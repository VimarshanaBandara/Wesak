import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_provider.dart';

/// OpenStreetMap implementation - free, no API key required
/// Sri Lanka urban areas ට sufficient quality
class OSMMapProvider implements MapProvider {
  // Event type eka අනුව marker pin color
  static const Map<String, Color> _markerColors = {
    'dansal': Colors.orange,
    'thorana': Colors.purple,
    'kudu': Color(0xFFFFD600), // Yellow
    'geetha': Colors.blue,
  };

  @override
  Widget buildMap({
    required LatLng initialCenter,
    required List<EventMarker> markers,
    required Function(EventMarker) onMarkerTap,
    double initialZoom = 10.0,
  }) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
      ),
      children: [
        // OSM tile layer - free community map tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.wesak',
        ),
        // Event location pins layer
        MarkerLayer(
          markers: markers
              .map((event) => _buildMarker(event, onMarkerTap))
              .toList(),
        ),
      ],
    );
  }

  /// Event type color eka use කරලා pin widget build කරනවා
  Marker _buildMarker(EventMarker event, Function(EventMarker) onTap) {
    final color = _markerColors[event.type] ?? Colors.grey;

    return Marker(
      point: event.position,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => onTap(event),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
