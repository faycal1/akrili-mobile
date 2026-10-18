import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  static const String _keyToken = 'auth_token';
  static const String _keyFcmToken = 'fcm_device_token';
  static const String _keyUserJson = 'auth_user_json';
  static const String _keyActiveRole = 'active_app_role';
  static const String _keyCustomBaseUrl = 'custom_base_url';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveFcmToken(String fcmToken) async {
    await _storage.write(key: _keyFcmToken, value: fcmToken);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: _keyFcmToken);
  }

  Future<void> deleteFcmToken() async {
    await _storage.delete(key: _keyFcmToken);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: _keyUserJson, value: userJson);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUserJson);
  }

  Future<void> saveActiveRole(String role) async {
    await _storage.write(key: _keyActiveRole, value: role);
  }

  Future<String?> getActiveRole() async {
    return await _storage.read(key: _keyActiveRole);
  }

  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _keyCustomBaseUrl, value: url);
  }

  Future<String?> getBaseUrl() async {
    return await _storage.read(key: _keyCustomBaseUrl);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserJson);
    await _storage.delete(key: _keyActiveRole);
  }
}
