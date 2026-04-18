enum MapStyle {
  clean,
  premium3D,
}

class MapConfig {
  // Mapbox Public Token
  static const String mapboxToken = 'YOUR_MAPBOX_TOKEN';

  // Helper method to resolve Mapbox Style URI
  static String getStyleUri(MapStyle style) {
    switch (style) {
      case MapStyle.premium3D:
        return 'mapbox://styles/mapbox/standard-satellite'; // Premium realistic 3D map
      case MapStyle.clean:
      default:
        return 'mapbox://styles/mapbox/streets-v12'; // Default clean picker
    }
  }
}
