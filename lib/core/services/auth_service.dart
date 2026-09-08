import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Attempts to sign in. Returns `null` on success or a human-readable error
  /// message on failure.
  Future<String?> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      await _storeSession(response);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  /// Attempts to create an account. Returns `null` on success or a
  /// human-readable error message on failure.
  Future<String?> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.register(data);
      await _storeSession(response);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with local logout even if the API call fails.
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (_) {
      // No storage access (e.g. in widget tests) => treat as signed out.
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user));
    } catch (_) {
      // Ignore storage failures in environments without a backing store.
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? raw;
    try {
      raw = await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Persists the token and user from a successful auth response.
  Future<void> _storeSession(Map<String, dynamic> response) async {
    final token = response['token'];
    final user = response['user'];
    if (token != null) {
      await _storage.write(key: _tokenKey, value: token.toString());
    }
    if (user is Map<String, dynamic>) {
      await saveUserData(user);
    }
  }

  /// Pulls a readable message out of a DioException (401 "Invalid
  /// credentials", 422 validation errors, network issues, etc.).
  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        // Laravel sends validation errors as: { "errors": { "email": [ ... ] } }
        final errors = data['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              return value.first.toString();
            }
          }
        }
      }
      if (error.response?.statusCode == 401) {
        return 'Invalid email or password.';
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
