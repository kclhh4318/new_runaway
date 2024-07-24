import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

class OpenAIService {
  final String baseUrl = 'https://api.openai.com/v1';
  final String apiKey;

  OpenAIService() : apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> getRecommendedCourse(String prompt) async {
    try {
      logger.info('Sending request to OpenAI API');
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that recommends running courses based on user-drawn routes. Respond with a valid JSON object without any markdown formatting.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
        }),
      );

      logger.info('Received response from OpenAI API: ${response.statusCode}');

      logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];

        logger.info('Full response content: $content');

        // Remove any markdown formatting if present
        content = content.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'\n?```'), '');

        content = _fixIncompleteJson(content);

        // Validate JSON
        try {
          json.decode(content);
        } catch (e) {
          logger.severe('Invalid JSON: $e');
          logger.severe('Problematic content: $content');
          throw FormatException('Invalid JSON in API response');
        }

        return content;
      } else {
        throw Exception('Failed to get course recommendation: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      logger.severe('Error in OpenAI service: $e');
      rethrow;
    }
  }

  String _fixIncompleteJson(String jsonString) {
    // 마지막 중괄호와 대괄호를 찾아 닫아줍니다.
    int openBraces = jsonString.split('{').length - jsonString.split('}').length;
    int openBrackets = jsonString.split('[').length - jsonString.split(']').length;

    String fixedJson = jsonString;
    for (int i = 0; i < openBraces; i++) {
      fixedJson += '}';
    }
    for (int i = 0; i < openBrackets; i++) {
      fixedJson += ']';
    }

    return fixedJson;
  }

}