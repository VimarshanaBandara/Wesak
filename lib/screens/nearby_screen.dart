import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_locale.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/event_card.dart';
import '../widgets/wesak_app_bar.dart';

/// Nearby Events screen — GPS use කරලා km filter
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

  double _radiusKm = 50;
  static const _radiusOptions = [5.0, 10.0, 25.0, 50.0, 100.0];
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
          _gpsError = 'denied';
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
          _gpsError = 'error';
          _loadingGps = false;
        });
      }
    }
  }

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
        title: AppLocale.nearbyTitle.getString(context),
        showBackButton: true,
        actions: [
          if (_gpsError != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchLocation,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_userPosition != null) _buildRadiusBar(),
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
          Text(
            AppLocale.nearbyWithin.getString(context),
            style: const TextStyle(
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
                          color: selected
                              ? Colors.white
                              : Colors.grey[600],
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
            Text(
              AppLocale.nearbyGettingLocation.getString(context),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A0533),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.nearbyAllowLocation.getString(context),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
      final errorMsg = _gpsError == 'denied'
          ? AppLocale.nearbyPermissionDenied.getString(context)
          : AppLocale.nearbyLocationError.getString(context);

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
                errorMsg,
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
                  child: Text(
                    AppLocale.nearbyTryAgain.getString(context),
                    style: const TextStyle(
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
                  context.formatString(
                      AppLocale.nearbyNoEvents, [_radiusKm.round()]),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A0533),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocale.nearbyTryLarger.getString(context),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
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
                    withDist.length == 1
                        ? context.formatString(
                            AppLocale.nearbyEventsCount,
                            [withDist.length, _radiusKm.round()])
                        : context.formatString(
                            AppLocale.nearbyEventsCountPlural,
                            [withDist.length, _radiusKm.round()]),
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
    'dansal': Icons.soup_kitchen_rounded,
    'thorana': Icons.account_balance_rounded,
    'kudu': Icons.wb_incandescent_rounded,
    'geetha': Icons.library_music_rounded,
  };

  static const Map<String, List<Color>> _typeGradients = {
    'dansal': [Color(0xFFE64A19), Color(0xFF8D1900)],
    'thorana': [Color(0xFF8E24AA), Color(0xFF1A0533)],
    'kudu': [Color(0xFFFF7043), Color(0xFFBF360C)],
    'geetha': [Color(0xFF1565C0), Color(0xFF002171)],
  };

  static const Map<String, Color> _typeColors = {
    'dansal': Color(0xFFBF360C),
    'thorana': Color(0xFF6A1B9A),
    'kudu': Color(0xFFE65100),
    'geetha': Color(0xFF0D47A1),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[event.type] ?? const Color(0xFF1A0533);
    final gradients = _typeGradients[event.type] ??
        [const Color(0xFF1A0533), const Color(0xFF4A148C)];
    final icon = _typeIcons[event.type] ?? Icons.event_rounded;
    final hasPhoto = event.photos.isNotEmpty;
    final typeLabel = AppLocale.typeLabel(context, event.type);

    return GestureDetector(
      onTap: () => EventCard.showDetail(context, event),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left — photo or icon placeholder
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18)),
                child: hasPhoto
                    ? Image.network(
                        event.photos.first,
                        width: 72,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : _placeholder(gradients, icon),
                        errorBuilder: (_, _, _) =>
                            _placeholder(gradients, icon),
                      )
                    : _placeholder(gradients, icon),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Event name
                      Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A0533),
                          height: 1.3,
                        ),
                      ),

                      if (event.city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                event.city,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 7),

                      // Distance badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradients),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              distance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(List<Color> gradients, IconData icon) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
    );
  }
}
