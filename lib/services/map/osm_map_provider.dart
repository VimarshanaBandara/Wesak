import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_provider.dart';

/// OpenStreetMap implementation - free, no API key required
/// Sri Lanka urban areas ට sufficient quality
class OSMMapProvider implements MapProvider {
  // Event type අනුව marker colors
  static const Map<String, Color> _markerColors = {
    'dansal'  : Color(0xFFE65100), // Deep orange - dansal fire/warmth
    'thorana' : Color(0xFF6A1B9A), // Deep purple - thorana lights
    'kudu'    : Color(0xFFF9A825), // Amber - lantern glow
    'geetha'  : Color(0xFF1565C0), // Deep blue - devotional
  };

  // Event type අනුව marker icons
  static const Map<String, IconData> _markerIcons = {
    'dansal'  : Icons.restaurant,
    'thorana' : Icons.account_balance,
    'kudu'    : Icons.wb_sunny,
    'geetha'  : Icons.music_note,
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
          userAgentPackageName: 'com.vmmobile.wesak',
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
    final icon = _markerIcons[event.type] ?? Icons.location_on;

    return Marker(
      point: event.position,
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: () => onTap(event),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }
}
