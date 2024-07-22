import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecommendedCourse {
  final List<LatLng> points;
  final double distance;
  final String description;
  final String safetyTips;

  RecommendedCourse({
    required this.points,
    required this.distance,
    required this.description,
    required this.safetyTips,
  });
}