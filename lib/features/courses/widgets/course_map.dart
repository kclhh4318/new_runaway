import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CourseMap extends StatelessWidget {
  final List<LatLng> routePoints;

  const CourseMap({Key? key, required this.routePoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
        zoom: 15.0,
      ),
      polylines: {
        Polyline(
          polylineId: PolylineId('course'),
          points: routePoints,
          color: Colors.blue,
          width: 4,
        ),
      },
    );
  }
}