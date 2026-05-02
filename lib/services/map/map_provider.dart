import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Provider-agnostic camera control — OSM සහ Google Maps දෙකටම work කරනවා
abstract class MapCameraController {
  void move(LatLng target, double zoom);
}

/// Abstract map provider interface
/// OSM හෝ Google Maps - implementation swap කරන්න මේ interface change කරන්නේ නෑ
abstract class MapProvider {
  /// Main map screen ට - events markers + search camera control
  Widget buildMap({
    required LatLng initialCenter,
    required List<EventMarker> markers,
    required Function(EventMarker) onMarkerTap,
    double initialZoom = 10.0,
    void Function(MapCameraController)? onMapReady,
  });

  /// Location picker screen ට - tap-to-select + GPS center
  Widget buildLocationPicker({
    required LatLng initialCenter,
    required double initialZoom,
    required LatLng? selectedLocation,
    required Function(LatLng) onLocationSelected,
    required void Function(MapCameraController) onMapReady,
  });
}

/// Map pin data - event location + display info
class EventMarker {
  final String id;
  final String title;
  final String type; // dansal | thorana | kudu | geetha
  final LatLng position;

  const EventMarker({
    required this.id,
    required this.title,
    required this.type,
    required this.position,
  });
}
