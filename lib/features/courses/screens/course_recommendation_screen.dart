import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GPT4CourseRecommendationService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<Map<String, dynamic>> getRecommendation(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this map image with a drawn route. Recommend a similar running course that follows actual roads and paths, avoiding highways and unsafe areas. Provide the course as a list of LatLng coordinates, total distance, description, and safety tips.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/png;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 500
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get course recommendation: ${response.body}');
      }
    } catch (e) {
      print('Error getting course recommendation: $e');
      rethrow;
    }
  }
}