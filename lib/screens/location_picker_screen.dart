import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_locale.dart';
import '../widgets/wesak_app_bar.dart';

/// Map ෙකන් location tap කරලා LatLng return කරනවා
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  LatLng _center = const LatLng(7.8731, 80.7718);
  double _zoom = 8.0;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingGps = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _loadingGps = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final currentLatLng =
          LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _center = currentLatLng;
          _zoom = 15.0;
          _loadingGps = false;
        });
        _mapController.move(currentLatLng, 15.0);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WesakAppBar(
        title: AppLocale.locationTitle.getString(context),
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null
                ? () => Navigator.pop(context, _selectedLocation)
                : null,
            child: Text(
              AppLocale.locationConfirm.getString(context),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              onTap: (_, latLng) {
                setState(() => _selectedLocation = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vmmobile.wesak',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Instruction banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Text(
                  _selectedLocation == null
                      ? AppLocale.locationTapHint.getString(context)
                      : AppLocale.locationSelectedHint
                          .getString(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedLocation == null
                        ? Colors.grey[700]
                        : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // GPS loading
          if (_loadingGps)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(AppLocale.locationGetting
                            .getString(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // My Location FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _goToCurrentLocation,
              tooltip: AppLocale.locationMyLocation.getString(context),
              child: _loadingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
