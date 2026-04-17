import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
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
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Category filter bottom sheet
            },
          ),
        ],
      ),
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

          return AppConfig.mapProvider.buildMap(
            initialCenter: const LatLng(7.8731, 80.7718),
            initialZoom: 8,
            markers: markers,
            onMarkerTap: (marker) {
              _showEventBottomSheet(context, marker, events);
            },
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
