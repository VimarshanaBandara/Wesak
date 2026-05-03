import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../l10n/app_locale.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../services/map/map_provider.dart';
import '../widgets/wesak_app_bar.dart';
import 'event_detail_screen.dart';

/// Map screen - Firestore verified events pins
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  // Provider ගෙන් onMapReady callback ෙකදී set වෙනවා
  MapCameraController? _cameraController;

  List<EventModel> _events = [];
  bool _eventsLoading = true;
  String? _eventsError;

  String? _filterType;
  bool _searching = false;
  String? _searchError;
  bool _locating = false;
  bool _findingDansal = false;
  Position? _lastPosition;

  static const _typeColors = {
    'dansal': Color(0xFFE65100),
    'thorana': Color(0xFF6A1B9A),
    'kudu': Color(0xFFF9A825),
    'geetha': Color(0xFF1565C0),
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _loadEvents() async {
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });
    try {
      final events = await _firestoreService.getVerifiedEvents();
      if (mounted) setState(() { _events = events; _eventsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _eventsError = '$e'; _eventsLoading = false; });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final encoded = Uri.encodeComponent(query.trim());
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1&countrycodes=lk',
        ),
      );
      req.headers.set('User-Agent', 'WsakApp/1.0');
      final res = await req.close();
      final body = await res.transform(const Utf8Decoder()).join();
      client.close();

      final results = json.decode(body) as List<dynamic>;
      if (results.isEmpty) {
        setState(() {
          _searchError = 'not_found';
          _searching = false;
        });
        return;
      }

      final lat = double.parse(results[0]['lat'] as String);
      final lng = double.parse(results[0]['lon'] as String);
      _cameraController?.move(LatLng(lat, lng), 13.0);
      setState(() => _searching = false);
    } catch (_) {
      setState(() {
        _searchError = 'failed';
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WesakAppBar(
        title: AppLocale.mapTitle.getString(context),
        actions: [
          IconButton(
            icon: _eventsLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _eventsLoading ? null : _loadEvents,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_eventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_eventsError != null) {
            return Center(child: Text('Error: $_eventsError'));
          }

          final events = _events;

          if (events.isEmpty) {
            return Stack(
              children: [
                AppConfig.mapProvider.buildMap(
                  initialCenter: const LatLng(7.8731, 80.7718),
                  initialZoom: 8,
                  markers: const [],
                  onMarkerTap: (_) {},
                  onMapReady: (c) => _cameraController = c,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        AppLocale.mapNoEvents.getString(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildMyLocationButton(),
                ),
              ],
            );
          }

          final filtered = _filterType == null
              ? events
              : events.where((e) => e.type == _filterType).toList();

          final markers = filtered
              .map(
                (e) => EventMarker(
                  id: e.id,
                  title: e.name,
                  type: e.type,
                  position: LatLng(e.lat, e.lng),
                ),
              )
              .toList();

          return Stack(
            children: [
              AppConfig.mapProvider.buildMap(
                initialCenter: const LatLng(7.8731, 80.7718),
                initialZoom: 8,
                markers: markers,
                onMarkerTap: (marker) {
                  _showEventPreview(context, marker, filtered);
                },
                onMapReady: (c) => _cameraController = c,
              ),

              // Top overlay: search + filter chips
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _searchLocation,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: AppLocale.mapSearchPlaceholder.getString(
                            context,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: Color(0xFF1A0533),
                          ),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchError = null);
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),

                    // Search error
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _searchError == 'not_found'
                                    ? AppLocale.mapLocationNotFound.getString(
                                        context,
                                      )
                                    : AppLocale.mapSearchFailed.getString(
                                        context,
                                      ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: AppLocale.mapFilterAll.getString(context),
                            icon: Icons.apps,
                            color: const Color(0xFF1A0533),
                            selected: _filterType == null,
                            count: events.length,
                            onTap: () => setState(() => _filterType = null),
                          ),
                          const SizedBox(width: 6),
                          ...['dansal', 'thorana', 'kudu', 'geetha'].map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _buildFilterChip(
                                label: AppLocale.typeLabel(context, type),
                                icon: _typeIcons[type]!,
                                color: _typeColors[type]!,
                                selected: _filterType == type,
                                count: events
                                    .where((e) => e.type == type)
                                    .length,
                                onTap: () => setState(() => _filterType = type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom row: legend + nearest dansal + my location
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MapLegend(),
                    const Spacer(),
                    _buildNearestDansalButton(context, events),
                    const SizedBox(width: 10),
                    _buildMyLocationButton(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocale.listGpsDenied.getString(context)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _lastPosition = pos;
      _cameraController?.move(LatLng(pos.latitude, pos.longitude), 14.0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocale.listGpsError.getString(context)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: _goToMyLocation,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _locating
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A0533),
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF1A0533),
                size: 22,
              ),
      ),
    );
  }

  Widget _buildNearestDansalButton(
      BuildContext context, List<EventModel> events) {
    return GestureDetector(
      onTap: () => _findNearestDansal(events),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE64A19), Color(0xFF8D1900)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_findingDansal)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.soup_kitchen_rounded,
                  color: Colors.white, size: 16),
            const SizedBox(width: 7),
            Text(
              AppLocale.mapNearestDansal.getString(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _findNearestDansal(List<EventModel> events) async {
    if (_findingDansal) return;
    setState(() => _findingDansal = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocale.listGpsDenied.getString(context)),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _lastPosition = pos;

      final sorted = events
          .where((e) => e.type == 'dansal')
          .map((e) => (
                event: e,
                distMeters: Geolocator.distanceBetween(
                    pos.latitude, pos.longitude, e.lat, e.lng),
              ))
          .toList()
        ..sort((a, b) => a.distMeters.compareTo(b.distMeters));

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _NearestDansalSheet(
            dansals: sorted,
            onShowOnMap: (event) {
              _cameraController?.move(LatLng(event.lat, event.lng), 16.0);
            },
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocale.listGpsError.getString(context)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _findingDansal = false);
    }
  }

  void _showEventPreview(
    BuildContext context,
    EventMarker marker,
    List<EventModel> events,
  ) {
    final matches = events.where((e) => e.id == marker.id);
    if (matches.isEmpty) return;
    final event = matches.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _EventPreviewSheet(event: event, userPosition: _lastPosition),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color
              : const Color(0xFF1A0533).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Map legend widget
class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _LegendItem(
        color: const Color(0xFFE65100),
        icon: Icons.restaurant,
        label: AppLocale.typeDansal.getString(context),
      ),
      _LegendItem(
        color: const Color(0xFF6A1B9A),
        icon: Icons.account_balance,
        label: AppLocale.typeThorana.getString(context),
      ),
      _LegendItem(
        color: const Color(0xFFF9A825),
        icon: Icons.wb_sunny,
        label: AppLocale.typeKudu.getString(context),
      ),
      _LegendItem(
        color: const Color(0xFF1565C0),
        icon: Icons.music_note,
        label: AppLocale.legendGeetha.getString(context),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0533).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });
}

// ── Event preview bottom sheet ─────────────────────────────────────────────

class _EventPreviewSheet extends StatelessWidget {
  final EventModel event;
  final Position? userPosition;

  const _EventPreviewSheet({required this.event, this.userPosition});

  static const _typeColors = {
    'dansal': Color(0xFFE65100),
    'thorana': Color(0xFF6A1B9A),
    'kudu': Color(0xFFF9A825),
    'geetha': Color(0xFF1565C0),
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant_rounded,
    'thorana': Icons.account_balance_rounded,
    'kudu': Icons.light_mode_rounded,
    'geetha': Icons.music_note_rounded,
  };

  Color get _typeColor => _typeColors[event.type] ?? const Color(0xFF1A0533);

  static const _typeGradients = {
    'dansal': [Color(0xFFE64A19), Color(0xFF8D1900)],
    'thorana': [Color(0xFF8E24AA), Color(0xFF1A0533)],
    'kudu': [Color(0xFFFF7043), Color(0xFFBF360C)],
    'geetha': [Color(0xFF1565C0), Color(0xFF002171)],
  };

  List<Color> get _typeGradient =>
      _typeGradients[event.type] ??
      [const Color(0xFF1A0533), const Color(0xFF4A148C)];

  String? _distanceLabel(BuildContext context) {
    if (userPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      event.lat,
      event.lng,
    );
    if (meters < 1000) {
      return context.formatString(AppLocale.commonMaway, [
        meters.round().toString(),
      ]);
    }
    return context.formatString(AppLocale.commonKmaway, [
      (meters / 1000).toStringAsFixed(1),
    ]);
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'geo:${event.lat},${event.lng}?q=${event.lat},${event.lng}(${Uri.encodeComponent(event.name)})',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor;
    final typeIcon = _typeIcons[event.type] ?? Icons.event_rounded;
    final distance = _distanceLabel(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row: icon + name/type/city/distance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _typeGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(typeIcon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppLocale.typeLabel(context, event.type),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A0533),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event.city.isNotEmpty || distance != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  children: [
                                    if (event.city.isNotEmpty) ...[
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 11,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          event.city,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    if (distance != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.near_me_rounded,
                                        size: 11,
                                        color: typeColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        distance,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: typeColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (event.verified) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.green.shade600,
                          size: 18,
                        ),
                      ],
                    ],
                  ),

                  // Photos — horizontal scroll, tap to zoom
                  if (event.photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 78,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.photos.length,
                        itemBuilder: (ctx, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _FullScreenPhotoViewer(url: event.photos[i]),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < event.photos.length - 1 ? 8 : 0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                event.photos[i],
                                width: 78,
                                height: 78,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, p) => p == null
                                    ? child
                                    : Container(
                                        width: 78,
                                        height: 78,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                errorBuilder: (_, _, _) => Container(
                                  width: 78,
                                  height: 78,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action buttons
                  Row(
                    children: [
                      // Directions
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openDirections,
                          icon: const Icon(Icons.directions_rounded, size: 15),
                          label: Text(
                            AppLocale.detailGetDirections.getString(context),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: typeColor,
                            side: BorderSide(
                              color: typeColor.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // View Details
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: event),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 15),
                          label: Text(
                            AppLocale.mapViewDetails.getString(context),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen photo viewer (zoom/pan) ────────────────────────────────────

class _FullScreenPhotoViewer extends StatelessWidget {
  final String url;

  const _FullScreenPhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}

// ── Nearest Dansal bottom sheet ─────────────────────────────────────────────

class _NearestDansalSheet extends StatelessWidget {
  final List<({EventModel event, double distMeters})> dansals;
  final void Function(EventModel) onShowOnMap;

  const _NearestDansalSheet({
    required this.dansals,
    required this.onShowOnMap,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE64A19), Color(0xFF8D1900)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.soup_kitchen_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocale.mapNearestDansalTitle.getString(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0533),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (dansals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.soup_kitchen_outlined,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    AppLocale.mapNoDansals.getString(context),
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: dansals.length,
                separatorBuilder: (_, _) => const Divider(
                    height: 1, indent: 16, endIndent: 16),
                itemBuilder: (ctx, i) {
                  final item = dansals[i];
                  return _DansalNearbyRow(
                    event: item.event,
                    distance: _formatDistance(item.distMeters),
                    rank: i + 1,
                    onShowOnMap: () {
                      Navigator.pop(ctx);
                      onShowOnMap(item.event);
                    },
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _DansalNearbyRow extends StatelessWidget {
  final EventModel event;
  final String distance;
  final int rank;
  final VoidCallback onShowOnMap;

  const _DansalNearbyRow({
    required this.event,
    required this.distance,
    required this.rank,
    required this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFE64A19)
                  : const Color(0xFF1A0533).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rank == 1 ? Colors.white : const Color(0xFF1A0533),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A0533),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.city.isNotEmpty)
                  Text(
                    event.city,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE64A19).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE64A19),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onShowOnMap,
                child: Text(
                  AppLocale.mapShowOnMap.getString(context),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
