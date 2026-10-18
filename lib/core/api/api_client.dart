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

          // SAFE LOGGING: Never log Authorization header or secret keys
          developer.log(
            '--> ${options.method} ${options.uri}',
            name: 'ApiClient',
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '<-- ${response.statusCode} ${response.requestOptions.uri}',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          developer.log(
            '<-- ERROR ${error.response?.statusCode} ${error.requestOptions.uri}: ${error.message}',
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

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
