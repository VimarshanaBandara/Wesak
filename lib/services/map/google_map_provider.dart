import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'map_provider.dart';

// Google Maps provider - stub, activate කරන්නේ ඕනෑ නම්:
//   1. pubspec.yaml ේ google_maps_flutter uncomment කරන්න
//   2. android/app/src/main/AndroidManifest.xml ේ API key add කරන්න
//   3. app_config.dart ේ useGoogleMaps = true කරන්න
//   4. buildMap() method ේ GoogleMap widget implement කරන්න

// ignore: depend_on_referenced_packages
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapProvider implements MapProvider {
  @override
  Widget buildMap({
    required LatLng initialCenter,
    required List<EventMarker> markers,
    required Function(EventMarker) onMarkerTap,
    double initialZoom = 10.0,
  }) {
    // TODO: google_maps_flutter package activate කළාම implement කරන්න
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Google Maps not configured'),
          Text(
            'See google_map_provider.dart for setup steps',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
