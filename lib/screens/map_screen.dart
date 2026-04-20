import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  final _mapController = MapController();
  final _searchController = TextEditingController();

  late final Stream<List<EventModel>> _eventsStream;

  // null = all types shown
  String? _filterType;

  // Location search
  bool _searching = false;
  String? _searchError;

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
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Nominatim (OpenStreetMap) free geocoding — API key නෑ
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
          _searchError = 'Location not found';
          _searching = false;
        });
        return;
      }

      final lat = double.parse(results[0]['lat'] as String);
      final lng = double.parse(results[0]['lon'] as String);
      _mapController.move(LatLng(lat, lng), 13.0);
      setState(() => _searching = false);
    } catch (_) {
      setState(() {
        _searchError = 'Search failed. Check connection.';
        _searching = false;
      });
    }
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
                  mapController: _mapController,
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
                mapController: _mapController,
              ),

              // Top overlay: search bar + filter chips
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
                          hintText: 'Search location...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF1A0533)),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchError = null);
                                      },
                                      child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),

                    // Search error
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Text(_searchError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
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
                                  onTap: () => setState(() => _filterType = e.key),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
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
