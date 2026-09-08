import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      final token = response['token'];
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(
        key: 'user_data',
        value: response['user'].toString(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.register(data);
      final token = response['token'];
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(
        key: 'user_data',
        value: response['user'].toString(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    }
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      // Parse JSON string back to Map
      try {
        return Map<String, dynamic>.from(
          // This is a placeholder - actual JSON parsing needed
          {},
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_data', value: userData.toString());
  }
}
