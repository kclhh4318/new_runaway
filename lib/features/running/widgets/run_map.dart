import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunMap extends StatelessWidget {
  final List<LatLng> routePoints;
  final List<LatLng>? predefinedCourse;

  const RunMap({
    Key? key,
    required this.routePoints,
    this.predefinedCourse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: routePoints.isNotEmpty ? routePoints.last : LatLng(37.5665, 126.9780),
        zoom: 15.0,
      ),
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: Colors.red,
          width: 4,
        ),
        if (predefinedCourse != null)
          Polyline(
            polylineId: PolylineId('predefined_course'),
            points: predefinedCourse!,
            color: Colors.blue,
            width: 4,
          ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}