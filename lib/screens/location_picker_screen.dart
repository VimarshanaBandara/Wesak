import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Map screen ෙකන් location tap කරලා LatLng return කරනවා
/// Usage: final result = await Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const LocationPickerScreen()));
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();

  // User tap කළ location - null නම් තෝරලා නෑ
  LatLng? _selectedLocation;

  // Default center - Sri Lanka
  LatLng _center = const LatLng(7.8731, 80.7718);
  double _zoom = 8.0;

  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    // Screen open වෙනකොට GPS location ට move කරනවා
    _goToCurrentLocation();
  }

  /// GPS permission check කරලා current location ට map move කරනවා
  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingGps = true);

    try {
      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Permission නෑ - Sri Lanka default center ෙකන් continue
        setState(() => _loadingGps = false);
        return;
      }

      // Current GPS position get කරනවා
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _center = currentLatLng;
          _zoom = 15.0;
          _loadingGps = false;
        });
        // Map ෙකත් move කරනවා
        _mapController.move(currentLatLng, 15.0);
      }
    } catch (_) {
      // GPS fail වුණොත් default center use කරනවා
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        centerTitle: true,
        actions: [
          // Selected location නෑ නම් button disable
          TextButton(
            onPressed: _selectedLocation != null
                ? () => Navigator.pop(context, _selectedLocation)
                : null,
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OSM map - tap කළ position ෙකන් pin set කරනවා
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              // Map tap -> selected location update
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
              // Selected pin
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

          // Top instruction banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _selectedLocation == null
                      ? 'Tap on the map to select location'
                      : 'Location selected — tap Confirm to save',
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

          // GPS loading indicator
          if (_loadingGps)
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Getting your location...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // "My Location" FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _goToCurrentLocation,
              tooltip: 'My Location',
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
