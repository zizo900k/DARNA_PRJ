import 'package:flutter/material.dart';

Widget buildNearbyMapView({
  required Map<String, dynamic> mainProperty,
  required List<Map<String, dynamic>> nearbyProperties,
  required Function(int id, bool isMain) onMarkerClick,
}) {
  return const Center(
    child: Text('Map view is only supported on web currently.'),
  );
}
