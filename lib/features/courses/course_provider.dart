import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/models/recommended_course.dart';
import 'package:new_runaway/services/openai_service.dart';
import 'package:new_runaway/services/api_service.dart';

class CourseProvider extends ChangeNotifier {
  Completer<GoogleMapController>? mapController;
  final ApiService _apiService = ApiService();
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

Please analyze this course and recommend a safe, realistic running route that STRICTLY adheres to actual roads, sidewalks, and pedestrian paths. Your task is to create a route that:

1. Uses ONLY existing roads, sidewalks, pedestrian paths, and public spaces that are accessible and safe for runners. Do NOT include any coordinates that would require running through buildings, private property, or inaccessible areas.

2. Prioritizes runner safety and accessibility over exact replication of the original drawn course. It's okay if the final route deviates significantly from the original, as long as it's safe and runnable.

3. Follows the general direction of the drawn course, but ALWAYS adjusts to the nearest accessible pedestrian path or sidewalk.

4. Absolutely avoids highways, major roads without sidewalks, and any areas unsafe or unsuitable for pedestrians.

5. Utilizes crosswalks and pedestrian crossings when crossing streets is necessary.

6. Incorporates parks, trails, or scenic areas if they are nearby and accessible, prioritizing runner-friendly environments.

7. Creates a route with a similar total distance to the original (within 20% deviation), but this is less important than ensuring the route is safe and realistic.

8. Aims for a circular route if possible, but prioritize safety and realistic paths over making the route circular.

9. Minimizes the number of turns and avoids complex intersections where possible to keep the route simple and safe.

10. Considers potential running hazards (e.g., busy streets, poor lighting areas) and provides safer alternatives.

When providing coordinates, ensure that EACH AND EVERY coordinate point corresponds to an actual road, sidewalk, or pedestrian path. Do not include any points that would require a runner to leave a publicly accessible path.

Provide the recommended course as a list of LatLng coordinates, along with:
- The total distance of the course in kilometers (accurate to two decimal places)
- A brief description of the route, highlighting how it follows actual roads and paths
- At least three specific safety tips or considerations for runners on this route
- Any potential points of interest or landmarks along the way that are actually on the route

Format your response as a JSON object for easy parsing, including the following keys:
coordinates, distance, description, safetyTips, pointsOfInterest

Ensure that the JSON is valid and does not include any additional formatting or markdown. Double-check that all JSON objects and arrays are properly closed.
''';

      final recommendation = await _openAIService.getRecommendedCourse(prompt);
      _recommendedCourse = _parseRecommendation(recommendation);
      _totalDistance = _recommendedCourse!.distance;
      notifyListeners();
    } catch (e) {
      print('Error analyzing and recommending course: $e');
      if (e is Exception) {
        print('Exception details: ${e.toString()}');
      }
      // OpenAI 서비스 실패 시 기본 코스 사용
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

  Future<Map<String, dynamic>> createCourse(List<LatLng> routePoints, String imageData) async {
    final routeCoordinate = {
      "type": "LineString",
      "coordinates": routePoints.map((point) => [point.latitude, point.longitude]).toList(),
    };

    final data = {
      "route": imageData,
      "route_coordinate": routeCoordinate,
      "distance": _totalDistance,
    };

    try {
      final response = await _apiService.createCourse(data);
      return response;
    } catch (e) {
      print('Error creating course: $e');
      rethrow;
    }
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

  void setMapController(Completer<GoogleMapController> controller) {
    mapController = controller;
    notifyListeners();
  }

  Future<void> reanalyze() async {
    if (_recommendedCourse != null) {
      await analyzeAndRecommendCourse(_recommendedCourse!.points);
    }
  }
}