import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final SecureStorageService _storage;
  late final Dio dio;
  void Function()? onUnauthorized;

  ApiClient({
    required SecureStorageService storage,
    String? baseUrl,
    this.onUnauthorized,
  }) : _storage = storage {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.defaultBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // SAFE LOGGING: Never log Authorization header or raw device tokens
          final safeUri = _sanitizeUri(options.uri);
          developer.log(
            '--> ${options.method} $safeUri',
            name: 'ApiClient',
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          final safeUri = _sanitizeUri(response.requestOptions.uri);
          developer.log(
            '<-- ${response.statusCode} $safeUri',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final safeUri = _sanitizeUri(error.requestOptions.uri);
          developer.log(
            '<-- ERROR ${error.response?.statusCode} $safeUri: ${error.message}',
            name: 'ApiClient',
          );

          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }

          return handler.next(error);
        },
      ),
    );
  }

  static String _sanitizeUri(Uri uri) {
    var path = uri.path;
    if (path.contains('/device-tokens/')) {
      path = path.replaceFirst(RegExp(r'/device-tokens/.*'), '/device-tokens/[TOKEN]');
    }
    return uri.replace(path: path).toString();
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
