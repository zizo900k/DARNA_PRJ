import 'package:flutter/material.dart';
import '../../config/map_config.dart';

Widget buildMapboxMap(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  bool isPicker = false,
  MapStyle mapStyle = MapStyle.clean,
  Function(double, double)? onLocationSelected,
}) {
  return const Center(child: Text("Unsupported Platform"));
}
