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

      if (response.containsKey('access_token') && response.containsKey('refresh_token') && response.containsKey('user_id')) {
        await _storageService.saveString('accessToken', response['access_token']);
        await _storageService.saveString('refreshToken', response['refresh_token']);
        await _storageService.saveString('userId', response['user_id']);
        await _storageService.saveString('username', username);  // 사용자 이름 저장
        logger.info('Login successful, tokens, user_id, and username saved');
        return {'success': true, 'message': 'Login successful', 'user_id': response['user_id']};
      } else {
        logger.warning('Invalid response from server: $response');
        return {'success': false, 'message': '아이디 또는 비밀번호가 잘못 되었습니다. 아이디와 비밀번호를 정확히 입력해 주세요.'};
      }
    } catch (e) {
      logger.severe('Login error: $e');
      return {'success': false, 'message': '로그인 중 오류가 발생했습니다. 다시 시도해 주세요.'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      logger.info('Attempting to register with username: $username');
      final response = await _apiService.register(username, password);
      logger.info('Registration response received: $response');

      if (response.containsKey('id') && response.containsKey('username')) {
        logger.info('Registration successful');
        return {'success': true, 'message': '회원가입이 완료되었습니다.'};
      } else if (response.containsKey('error')) {
        logger.warning('Registration failed: ${response['error']}');
        return {'success': false, 'message': response['error']};
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
    print('Checking if logged in. Access token exists: ${accessToken != null}');
    return accessToken != null;
  }

  Future<void> logout() async {
    print('Logging out');
    await _storageService.remove('access_token');
    await _storageService.remove('refresh_token');
    print('Tokens removed');
  }
}