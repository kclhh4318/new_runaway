import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String baseUrl = 'https://api.openai.com/v1';
  final String apiKey;

  OpenAIService() : apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> getRecommendedCourse(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that recommends running courses based on user-drawn routes. You have to separate the sidewalk from the roadway on map and make a running course based on the sidewalk.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get course recommendation');
    }
  }
}