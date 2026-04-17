import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Abstract map provider interface
/// OSM හෝ Google Maps - implementation swap කරන්න මේ interface change කරන්නේ නෑ
abstract class MapProvider {
  Widget buildMap({
    required LatLng initialCenter,
    required List<EventMarker> markers,
    required Function(EventMarker) onMarkerTap,
    double initialZoom = 10.0,
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
