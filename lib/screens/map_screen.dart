import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import '../widgets/wesak_app_bar.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';
import '../services/firestore_service.dart';
import '../services/map/map_provider.dart';

/// Map screen - Firestore verified events pins ලෙස show කරනවා
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _firestoreService = FirestoreService();

  late final Stream<List<EventModel>> _eventsStream;

  // null = all types shown
  String? _filterType;

  static const _typeLabels = {
    'dansal': 'Dansal',
    'thorana': 'Thorana',
    'kudu': 'Wesak Kudu',
    'geetha': 'Bhakthi Geetha',
  };
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WesakAppBar(title: 'Map'),
      // Firestore verified events stream ට listen කරනවා
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          // Approved events නෑ නම් empty map + message
          if (events.isEmpty) {
            return Stack(
              children: [
                // Map show කරනවා - empty ෙකදීත්
                AppConfig.mapProvider.buildMap(
                  initialCenter: const LatLng(7.8731, 80.7718),
                  initialZoom: 8,
                  markers: const [],
                  onMarkerTap: (_) {},
                ),
                const Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'No approved events yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Filter events by selected type
          final filtered = _filterType == null
              ? events
              : events.where((e) => e.type == _filterType).toList();

          // Events → EventMarker list
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
                  _showEventBottomSheet(context, marker, filtered);
                },
              ),

              // Filter chips - top
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All chip
                      _buildFilterChip(
                        label: 'All',
                        icon: Icons.apps,
                        color: const Color(0xFF1A0533),
                        selected: _filterType == null,
                        onTap: () => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 6),
                      ..._typeLabels.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildFilterChip(
                              label: e.value,
                              icon: _typeIcons[e.key]!,
                              color: _typeColors[e.key]!,
                              selected: _filterType == e.key,
                              onTap: () =>
                                  setState(() => _filterType = e.key),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // Legend - bottom left corner
              const Positioned(
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

  /// Map pin tap → EventDetailScreen navigate කරනවා
  void _showEventBottomSheet(
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

  /// Phone ේ Google Maps app ෙකන් event location ට directions open කරනවා
  /// geo: URL scheme use කරනවා - free, no API key
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

/// Map legend - pin colors + categories explain කරනවා
class _MapLegend extends StatelessWidget {
  const _MapLegend();

  static const _items = [
    _LegendItem(color: Color(0xFFE65100), icon: Icons.restaurant,     label: 'Dansal'),
    _LegendItem(color: Color(0xFF6A1B9A), icon: Icons.account_balance, label: 'Thorana'),
    _LegendItem(color: Color(0xFFF9A825), icon: Icons.wb_sunny,        label: 'Wesak Kudu'),
    _LegendItem(color: Color(0xFF1565C0), icon: Icons.music_note,      label: 'Geetha'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _items
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
                        child: Icon(item.icon, color: Colors.white, size: 13),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
  const _LegendItem({required this.color, required this.icon, required this.label});
}
