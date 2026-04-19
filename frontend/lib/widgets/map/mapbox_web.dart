// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import '../../config/map_config.dart';

Widget buildMapboxMap(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  bool isPicker = false,
  MapStyle mapStyle = MapStyle.clean,
  Function(double, double)? onLocationSelected,
}) {
  return _MapboxWeb(
    initialLatitude: initialLatitude,
    initialLongitude: initialLongitude,
    isPicker: isPicker,
    mapStyle: mapStyle,
    onLocationSelected: onLocationSelected,
  );
}

class _MapboxWeb extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool isPicker;
  final MapStyle mapStyle;
  final Function(double, double)? onLocationSelected;

  const _MapboxWeb({
    this.initialLatitude,
    this.initialLongitude,
    this.isPicker = false,
    this.mapStyle = MapStyle.clean,
    this.onLocationSelected,
  });

  @override
  State<_MapboxWeb> createState() => _MapboxWebState();
}

class _MapboxWebState extends State<_MapboxWeb> {
  late String viewId;

  @override
  void initState() {
    super.initState();
    viewId = 'mapbox-web-${DateTime.now().millisecondsSinceEpoch}';

    final lat = widget.initialLatitude ?? 33.5731;
    final lng = widget.initialLongitude ?? -7.5898;
    final hasMarker = widget.initialLatitude != null && widget.initialLongitude != null;

    final bool isPremium = widget.mapStyle == MapStyle.premium3D;
    
    final String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Mapbox</title>
    <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no" />
    <script src="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.js"></script>
    <link href="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.css" rel="stylesheet" />
    <style>
        body { margin: 0; padding: 0; overflow: hidden; }
        #map { position: absolute; top: 0; bottom: 0; width: 100%; border-radius: 16px; }
        .mapboxgl-control-container { display: none; }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        mapboxgl.accessToken = '${MapConfig.mapboxToken}';
        const map = new mapboxgl.Map({
            container: 'map',
            style: '${MapConfig.getStyleUri(widget.mapStyle)}',
            center: [$lng, $lat],
            zoom: ${isPremium ? 17 : 14}, // Zoom in more for satellite to show detail
            pitch: 0, // Flat top-down view
            antialias: true,
            attributionControl: false
        });
        
        map.on('load', () => {
            // Add marker after load
            if ($hasMarker || !${widget.isPicker}) {
                if ($hasMarker) {
                    new mapboxgl.Marker({ color: "#E74C3C" })
                        .setLngLat([$lng, $lat])
                        .addTo(map);
                }
            }
        });

        if (${widget.isPicker}) {
            let marker = null;
            if ($hasMarker) {
                marker = new mapboxgl.Marker({ color: "#E74C3C" })
                    .setLngLat([$lng, $lat])
                    .addTo(map);
            }
            
            map.on('click', (e) => {
                if (marker) marker.remove();
                marker = new mapboxgl.Marker({ color: "#E74C3C" })
                    .setLngLat([e.lngLat.lng, e.lngLat.lat])
                    .addTo(map);
                window.parent.postMessage({ type: 'mapClick', lat: e.lngLat.lat, lng: e.lngLat.lng }, '*');
            });
        } else {
            // display only
            map.scrollZoom.disable();
            map.dragPan.disable();
            map.doubleClickZoom.disable();
            map.touchZoomRotate.disable();
        }
    </script>
</body>
</html>
''';

    final String base64Html = base64Encode(const Utf8Encoder().convert(htmlContent));
    
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'data:text/html;base64,$base64Html'
        ..style.border = 'none'
        ..style.borderRadius = '16px'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });

    html.window.onMessage.listen((event) {
      if (widget.onLocationSelected == null) return;
      if (event.data is Map) {
        final data = event.data as Map;
        if (data['type'] == 'mapClick') {
          widget.onLocationSelected!(data['lat'], data['lng']);
        }
      } else {
        try {
          final jsObj = event.data;
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewId);
  }
}
