import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import 'map_provider.dart';

class GoogleMapProvider implements MapProvider {
  gm.GoogleMapController? _pickerController;

  static const Map<String, double> _markerHues = {
    'dansal': gm.BitmapDescriptor.hueOrange,
    'thorana': gm.BitmapDescriptor.hueViolet,
    'kudu': gm.BitmapDescriptor.hueYellow,
    'geetha': gm.BitmapDescriptor.hueAzure,
  };

  @override
  Widget buildMap({
    required LatLng initialCenter,
    required List<EventMarker> markers,
    required Function(EventMarker) onMarkerTap,
    double initialZoom = 10.0,
    void Function(MapCameraController)? onMapReady,
  }) {
    return _ClusteredGoogleMap(
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      markers: markers,
      markerHues: _markerHues,
      onMarkerTap: onMarkerTap,
      onMapReady: onMapReady,
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
    final existing = _pickerController;
    if (existing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMapReady(_GoogleCameraController(existing));
      });
    }

    final markers = selectedLocation != null
        ? {
            gm.Marker(
              markerId: const gm.MarkerId('selected'),
              position: gm.LatLng(
                  selectedLocation.latitude, selectedLocation.longitude),
              icon: gm.BitmapDescriptor.defaultMarkerWithHue(
                  gm.BitmapDescriptor.hueRed),
            ),
          }
        : <gm.Marker>{};

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(initialCenter.latitude, initialCenter.longitude),
        zoom: initialZoom,
      ),
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      rotateGesturesEnabled: false,
      onTap: (gm.LatLng latLng) {
        onLocationSelected(LatLng(latLng.latitude, latLng.longitude));
      },
      onMapCreated: (controller) {
        _pickerController = controller;
        onMapReady(_GoogleCameraController(controller));
      },
    );
  }
}

// ── Clustered map widget ─────────────────────────────────────────────────────

class _ClusteredGoogleMap extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<EventMarker> markers;
  final Map<String, double> markerHues;
  final Function(EventMarker) onMarkerTap;
  final void Function(MapCameraController)? onMapReady;

  const _ClusteredGoogleMap({
    required this.initialCenter,
    required this.initialZoom,
    required this.markers,
    required this.markerHues,
    required this.onMarkerTap,
    this.onMapReady,
  });

  @override
  State<_ClusteredGoogleMap> createState() => _ClusteredGoogleMapState();
}

class _ClusteredGoogleMapState extends State<_ClusteredGoogleMap> {
  gm.GoogleMapController? _controller;
  Set<gm.Marker> _markers = {};
  double _zoom = 8.0;

  // Cache cluster icons by count to avoid re-rendering
  final Map<int, gm.BitmapDescriptor> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _rebuildMarkers();
  }

  @override
  void didUpdateWidget(_ClusteredGoogleMap old) {
    super.didUpdateWidget(old);
    if (old.markers != widget.markers) _rebuildMarkers();
  }

  Future<void> _rebuildMarkers() async {
    final computed = await _computeMarkers(widget.markers, _zoom);
    if (mounted) setState(() => _markers = computed);
  }

  Future<Set<gm.Marker>> _computeMarkers(
      List<EventMarker> events, double zoom) async {
    // At high zoom or few events — show individual markers directly
    if (zoom >= 13 || events.length <= 20) {
      return events.map(_singleMarker).toSet();
    }

    // Grid precision based on zoom level
    final precision = zoom < 7 ? 0 : zoom < 10 ? 1 : 2;

    // Group events into grid cells
    final grid = <String, List<EventMarker>>{};
    for (final e in events) {
      final key =
          '${e.position.latitude.toStringAsFixed(precision)}_${e.position.longitude.toStringAsFixed(precision)}';
      grid.putIfAbsent(key, () => []).add(e);
    }

    final result = <gm.Marker>{};
    for (final entry in grid.entries) {
      final group = entry.value;
      if (group.length == 1) {
        result.add(_singleMarker(group.first));
      } else {
        final center = _centroid(group);
        final icon = await _getClusterIcon(group.length);
        result.add(gm.Marker(
          markerId: gm.MarkerId('cluster_${entry.key}'),
          position: center,
          icon: icon,
          onTap: () => _controller?.animateCamera(
            gm.CameraUpdate.newLatLngZoom(center, _zoom + 3),
          ),
        ));
      }
    }
    return result;
  }

  gm.Marker _singleMarker(EventMarker e) {
    final hue = widget.markerHues[e.type] ?? gm.BitmapDescriptor.hueRed;
    return gm.Marker(
      markerId: gm.MarkerId(e.id),
      position: gm.LatLng(e.position.latitude, e.position.longitude),
      icon: gm.BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: gm.InfoWindow(title: e.title),
      onTap: () => widget.onMarkerTap(e),
    );
  }

  gm.LatLng _centroid(List<EventMarker> group) {
    final lat =
        group.map((e) => e.position.latitude).reduce((a, b) => a + b) /
            group.length;
    final lng =
        group.map((e) => e.position.longitude).reduce((a, b) => a + b) /
            group.length;
    return gm.LatLng(lat, lng);
  }

  Future<gm.BitmapDescriptor> _getClusterIcon(int count) async {
    final key = count > 99 ? 99 : count;
    if (_iconCache.containsKey(key)) return _iconCache[key]!;

    const size = 56;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFF1A0533).withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      Paint()..color = const Color(0xFF1A0533),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: count > 99 ? '99+' : '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas,
        Offset(size / 2 - tp.width / 2, size / 2 - tp.height / 2));

    final img = await recorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = gm.BitmapDescriptor.bytes(data!.buffer.asUint8List());
    _iconCache[key] = descriptor;
    return descriptor;
  }

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(
            widget.initialCenter.latitude, widget.initialCenter.longitude),
        zoom: widget.initialZoom,
      ),
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      rotateGesturesEnabled: false,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapReady?.call(_GoogleCameraController(controller));
        _rebuildMarkers();
      },
      onCameraMove: (position) => _zoom = position.zoom,
      onCameraIdle: _rebuildMarkers,
    );
  }
}

// ── Camera controller ────────────────────────────────────────────────────────

class _GoogleCameraController implements MapCameraController {
  final gm.GoogleMapController _controller;
  _GoogleCameraController(this._controller);

  @override
  void move(LatLng target, double zoom) {
    _controller.animateCamera(
      gm.CameraUpdate.newLatLngZoom(
        gm.LatLng(target.latitude, target.longitude),
        zoom,
      ),
    );
  }
}
