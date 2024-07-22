import 'package:google_maps_flutter/google_maps_flutter.dart';

class DrawnCourse {
  final List<LatLng> points;

  DrawnCourse({required this.points});

  List<Map<String, double>> toJson() {
    return points.map((point) => {
      'latitude': point.latitude,
      'longitude': point.longitude,
    }).toList();
  }
}