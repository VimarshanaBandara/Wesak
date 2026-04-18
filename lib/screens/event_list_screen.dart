import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/event_card.dart';
import '../widgets/wesak_app_bar.dart';

enum _SortMode { defaultSort, nearMe }

/// Category filtered event list screen
/// Home screen category card tap ෙකන් open වෙනවා
class EventListScreen extends StatefulWidget {
  final String eventType;
  final String displayName;

  const EventListScreen({
    super.key,
    required this.eventType,
    required this.displayName,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _firestoreService = FirestoreService();
  late final Stream<List<EventModel>> _stream;

  _SortMode _sortMode = _SortMode.defaultSort;
  Position? _userPosition;
  bool _loadingGps = false;
  String? _gpsError;

  static const _distCalc = Distance();

  static const _typeGradients = {
    'dansal': [Color(0xFFBF360C), Color(0xFFFF6D00)],
    'thorana': [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    'kudu': [Color(0xFFF57F17), Color(0xFFFFD600)],
    'geetha': [Color(0xFF0D47A1), Color(0xFF1976D2)],
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };

  static const _typeDescriptions = {
    'dansal': 'Free food offerings for all',
    'thorana': 'Illuminated Wesak structures',
    'kudu': 'Traditional Wesak lanterns',
    'geetha': 'Buddhist devotional music',
  };

  @override
  void initState() {
    super.initState();
    _stream = _firestoreService.getEventsByTypeStream(widget.eventType);
  }

  // ── GPS helpers ─────────────────────────────────────────────────────────────

  Future<void> _enableNearMe() async {
    setState(() {
      _loadingGps = true;
      _gpsError = null;
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _gpsError = 'Location permission denied';
          _loadingGps = false;
          _sortMode = _SortMode.defaultSort;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      setState(() {
        _userPosition = pos;
        _loadingGps = false;
        _sortMode = _SortMode.nearMe;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Could not get location';
        _loadingGps = false;
        _sortMode = _SortMode.defaultSort;
      });
    }
  }

  double? _distanceTo(EventModel e) {
    if (_userPosition == null) return null;
    return _distCalc.as(
      LengthUnit.Kilometer,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(e.lat, e.lng),
    );
  }

  List<EventModel> _sorted(List<EventModel> events) {
    if (_sortMode == _SortMode.nearMe && _userPosition != null) {
      final sorted = [...events];
      sorted.sort((a, b) => (_distanceTo(a) ?? 0).compareTo(_distanceTo(b) ?? 0));
      return sorted;
    }
    return events;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gradients =
        _typeGradients[widget.eventType] ?? [Colors.grey, Colors.blueGrey];
    final icon = _typeIcons[widget.eventType] ?? Icons.event;
    final description = _typeDescriptions[widget.eventType] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: WesakAppBar(title: widget.displayName, showBackButton: true),
      body: StreamBuilder<List<EventModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = _sorted(snapshot.data ?? []);

          if (events.isEmpty) {
            return _buildEmptyState(gradients, icon);
          }

          return CustomScrollView(
            slivers: [
              // Header banner
              SliverToBoxAdapter(
                child: _buildHeader(
                    gradients, icon, description, events.length),
              ),

              // Sort bar
              SliverToBoxAdapter(
                child: _buildSortBar(gradients),
              ),

              // GPS error banner
              if (_gpsError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _gpsError!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Event list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = events[index];
                      final dist = _sortMode == _SortMode.nearMe
                          ? _distanceTo(event)
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EventCard(event: event, distanceKm: dist),
                      );
                    },
                    childCount: events.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    List<Color> gradients,
    IconData icon,
    String description,
    int count,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradients.last.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(List<Color> gradients) {
    final activeColor = gradients.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          const Text(
            'Sort by',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),

          // Default chip
          _sortChip(
            label: 'Default',
            icon: Icons.sort,
            selected: _sortMode == _SortMode.defaultSort,
            activeColor: activeColor,
            onTap: () => setState(() {
              _sortMode = _SortMode.defaultSort;
              _gpsError = null;
            }),
          ),
          const SizedBox(width: 8),

          // Near me chip
          _sortChip(
            label: _loadingGps
                ? 'Locating…'
                : _sortMode == _SortMode.nearMe
                    ? 'Near Me'
                    : 'Near Me',
            icon: _loadingGps
                ? Icons.gps_not_fixed
                : Icons.near_me,
            selected: _sortMode == _SortMode.nearMe,
            activeColor: const Color(0xFF2E7D32),
            loading: _loadingGps,
            onTap: _loadingGps
                ? null
                : () {
                    if (_sortMode == _SortMode.nearMe) {
                      setState(() => _sortMode = _SortMode.defaultSort);
                    } else if (_userPosition != null) {
                      setState(() => _sortMode = _SortMode.nearMe);
                    } else {
                      _enableNearMe();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _sortChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color activeColor,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: selected ? Colors.white : activeColor,
                ),
              )
            else
              Icon(
                icon,
                size: 13,
                color: selected ? Colors.white : Colors.grey[600],
              ),
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

  Widget _buildEmptyState(List<Color> gradients, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradients.first.withValues(alpha: 0.15),
                  gradients.last.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 40,
                color: gradients.first.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${widget.displayName} yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A0533),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to add one!',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
