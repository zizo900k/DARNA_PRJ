import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/map_config.dart';

Widget buildMapboxMap(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  bool isPicker = false,
  MapStyle mapStyle = MapStyle.clean,
  Function(double, double)? onLocationSelected,
}) {
  return _MapboxMobile(
    initialLatitude: initialLatitude,
    initialLongitude: initialLongitude,
    isPicker: isPicker,
    mapStyle: mapStyle,
    onLocationSelected: onLocationSelected,
  );
}

class _MapboxMobile extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool isPicker;
  final MapStyle mapStyle;
  final Function(double, double)? onLocationSelected;

  const _MapboxMobile({
    this.initialLatitude,
    this.initialLongitude,
    this.isPicker = false,
    this.mapStyle = MapStyle.clean,
    this.onLocationSelected,
  });

  @override
  State<_MapboxMobile> createState() => _MapboxMobileState();
}

class _MapboxMobileState extends State<_MapboxMobile> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(MapConfig.mapboxToken);
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    // Hide scale bar/compass for a cleaner look
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _setCircleMarker(widget.initialLatitude!, widget.initialLongitude!);
    }

    if (!widget.isPicker) {
      mapboxMap.gestures.updateSettings(GesturesSettings(
        scrollEnabled: false,
        pitchEnabled: false,
        rotateEnabled: false,
        doubleTapToZoomInEnabled: false,
        pinchToZoomEnabled: false,
        panEnabled: false,
      ));
    }
  }

  void _setMarker(double lat, double lng) async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();
    pointAnnotationManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)).toJson(),
      iconImage: 'marker-15', // Default mapbox marker, or we could load custom
      iconSize: 2.0,
      iconColor: 0xFFE74C3C, // Cannot easily tint default marker without custom image, let's just use default or provide a CircleAnnotation
    ));
    // As alternative for simpler colored dot, we can use CircleAnnotationManager
    // But PointAnnotation with standard icon works. 
  }

  // Use CircleAnnotationManager for a custom colored dot
  CircleAnnotationManager? circleAnnotationManager;
  void _setCircleMarker(double lat, double lng) async {
    if (circleAnnotationManager == null) {
      if (mapboxMap == null) return;
      circleAnnotationManager = await mapboxMap!.annotations.createCircleAnnotationManager();
    }
    await circleAnnotationManager!.deleteAll();
    circleAnnotationManager!.create(CircleAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)).toJson(),
      circleColor: 0xFFE74C3C, // AppColors.primary
      circleRadius: 10.0,
      circleStrokeColor: 0xFFFFFFFF,
      circleStrokeWidth: 3.0,
    ));
  }

  void _onTap(MapContentGestureContext context) {
    if (!widget.isPicker) return;
    final lat = context.point.coordinates.lat.toDouble();
    final lng = context.point.coordinates.lng.toDouble();
    _setCircleMarker(lat, lng);
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(lat, lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.initialLatitude ?? 33.5731;
    final lng = widget.initialLongitude ?? -7.5898;
    
    final bool isPremium = widget.mapStyle == MapStyle.premium3D;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MapWidget(
        key: const ValueKey("mapWidget"),
        styleUri: MapConfig.getStyleUri(widget.mapStyle),
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(lng, lat)).toJson(),
          zoom: isPremium ? 16.0 : 14.0,
          pitch: isPremium ? 45.0 : 0.0,
        ),
        onMapCreated: _onMapCreated,
        onTapListener: _onTap,
      ),
    );
  }
}
