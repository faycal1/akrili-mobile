import 'dart:convert';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client;
  final SecureStorageService _storage;

  AuthRepository({
    required ApiClient client,
    required SecureStorageService storage,
  })  : _client = client,
        _storage = storage;

  ApiClient get client => _client;

  Future<UserModel> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'device_name': deviceName ?? 'Mobile App',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.saveToken(token);
    await _storage.saveUserJson(jsonEncode(user.toJson()));

    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? role,
    String? deviceName,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'role': role ?? 'tenant',
        'device_name': deviceName ?? 'Mobile App',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.saveToken(token);
    await _storage.saveUserJson(jsonEncode(user.toJson()));

    return user;
  }

  Future<void> logout() async {
    final fcmToken = await _storage.getFcmToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      try {
        await unregisterDeviceToken(fcmToken);
      } catch (_) {}
      await _storage.deleteFcmToken();
    }

    try {
      await _client.dio.post(ApiEndpoints.logout);
    } catch (_) {}

    await _storage.clearAuth();
  }

  Future<UserModel> getMe() async {
    final response = await _client.dio.get(ApiEndpoints.me);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _storage.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _client.dio.post(
      ApiEndpoints.deviceTokens,
      data: {
        'token': token,
        'platform': platform,
      },
    );
    await _storage.saveFcmToken(token);
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _client.dio.delete('${ApiEndpoints.deviceTokens}/$token');
    await _storage.deleteFcmToken();
  }

  Future<UserModel?> getCachedUser() async {
    final userJson = await _storage.getUserJson();
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }
}
