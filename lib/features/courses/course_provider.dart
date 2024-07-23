import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/models/recommended_course.dart';
import 'package:new_runaway/services/openai_service.dart';

class CourseProvider extends ChangeNotifier {
  final OpenAIService _openAIService = OpenAIService();
  RecommendedCourse? _recommendedCourse;
  double _totalDistance = 0.0;

  RecommendedCourse? get recommendedCourse => _recommendedCourse;
  double get totalDistance => _totalDistance;

  Future<void> analyzeAndRecommendCourse(List<LatLng> drawnPoints) async {
    try {
      final pointsJson = drawnPoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList();

      final prompt = '''
      Given the following drawn course coordinates:
      $pointsJson
      
      Please analyze this course and recommend a similar running route that:
      1. Follows the general shape and direction of the drawn course
      2. STRICTLY avoids highways, major roads, and any areas not suitable for pedestrians
      3. Adjusts the route to follow actual roads, paths, or trails that runners can safely use
      4. Prioritizes pedestrian-friendly areas such as sidewalks, parks, or dedicated running paths
      5. Maintains a similar total distance to the original drawn course (within 15% deviation)
      6. Ensures the route is circular (start and end points should be within 100 meters of each other)
      7. Includes at least one interesting landmark or scenic area if possible
      8. Limits the number of sharp turns or complex intersections for runner safety
      9. Considers potential running hazards and tries to minimize them

      The recommended course must be significantly different from the original drawn course to ensure it follows real, safe running paths.

      Provide the recommended course as a list of LatLng coordinates, along with:
      - The total distance of the course in kilometers (must be different from the original)
      - A brief description of the route, highlighting any notable features or areas
      - At least three specific safety tips or considerations for runners on this route

      Format your response as a JSON object for easy parsing, including the following keys:
      coordinates, distance, description, safetyTips
      ''';

      final recommendation = await _openAIService.getRecommendedCourse(prompt);
      _recommendedCourse = _parseRecommendation(recommendation);
      _totalDistance = _recommendedCourse!.distance;
      notifyListeners();
    } catch (e) {
      print('Error analyzing and recommending course: $e');
      _recommendedCourse = _createDefaultCourse(drawnPoints);
      _totalDistance = _calculateDistance(drawnPoints);
      notifyListeners();
    }
  }

  RecommendedCourse _parseRecommendation(String recommendation) {
    final Map<String, dynamic> data = json.decode(recommendation);

    final List<LatLng> points = (data['coordinates'] as List).map((point) {
      return LatLng(point['latitude'], point['longitude']);
    }).toList();

    final double distance = data['distance'];
    final String description = data['description'] ?? '';
    final String safetyTips = data['safetyTips'] ?? '';

    return RecommendedCourse(
      points: points,
      distance: distance,
      description: description,
      safetyTips: safetyTips,
    );
  }

  RecommendedCourse _createDefaultCourse(List<LatLng> drawnPoints) {
    return RecommendedCourse(
      points: drawnPoints,
      distance: _calculateDistance(drawnPoints),
      description: '사용자가 그린 원본 코스입니다. 실제 달릴 수 있는 경로로 조정이 필요할 수 있습니다.',
      safetyTips: '주변 환경에 주의하며 안전하게 달리세요. 차도나 위험한 지역을 피해 달리세요.',
    );
  }

  double _calculateDistance(List<LatLng> points) {
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _haversineDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  double _haversineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // 킬로미터
    double lat1 = start.latitude * (pi / 180);
    double lon1 = start.longitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double lon2 = end.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> reanalyze() async {
    if (_recommendedCourse != null) {
      await analyzeAndRecommendCourse(_recommendedCourse!.points);
    }
  }
}