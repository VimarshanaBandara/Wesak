import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import 'map_provider.dart';

/// Google Maps implementation
/// AndroidManifest.xml සහ AppDelegate.swift ේ "YOUR_GOOGLE_MAPS_API_KEY" replace කරන්න
class GoogleMapProvider implements MapProvider {
  // Controllers — map screen සහ location picker ට separate
  gm.GoogleMapController? _mapController;
  gm.GoogleMapController? _pickerController;

  // Event type අනුව Google Maps marker hues
  static const Map<String, double> _markerHues = {
    'dansal'  : gm.BitmapDescriptor.hueOrange,   // deep orange
    'thorana' : gm.BitmapDescriptor.hueViolet,   // deep purple
    'kudu'    : gm.BitmapDescriptor.hueYellow,   // amber
    'geetha'  : gm.BitmapDescriptor.hueAzure,    // deep blue
  };

  @override
  Widget buildMap({
    required LatLng initialCenter,
    required List<EventMarker> markers,
    required Function(EventMarker) onMarkerTap,
    double initialZoom = 10.0,
    void Function(MapCameraController)? onMapReady,
  }) {
    // Controller already exists (screen rebuild) — callback immediately
    final existing = _mapController;
    if (existing != null && onMapReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMapReady(_GoogleCameraController(existing));
      });
    }

    final gmMarkers = markers.map((event) {
      final hue = _markerHues[event.type] ?? gm.BitmapDescriptor.hueRed;
      return gm.Marker(
        markerId: gm.MarkerId(event.id),
        position: gm.LatLng(event.position.latitude, event.position.longitude),
        icon: gm.BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: gm.InfoWindow(title: event.title),
        onTap: () => onMarkerTap(event),
      );
    }).toSet();

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(initialCenter.latitude, initialCenter.longitude),
        zoom: initialZoom,
      ),
      markers: gmMarkers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      rotateGesturesEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        onMapReady?.call(_GoogleCameraController(controller));
      },
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
    // Controller already exists — callback immediately
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
