import 'package:flutter/material.dart';
import '../../config/map_config.dart';

import 'mapbox_stub.dart'
    if (dart.library.io) 'mapbox_mobile.dart'
    if (dart.library.html) 'mapbox_web.dart';

class MapboxWidget extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool isPicker;
  final MapStyle mapStyle;
  final Function(double, double)? onLocationSelected;

  const MapboxWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.isPicker = false,
    this.mapStyle = MapStyle.clean,
    this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return buildMapboxMap(
      context,
      initialLatitude: initialLatitude,
      initialLongitude: initialLongitude,
      isPicker: isPicker,
      mapStyle: mapStyle,
      onLocationSelected: onLocationSelected,
    );
  }
}
