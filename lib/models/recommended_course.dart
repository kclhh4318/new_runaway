import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecommendedCourse {
  final List<LatLng> points;
  final double distance;
  final String description;
  final List<String> safetyTips;
  final List<String> pointsOfInterest;

  RecommendedCourse({
    required this.points,
    required this.distance,
    required this.description,
    required this.safetyTips,
    required this.pointsOfInterest,
  });

  factory RecommendedCourse.fromJson(Map<String, dynamic> json) {
    return RecommendedCourse(
      points: (json['coordinates'] as List).map((point) {
        return LatLng(point['latitude'] as double, point['longitude'] as double);
      }).toList(),
      distance: (json['distance'] as num).toDouble(),
      description: json['description'] as String,
      safetyTips: (json['safetyTips'] as List).cast<String>(),
      pointsOfInterest: (json['pointsOfInterest'] as List?)?.cast<String>() ?? ['관심 지점 정보가 없습니다.'],
    );
  }
}