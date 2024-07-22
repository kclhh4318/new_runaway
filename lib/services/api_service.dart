import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:new_runaway/config/app_config.dart';
import 'package:new_runaway/services/token_service.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final TokenService _tokenService = TokenService();

  Future<dynamic> get(String endpoint) async {
    return _request(() async => http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    ));
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    return _request(() async => http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(data),
    ));
  }

  Future<Map<String, String>> _getHeaders() async {
    final accessToken = await _tokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
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
}