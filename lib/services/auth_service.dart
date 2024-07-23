import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/token_service.dart';
import 'package:new_runaway/services/storage_service.dart';
import 'package:new_runaway/utils/logger.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      logger.info('Attempting to login with username: $username');
      final response = await _apiService.login(username, password);
      logger.info('Login response received: $response');

      if (response.containsKey('access_token') && response.containsKey('refresh_token')) {
        await _storageService.saveString('accessToken', response['access_token']);
        await _storageService.saveString('refreshToken', response['refresh_token']);
        logger.info('Login successful, tokens saved');
        return {'success': true, 'message': 'Login successful'};
      } else {
        logger.warning('Invalid response from server: $response');
        return {'success': false, 'message': 'Invalid server response'};
      }
    } catch (e) {
      logger.severe('Login error: $e');
      String errorMessage = 'An unexpected error occurred';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      logger.info('Attempting to register with username: $username');
      final response = await _apiService.register(username, password);
      logger.info('Registration response received: $response');

      if (response.containsKey('id') && response.containsKey('username')) {
        logger.info('Registration successful, attempting auto-login');
        return await login(username, password);
      } else {
        logger.warning('Invalid response from server: $response');
        return {'success': false, 'message': 'Invalid server response'};
      }
    } catch (e) {
      logger.severe('Registration error: $e');
      String errorMessage = 'An unexpected error occurred';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await _storageService.getString('access_token');
    print('Checking if logged in. Access token exists: ${accessToken != null}'); // 로그 추가
    return accessToken != null;
  }

  Future<void> logout() async {
    print('Logging out'); // 로그 추가
    await _storageService.remove('access_token');
    await _storageService.remove('refresh_token');
    print('Tokens removed'); // 로그 추가
  }
}