import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import '../../config/map_config.dart';

Widget buildNearbyMapView({
  required Map<String, dynamic> mainProperty,
  required List<Map<String, dynamic>> nearbyProperties,
  required Function(int id, bool isMain) onMarkerClick,
}) {
  return _NearbyMapWeb(
    mainProperty: mainProperty,
    nearbyProperties: nearbyProperties,
    onMarkerClick: onMarkerClick,
  );
}

class _NearbyMapWeb extends StatefulWidget {
  final Map<String, dynamic> mainProperty;
  final List<Map<String, dynamic>> nearbyProperties;
  final Function(int id, bool isMain) onMarkerClick;

  const _NearbyMapWeb({
    required this.mainProperty,
    required this.nearbyProperties,
    required this.onMarkerClick,
  });

  @override
  State<_NearbyMapWeb> createState() => _NearbyMapWebState();
}

class _NearbyMapWebState extends State<_NearbyMapWeb> {
  late String _viewId;

  double get _mainLat => double.tryParse(widget.mainProperty['latitude']?.toString() ?? '') ?? 33.5731;
  double get _mainLng => double.tryParse(widget.mainProperty['longitude']?.toString() ?? '') ?? -7.5898;

  @override
  void initState() {
    super.initState();
    _buildMap();
  }

  void _buildMap() {
    _viewId = 'nearby-map-${DateTime.now().millisecondsSinceEpoch}';

    // Build marker JS
    final markersJs = StringBuffer();
    
    // Main property marker (special red larger marker)
    markersJs.writeln('''
      const mainEl = document.createElement('div');
      mainEl.className = 'main-marker';
      mainEl.innerHTML = '<div class="marker-pulse"></div><div class="marker-dot"></div>';
      mainEl.addEventListener('click', () => {
        window.parent.postMessage({ type: 'markerClick', id: ${widget.mainProperty['id']}, isMain: true }, '*');
      });
      new mapboxgl.Marker({element: mainEl})
        .setLngLat([$_mainLng, $_mainLat])
        .addTo(map);
    ''');

    // Bounds to fit all
    markersJs.writeln('const bounds = new mapboxgl.LngLatBounds();');
    markersJs.writeln('bounds.extend([$_mainLng, $_mainLat]);');

    // Nearby markers
    for (final prop in widget.nearbyProperties) {
      final lat = double.tryParse(prop['latitude']?.toString() ?? '');
      final lng = double.tryParse(prop['longitude']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      final id = prop['id'];
      
      markersJs.writeln('''
        const el_$id = document.createElement('div');
        el_$id.className = 'nearby-marker';
        el_$id.innerHTML = '<div class="nearby-dot"></div>';
        el_$id.addEventListener('click', () => {
          window.parent.postMessage({ type: 'markerClick', id: $id, isMain: false }, '*');
        });
        new mapboxgl.Marker({element: el_$id})
          .setLngLat([$lng, $lat])
          .addTo(map);
        bounds.extend([$lng, $lat]);
      ''');
    }

    // Fit bounds if we have nearby
    if (widget.nearbyProperties.isNotEmpty) {
      markersJs.writeln('''
        map.fitBounds(bounds, { padding: 60, maxZoom: 14, duration: 1000 });
      ''');
    }

    final String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no" />
    <script src="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.js"></script>
    <link href="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.css" rel="stylesheet" />
    <style>
        body { margin: 0; padding: 0; overflow: hidden; }
        #map { position: absolute; top: 0; bottom: 0; width: 100%; }
        .mapboxgl-control-container { display: none; }
        
        .main-marker {
          width: 40px; height: 40px;
          cursor: pointer;
          position: relative;
        }
        .marker-pulse {
          width: 40px; height: 40px;
          border-radius: 50%;
          background: rgba(231, 76, 60, 0.25);
          position: absolute;
          animation: pulse 2s infinite;
        }
        .marker-dot {
          width: 18px; height: 18px;
          border-radius: 50%;
          background: #E74C3C;
          border: 3px solid #fff;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
          position: absolute;
          top: 50%; left: 50%;
          transform: translate(-50%, -50%);
        }
        @keyframes pulse {
          0% { transform: scale(0.8); opacity: 1; }
          100% { transform: scale(2); opacity: 0; }
        }
        
        .nearby-marker {
          width: 28px; height: 28px;
          cursor: pointer;
          position: relative;
        }
        .nearby-dot {
          width: 14px; height: 14px;
          border-radius: 50%;
          background: #2ECC71;
          border: 2.5px solid #fff;
          box-shadow: 0 2px 6px rgba(0,0,0,0.25);
          position: absolute;
          top: 50%; left: 50%;
          transform: translate(-50%, -50%);
          transition: all 0.2s;
        }
        .nearby-marker:hover .nearby-dot {
          transform: translate(-50%, -50%) scale(1.3);
          background: #27AE60;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        mapboxgl.accessToken = '${MapConfig.mapboxToken}';
        const map = new mapboxgl.Map({
            container: 'map',
            style: '${MapConfig.getStyleUri(MapStyle.clean)}',
            center: [$_mainLng, $_mainLat],
            zoom: 13,
            pitch: 0,
            antialias: true,
            attributionControl: false
        });
        
        map.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'bottom-right');
        
        map.on('load', () => {
            ${markersJs.toString()}
        });
    </script>
</body>
</html>
''';

    final String base64Html = base64Encode(const Utf8Encoder().convert(htmlContent));
    
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'data:text/html;base64,$base64Html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });

    html.window.onMessage.listen((event) {
      if (event.data is Map) {
        final data = event.data as Map;
        if (data['type'] == 'markerClick') {
          final id = data['id'];
          final isMain = data['isMain'] == true;
          if (mounted) {
            widget.onMarkerClick(id as int, isMain);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
