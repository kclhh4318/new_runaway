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

Your task is to create a realistic and safe running route based on these coordinates. However, DO NOT simply connect these points. Instead, use them as a general guide to create a route that follows actual roads and pedestrian paths. Your route should:

1. Follow the general shape and direction of the drawn course, but prioritize using real roads and paths.
2. Ensure EVERY point in your recommended route is on an actual road, sidewalk, or pedestrian path. Do not include any points that would be inside buildings or inaccessible areas.
3. Adjust the route significantly if necessary to follow real-world infrastructure. It's okay if the final route deviates from the original drawing, as long as it maintains a similar overall shape and distance.
4. Prioritize pedestrian-friendly areas such as sidewalks, park paths, and quiet residential streets.
5. Avoid highways, major roads without sidewalks, and any areas unsafe for pedestrians.
6. Use crosswalks or pedestrian crossings when the route needs to cross streets.
7. Include parks, trails, or scenic areas if they fit naturally into the route.
8. Try to create a circular route if possible, but prioritize safety and realism over perfect circularity.
9. Aim for a total distance similar to what the original drawn course would be (within 20% deviation).
10. Minimize sharp turns and complex intersections for runner safety and convenience.

For your response, please provide:
1. A list of LatLng coordinates that represent your recommended route. These should be actual points on roads or paths.
2. The total distance of your recommended route in kilometers (to two decimal places).
3. A detailed description of the route, highlighting how it follows actual roads and paths, and noting any significant deviations from the original drawn course.
4. At least five specific safety tips for runners on this route.
5. Any points of interest or landmarks that would likely be along this route.

Format your response as a JSON object with the following keys:
coordinates, distance, description, safetyTips, pointsOfInterest

Ensure your JSON is valid and contains no additional formatting or markdown.
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