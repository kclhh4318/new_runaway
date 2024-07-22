import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/token_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);

      if (response.containsKey('access_token') && response.containsKey('refresh_token')) {
        await _tokenService.setTokens(response['access_token'], response['refresh_token']);
        return true;
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await _apiService.register(username, password);

      if (response.containsKey('id') && response.containsKey('username')) {
        return await login(username, password);
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.post('logout', {});
    await _tokenService.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await _tokenService.getAccessToken();
    return accessToken != null;
  }
}