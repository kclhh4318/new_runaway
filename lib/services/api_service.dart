import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:new_runaway/config/app_config.dart';
import 'package:new_runaway/services/token_service.dart';
import 'package:new_runaway/services/storage_service.dart';
import 'package:new_runaway/utils/logger.dart';
import 'package:new_runaway/models/running_session.dart';
import 'package:new_runaway/models/course.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final TokenService _tokenService = TokenService();
  final StorageService _storageService = StorageService();

  Future<dynamic> get(String endpoint) async {
    logger.info('Sending GET request to endpoint: $endpoint');
    final headers = await _getHeaders();
    logger.info('Request headers: $headers');

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    logger.info('Response status code: ${response.statusCode}');
    logger.info('Response body: ${response.body}');

    return _handleResponse(response);
  }

  Future<http.Response> post(String endpoint, dynamic data, {Map<String, String>? additionalHeaders}) async {
    logger.info('Sending POST request to endpoint: $endpoint');
    final allHeaders = await _getHeaders();
    if (additionalHeaders != null) {
      allHeaders.addAll(additionalHeaders);
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
      additionalHeaders: {'x-user-id': userId ?? ''},
    );
    logger.info('Running session start response: ${response.body}');
    return json.decode(response.body);
  }

  Future<void> endRunningSession(String sessionId, Map<String, dynamic> sessionData, String? courseId) async {
    logger.info('Ending running session');
    logger.info('Session ID: $sessionId');
    logger.info('Course ID being sent to server: $courseId');

    final fullSessionData = {
      ...sessionData,
      'course_id': courseId,
    };

    logger.info('Full session data being sent to server:');
    logger.info(json.encode(fullSessionData, toEncodable: (object) {
      if (object is LatLng) {
        return {'latitude': object.latitude, 'longitude': object.longitude};
      }
      return object.toString();
    }));

    final response = await post('running_sessions/$sessionId/end', fullSessionData);
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

  // api_service.dart
  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    final userId = await _storageService.getUserId();
    if (userId == null) {
      throw Exception('User ID is not available');
    }
    logger.info('Creating course for user ID: $userId');
    logger.info('Course data: $data');

    final response = await post(
      'courses/create_course/$userId',
      data,
    );
    final responseData = json.decode(response.body);
    logger.info('Create course response: $responseData');
    return responseData;
  }

  Future<Map<String, dynamic>> getStats(String period, String userId) async {
    String endpoint;
    switch (period) {
      case '주':
        endpoint = 'stats/weekly/$userId';
        break;
      case '월':
        endpoint = 'stats/monthly/$userId';
        break;
      case '년':
        endpoint = 'stats/yearly/$userId';
        break;
      case '전체':
      default:
        endpoint = 'stats/all_time/$userId';
    }
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  Future<List<Course>> getLatestCourses(double latitude, double longitude) async {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
    };

    logger.info('Sending request to /courses/latest with data: $data');

    try {
      final response = await post('courses/latest', data);

      logger.info('Received response from /courses/latest');
      logger.info('Status code: ${response.statusCode}');
      logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        logger.info('Parsed JSON list: $jsonList');
        final courses = jsonList.map((json) {
          logger.info('Processing course JSON:');
          json.forEach((key, value) {
            logger.info('  $key: ${value.runtimeType} = $value');
          });
          return Course.fromJson(json);
        }).toList();
        logger.info('Converted courses: $courses');
        return courses;
      } else {
        throw Exception('최신 코스를 불러오는 데 실패했다모! 상태 코드: ${response.statusCode}, 응답: ${response.body}');
      }
    } catch (e) {
      logger.severe('Error in getLatestCourses: $e');
      rethrow;
    }
  }

  Future<List<Course>> getMyDrawnCourses(String userId) async {
    logger.info('Fetching drawn courses for user ID: $userId');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/courses/all_courses/$userId'),
        headers: await _getHeaders(),
      );

      logger.info('Response status code: ${response.statusCode}');
      logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final courses = jsonData.map((json) => Course.fromJson(json)).toList();
        logger.info('Fetched ${courses.length} courses');
        return courses;
      } else {
        logger.severe('Failed to load drawn courses: ${response.statusCode}');
        throw Exception('Failed to load drawn courses');
      }
    } catch (e) {
      logger.severe('Error fetching drawn courses: $e');
      return [];
    }
  }

  // lib/services/api_service.dart에 추가

  Future<bool> logout() async {
    logger.info('Logging out user');
    final accessToken = await _tokenService.getAccessToken();

    if (accessToken == null) {
      logger.warning('No access token found for logout');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      logger.info('Logout response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _tokenService.clearTokens();
        await _storageService.remove('userId');
        logger.info('User logged out successfully');
        return true;
      } else {
        logger.warning('Logout failed: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.severe('Error during logout: $e');
      return false;
    }
  }

}
