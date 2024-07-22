import 'package:new_runaway/services/storage_service.dart';

class TokenService {
  final StorageService _storageService = StorageService();

  Future<String?> getAccessToken() async {
    return await _storageService.getString('accessToken');
  }

  Future<String?> getRefreshToken() async {
    return await _storageService.getString('refreshToken');
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storageService.saveString('accessToken', accessToken);
    await _storageService.saveString('refreshToken', refreshToken);
  }

  Future<void> clearTokens() async {
    await _storageService.remove('accessToken');
    await _storageService.remove('refreshToken');
  }
}