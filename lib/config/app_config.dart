import '../services/map/map_provider.dart';
import '../services/map/osm_map_provider.dart';
import '../services/map/google_map_provider.dart';

/// App-wide configuration
/// Map provider switch, feature flags, etc.
class AppConfig {
  // Map provider toggle
  // false = OpenStreetMap (free, default)
  // true  = Google Maps (better quality, requires API key setup)
  // Switch කරන්නේ: google_map_provider.dart ේ steps follow කරලා මේ true කරන්න
  static const bool useGoogleMaps = false;

  /// Active map provider - useGoogleMaps flag eka අනුව return කරනවා
  static MapProvider get mapProvider {
    return useGoogleMaps ? GoogleMapProvider() : OSMMapProvider();
  }
}
