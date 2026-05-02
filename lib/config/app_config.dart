import '../services/map/map_provider.dart';
import '../services/map/osm_map_provider.dart';
import '../services/map/google_map_provider.dart';

/// App-wide configuration
class AppConfig {
  // true = Google Maps | false = OpenStreetMap (free fallback)
  static const bool useGoogleMaps = true;

  // Singleton — same provider instance reuse කරනවා (internal controllers persist)
  static MapProvider? _provider;
  static MapProvider get mapProvider {
    _provider ??= useGoogleMaps ? GoogleMapProvider() : OSMMapProvider();
    return _provider!;
  }
}
