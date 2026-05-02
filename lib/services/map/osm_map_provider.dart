import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_provider.dart';

/// OpenStreetMap implementation - free, no API key required
/// Google Maps switch කළාම OSMMapProvider unused වෙනවා, flutter_map package keep කරන්නේ නෑ
class OSMMapProvider implements MapProvider {
  // buildMap සහ buildLocationPicker ට separate controllers — same screen ෙකදී conflict නෑ
  final MapController _mapController = MapController();
  final MapController _pickerController = MapController();

  static const Map<String, Color> _markerColors = {
    'dansal'  : Color(0xFFE65100),
    'thorana' : Color(0xFF6A1B9A),
    'kudu'    : Color(0xFFF9A825),
    'geetha'  : Color(0xFF1565C0),
  };

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
    void Function(MapCameraController)? onMapReady,
  }) {
    if (onMapReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMapReady(_OSMCameraController(_mapController));
      });
    }
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.vmmobile.wesak',
        ),
        MarkerLayer(
          markers: markers
              .map((event) => _buildMarker(event, onMarkerTap))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget buildLocationPicker({
    required LatLng initialCenter,
    required double initialZoom,
    required LatLng? selectedLocation,
    required Function(LatLng) onLocationSelected,
    required void Function(MapCameraController) onMapReady,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onMapReady(_OSMCameraController(_pickerController));
    });
    return FlutterMap(
      mapController: _pickerController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onTap: (_, latLng) => onLocationSelected(latLng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.vmmobile.wesak',
        ),
        if (selectedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                width: 48,
                height: 48,
                child: const Icon(Icons.location_on, color: Colors.red, size: 48),
              ),
            ],
          ),
      ],
    );
  }

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

class _OSMCameraController implements MapCameraController {
  final MapController _controller;
  _OSMCameraController(this._controller);

  @override
  void move(LatLng target, double zoom) => _controller.move(target, zoom);
}
