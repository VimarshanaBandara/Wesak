import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/event_card.dart';
import '../widgets/wesak_app_bar.dart';

/// Nearby Events screen — GPS use කරලා km ෙකන් sort කරලා show කරනවා
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final _firestoreService = FirestoreService();
  late final Stream<List<EventModel>> _stream;

  Position? _userPosition;
  bool _loadingGps = true;
  String? _gpsError;

  // km filter - default 50km
  double _radiusKm = 50;
  static const _radiusOptions = [5.0, 10.0, 25.0, 50.0, 100.0];

  // Distance calculator - latlong2
  static const _distCalc = Distance();

  @override
  void initState() {
    super.initState();
    _stream = _firestoreService.getVerifiedEventsStream();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
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
          _gpsError = 'Location permission denied.\nPlease enable in Settings.';
          _loadingGps = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userPosition = pos;
          _loadingGps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gpsError = 'Could not get location. Please try again.';
          _loadingGps = false;
        });
      }
    }
  }

  /// Haversine distance km — user position → event
  double _distanceTo(EventModel event) {
    if (_userPosition == null) return double.infinity;
    return _distCalc.as(
      LengthUnit.Kilometer,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(event.lat, event.lng),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: WesakAppBar(
        title: 'Nearby Events',
        showBackButton: true,
        actions: [
          // Retry GPS button
          if (_gpsError != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchLocation,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Radius filter bar ──────────────────────────────────────
          if (_userPosition != null) _buildRadiusBar(),

          // ── Content ───────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildRadiusBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.radar, size: 18, color: Color(0xFF6A0080)),
          const SizedBox(width: 8),
          const Text(
            'Within',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A0533),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _radiusOptions.map((km) {
                  final selected = _radiusKm == km;
                  return GestureDetector(
                    onTap: () => setState(() => _radiusKm = km),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF6A0080)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF6A0080)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        km < 100 ? '${km.round()} km' : '100 km',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // GPS loading
    if (_loadingGps) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6A0080).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_searching,
                  size: 36, color: Color(0xFF6A0080)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Getting your location...',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF1A0533),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please allow location access',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFF6A0080),
              strokeWidth: 2.5,
            ),
          ],
        ),
      );
    }

    // GPS error
    if (_gpsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off,
                    size: 36, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                _gpsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A0533),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _fetchLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0533),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Events list
    return StreamBuilder<List<EventModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data ?? [];

        // Distance compute + filter by radius + sort
        final withDist = all
            .map((e) => (event: e, dist: _distanceTo(e)))
            .where((e) => e.dist <= _radiusKm)
            .toList()
          ..sort((a, b) => a.dist.compareTo(b.dist));

        if (withDist.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No events within ${_radiusKm.round()} km',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A0533),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try a larger radius',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User location info bar
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.my_location,
                        size: 17, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${withDist.length} event${withDist.length == 1 ? '' : 's'} within ${_radiusKm.round()} km',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A0533),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: withDist.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = withDist[i];
                  return _NearbyEventCard(
                    event: item.event,
                    distance: _formatDistance(item.dist),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Event card with distance badge
class _NearbyEventCard extends StatelessWidget {
  final EventModel event;
  final String distance;

  const _NearbyEventCard({required this.event, required this.distance});

  static const Map<String, IconData> _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };
  static const Map<String, Color> _typeColors = {
    'dansal': Color(0xFFBF360C),
    'thorana': Color(0xFF4A148C),
    'kudu': Color(0xFFF57F17),
    'geetha': Color(0xFF0D47A1),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[event.type] ?? Colors.grey;
    final icon = _typeIcons[event.type] ?? Icons.event;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => EventCard.showDetail(context, event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (event.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            event.city,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        event.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Distance badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0533),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me,
                            size: 11, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.photos.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event.photos.first,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) =>
                            p == null ? child : Container(
                              width: 52,
                              height: 52,
                              color: Colors.grey[200],
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
