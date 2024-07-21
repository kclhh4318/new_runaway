import 'package:runaway/services/api_service.dart';
import 'package:runaway/models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<User> login(String username, String password) async {
    final response = await _apiService.post('login', {
      'username': username,
      'password': password,
    });
    return User.fromJson(response);
  }

  Future<User> register(String username, String email, String password) async {
    final response = await _apiService.post('register', {
      'username': username,
      'email': email,
      'password': password,
    });
    return User.fromJson(response);
  }

  Future<void> logout() async {
    await _apiService.post('logout', {});
  }
}