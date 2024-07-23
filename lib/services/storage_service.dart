import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class StorageService {
  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> saveUserId(String userId) async {
    await saveString('userId', userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    logger.info('Retrieved user ID from storage: $userId');
    return userId;
  }

  Future<void> printSavedTokens() async {
    final accessToken = await getString('accessToken');
    final refreshToken = await getString('refreshToken');
    print('Saved Access Token: $accessToken');
    print('Saved Refresh Token: $refreshToken');
  }
}