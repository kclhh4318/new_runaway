import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:new_runaway/config/app_config.dart';
import 'package:new_runaway/services/token_service.dart';
import 'package:new_runaway/services/storage_service.dart';
import 'package:new_runaway/utils/logger.dart';
import 'package:new_runaway/models/running_session.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final TokenService _tokenService = TokenService();
  final StorageService _storageService = StorageService();

  Future<dynamic> get(String endpoint) async {
    return _request(() async => http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    ));
  }

  Future<http.Response> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    logger.info('Sending POST request to endpoint: $endpoint');
    final allHeaders = await _getHeaders();
    if (headers != null) {
      allHeaders.addAll(headers);
    }
    logger.info('Request headers: $allHeaders');
    logger.info('Request body: ${json.encode(data)}');

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: allHeaders,
      body: json.encode(data),
    );

    logger.info('Response status code: ${response.statusCode}');
    logger.info('Response body: ${response.body}');

    return response;
  }

  Future<Map<String, String>> _getHeaders() async {
    final accessToken = await _tokenService.getAccessToken();
    final userId = await _storageService.getUserId();

    logger.info('Getting headers. User ID: $userId');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (userId != null) 'x-user-id': userId,
    };
  }

  Future<dynamic> _request(Future<http.Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await requestFunction();
        } else {
          throw Exception('Token refresh failed');
        }
      }
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<Map<String, dynamic>> startRunningSession() async {
    logger.info('Starting running session');
    final userId = await _storageService.getUserId();
    final response = await post(
      'running_sessions/start',
      {},
      headers: {'x-user-id': userId ?? ''},
    );
    logger.info('Running session start response: ${response.body}');
    return json.decode(response.body);
  }

  Future<void> endRunningSession(String sessionId, Map<String, dynamic> sessionData) async {
    logger.info('Ending running session');
    logger.info('Session ID: $sessionId');
    logger.info('Session data: $sessionData');
    final response = await post('running_sessions/$sessionId/end', sessionData);
    logger.info('Running session end response: ${response.body}');
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _tokenService.setTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    return false;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _tokenService.setTokens(data['access_token'], data['refresh_token']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to register: ${response.statusCode}');
    }
  }

  Future<List<RunningSession>> getRecentRuns(String userId) async {
    try {
      final response = await get('running_sessions/runs/$userId');
      print('Raw response: $response');
      if (response == null || response is! List) {
        print('Unexpected response type: ${response.runtimeType}');
        return [];
      }
      return response.map((json) {
        try {
          return RunningSession.fromJson(json);
        } catch (e) {
          print('Error parsing RunningSession: $e');
          print('Problematic JSON: $json');
          return null;
        }
      }).whereType<RunningSession>().toList();
    } catch (e) {
      print('Error getting recent runs: $e');
      return [];
    }
  }

  Future<List<RunningSession>> getAllRuns(String userId) async {
    try {
      final response = await get('running_sessions/all_runs/$userId');
      if (response == null || response is! List) {
        print('Unexpected response type: ${response.runtimeType}');
        return [];
      }
      return response.map((json) => RunningSession.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all runs: $e');
      return [];
    }
  }

}
