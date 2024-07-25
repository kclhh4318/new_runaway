import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/models/recommended_course.dart';
import 'package:new_runaway/services/openai_service.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/logger.dart';

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
      final refinedPoints = await _refineDrawnPoints(drawnPoints);
      if (refinedPoints.isEmpty) {
        throw Exception('Refined points are empty');
      }

      final pointsJson = refinedPoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList();


      final prompt = '''
Given the following drawn course coordinates:
$pointsJson

Create a running route that closely follows these coordinates while adhering to the following strict rules:
1. Prioritize major roads with sidewalks for the route.
2. Ensure that every point of the recommended route is on a road with a sidewalk or pedestrian path.
3. The shape and distance of the route should be as close as possible to the original drawn course.
4. Use proper crosswalks or pedestrian crossings when the route needs to cross streets.
5. If a major road with a sidewalk is not available, choose the next best option that ensures runner safety.
6. The total distance of the recommended route should be within 15% of the original drawn course length to account for potentially longer routes on major roads.
7. Include any notable landmarks or points of interest along the major roads in the route description.

Provide your response as a JSON object with these keys:
coordinates (list of LatLng), distance (km), description, safetyTips, pointsOfInterest

Ensure your JSON is valid and contains no additional formatting or markdown.
''';

      final recommendation = await _openAIService.getRecommendedCourse(prompt);
      _recommendedCourse = _parseRecommendation(recommendation);
      _totalDistance = _recommendedCourse!.distance;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error analyzing and recommending course: $e');
      print('Stack trace: $stackTrace');
      _recommendedCourse = _createDefaultCourse(drawnPoints);
      _totalDistance = _calculateDistance(drawnPoints);
      notifyListeners();
    }
  }

  RecommendedCourse _parseRecommendation(String recommendation) {
    final Map<String, dynamic> data = json.decode(recommendation);
    return RecommendedCourse.fromJson(data);
  }

  RecommendedCourse _createDefaultCourse(List<LatLng> drawnPoints) {
    return RecommendedCourse(
      points: drawnPoints,
      distance: _calculateDistance(drawnPoints),
      description: '사용자가 그린 원본 코스입니다. 실제 달릴 수 있는 경로로 조정이 필요할 수 있습니다.',
      safetyTips: ['주변 환경에 주의하며 안전하게 달리세요.', '차도나 위험한 지역을 피해 달리세요.'],
      pointsOfInterest: ['기본 코스에는 특별한 관심 지점이 없습니다.'],
    );
  }

  // course_provider.dart
  Future<String?> createCourse(List<LatLng> routePoints, String imageData, int courseType) async {
    logger.info('Creating course in CourseProvider');
    logger.info('Course type: $courseType');

    final routeCoordinate = {
      "type": "LineString",
      "coordinates": routePoints.map((point) => [point.longitude, point.latitude]).toList(),
    };

    final data = {
      "route": imageData,
      "route_coordinate": routeCoordinate,
      "distance": _totalDistance,
      "course_type": courseType,
    };

    try {
      logger.info('Calling API service to create course');
      final response = await _apiService.createCourse(data);
      logger.info('Course creation successful');
      logger.info('Response: $response');

      if (response.containsKey('id')) {
        final courseId = response['id'] as String;
        logger.info('Course ID received: $courseId');
        return courseId;
      } else {
        logger.warning('No course ID found in the response');
        return null;
      }
    } catch (e) {
      logger.severe('Error creating course: $e');
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

  Future<List<LatLng>> _refineDrawnPoints(List<LatLng> drawnPoints) async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> refinedPoints = [];

    for (int i = 0; i < drawnPoints.length - 1; i += 2) {
      PointLatLng start = PointLatLng(drawnPoints[i].latitude, drawnPoints[i].longitude);
      PointLatLng end = PointLatLng(drawnPoints[i + 1].latitude, drawnPoints[i + 1].longitude);

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        dotenv.env['GOOGLE_MAPS_API_KEY']!,
        start,
        end,
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        refinedPoints.addAll(result.points.map((point) => LatLng(point.latitude, point.longitude)));
      } else {
        // 경로를 찾지 못한 경우, 원본 점들을 사용
        refinedPoints.add(drawnPoints[i]);
        if (i + 1 < drawnPoints.length) {
          refinedPoints.add(drawnPoints[i + 1]);
        }
      }
    }

    if (refinedPoints.isEmpty) {
      // 정제된 점들이 없으면 원본 점들을 그대로 반환
      return drawnPoints;
    }

    return refinedPoints;
  }

}
