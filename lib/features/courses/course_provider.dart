import 'package:flutter/foundation.dart';
import 'dart:convert';
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
      2. Avoids highways and major roads
      3. Prefers paths with sidewalks or dedicated running/cycling paths
      4. Includes interesting landmarks or scenic areas if possible
      5. Maintains a similar total distance to the original drawn course

      Provide the recommended course as a list of LatLng coordinates, along with:
      - The total distance of the course in kilometers
      - A brief description of the route
      - Any safety tips or considerations for runners

      Format your response as a JSON object for easy parsing.
      ''';

      final recommendation = await _openAIService.getRecommendedCourse(prompt);
      _recommendedCourse = _parseRecommendation(recommendation);
      _totalDistance = _recommendedCourse!.distance;
      notifyListeners();
    } catch (e) {
      print('Error analyzing and recommending course: $e');
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

  void reanalyze() {
    if (_recommendedCourse != null) {
      analyzeAndRecommendCourse(_recommendedCourse!.points);
    }
  }
}