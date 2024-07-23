import 'package:new_runaway/services/storage_service.dart';

class SessionService {
  final StorageService _storageService = StorageService();

  Future<bool> isLoggedIn() async {
    final accessToken = await _storageService.getString('accessToken');
    final refreshToken = await _storageService.getString('refreshToken');
    return accessToken != null && refreshToken != null;
  }
}