enum MapStyle {
  clean,
  premium3D,
}

class MapConfig {
  // Mapbox Public Token
  static const String mapboxToken = 'YOUR_MAPBOX_TOKEN_HERE';

  // Helper method to resolve Mapbox Style URI
  static String getStyleUri(MapStyle style) {
    switch (style) {
      case MapStyle.premium3D:
        return 'mapbox://styles/mapbox/satellite-v9'; // Pure high-res satellite (no labels, clean look)
      case MapStyle.clean:
      default:
        return 'mapbox://styles/mapbox/standard'; // New Mapbox Standard (Premium 3D vision, Google-like)
    }
  }
}
