import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:latlong2/latlong.dart';

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

  late final Stream<List<EventModel>> _eventsStream;

  String? _filterType;
  bool _searching = false;
  String? _searchError;

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
    _eventsStream = _firestoreService.getVerifiedEventsStream();
    _searchController.addListener(() => setState(() {}));
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
      appBar: WesakAppBar(title: AppLocale.mapTitle.getString(context)),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

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
                          horizontal: 16, vertical: 10),
                      child: Text(
                        AppLocale.mapNoEvents.getString(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final filtered = _filterType == null
              ? events
              : events.where((e) => e.type == _filterType).toList();

          final markers = filtered
              .map((e) => EventMarker(
                    id: e.id,
                    title: e.name,
                    type: e.type,
                    position: LatLng(e.lat, e.lng),
                  ))
              .toList();

          return Stack(
            children: [
              AppConfig.mapProvider.buildMap(
                initialCenter: const LatLng(7.8731, 80.7718),
                initialZoom: 8,
                markers: markers,
                onMarkerTap: (marker) {
                  _showEventDetail(context, marker, filtered);
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
                          hintText: AppLocale.mapSearchPlaceholder
                              .getString(context),
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search,
                              size: 20, color: Color(0xFF1A0533)),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(
                                            () => _searchError = null);
                                      },
                                      child: Icon(Icons.close,
                                          size: 18,
                                          color: Colors.grey[400]),
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),

                    // Search error
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Text(
                                _searchError == 'not_found'
                                    ? AppLocale.mapLocationNotFound
                                        .getString(context)
                                    : AppLocale.mapSearchFailed
                                        .getString(context),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red),
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
                            label: AppLocale.mapFilterAll
                                .getString(context),
                            icon: Icons.apps,
                            color: const Color(0xFF1A0533),
                            selected: _filterType == null,
                            onTap: () =>
                                setState(() => _filterType = null),
                          ),
                          const SizedBox(width: 6),
                          ...['dansal', 'thorana', 'kudu', 'geetha']
                              .map((type) => Padding(
                                    padding:
                                        const EdgeInsets.only(right: 6),
                                    child: _buildFilterChip(
                                      label: AppLocale.typeLabel(
                                          context, type),
                                      icon: _typeIcons[type]!,
                                      color: _typeColors[type]!,
                                      selected: _filterType == type,
                                      onTap: () => setState(
                                          () => _filterType = type),
                                    ),
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Legend - bottom left
              Positioned(
                bottom: 16,
                left: 16,
                child: _MapLegend(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEventDetail(
    BuildContext context,
    EventMarker marker,
    List<EventModel> events,
  ) {
    final event = events.firstWhere((e) => e.id == marker.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
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
          label: AppLocale.typeDansal.getString(context)),
      _LegendItem(
          color: const Color(0xFF6A1B9A),
          icon: Icons.account_balance,
          label: AppLocale.typeThorana.getString(context)),
      _LegendItem(
          color: const Color(0xFFF9A825),
          icon: Icons.wb_sunny,
          label: AppLocale.typeKudu.getString(context)),
      _LegendItem(
          color: const Color(0xFF1565C0),
          icon: Icons.music_note,
          label: AppLocale.legendGeetha.getString(context)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((item) => Padding(
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
                        child: Icon(item.icon,
                            color: Colors.white, size: 13),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        item.label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem(
      {required this.color, required this.icon, required this.label});
}
