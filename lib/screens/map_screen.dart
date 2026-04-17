import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../widgets/wesak_app_bar.dart';
import '../models/event_model.dart';
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

  // Stream initState ේ store කරනවා - build() ෙකදී new stream create වෙන්නේ නෑ
  // build() ේදී stream call කළොත් rebuild ෙකදී stream restart වෙලා data miss වෙනවා
  late final Stream<List<EventModel>> _eventsStream;

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

          // Events → EventMarker list
          final markers = events
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
                  _showEventBottomSheet(context, marker, events);
                },
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

  /// Map pin tap → event quick info bottom sheet
  void _showEventBottomSheet(
    BuildContext context,
    EventMarker marker,
    List<EventModel> events,
  ) {
    final event = events.firstWhere((e) => e.id == marker.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(event.name,
                style: Theme.of(context).textTheme.titleLarge),
            if (event.city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    event.city,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.description),
            ],

            // Event photos - Firebase Storage URLs
            if (event.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      event.photos[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Get Directions button - phone ේ Google Maps app open කරනවා
            FilledButton.icon(
              onPressed: () => _openGoogleMaps(event.lat, event.lng, event.name),
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Phone ේ Google Maps app ෙකන් event location ට directions open කරනවා
  /// geo: URL scheme use කරනවා - free, no API key
  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    // Google Maps app deep link - label ෙකන් pin name show කරනවා
    final uri = Uri.parse(
      'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback - browser ෙකන් Google Maps open කරනවා
      final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
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
