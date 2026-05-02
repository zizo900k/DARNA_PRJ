import 'package:flutter/material.dart';
import '../../config/map_config.dart';
import '../../theme/language_provider.dart';

Widget buildMapboxMap(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  bool isPicker = false,
  MapStyle mapStyle = MapStyle.clean,
  Function(double, double)? onLocationSelected,
}) {
  return Center(child: Text(context.tr('unsupported_platform')));
}
