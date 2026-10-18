import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  static String activeBaseUrl = AppConfig.defaultBaseUrl;

  final SecureStorageService _storage;
  late final Dio dio;
  void Function()? onUnauthorized;

  ApiClient({
    required SecureStorageService storage,
    String? baseUrl,
    this.onUnauthorized,
  }) : _storage = storage {
    activeBaseUrl = baseUrl ?? AppConfig.defaultBaseUrl;
    dio = Dio(
      BaseOptions(
        baseUrl: activeBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Accept-Language': 'fr',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final locale = await _storage.getLocale() ?? 'fr';
          options.headers['Accept-Language'] = locale;

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

          final path = error.requestOptions.uri.path;
          final authHeader = error.requestOptions.headers['Authorization']?.toString();
          final hasAuthHeader = authHeader != null && authHeader.isNotEmpty;
          final isAuthEndpoint = path.contains('/auth/login') || path.contains('/auth/register');

          if (error.response?.statusCode == 401 && hasAuthHeader && !isAuthEndpoint) {
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
    var cleaned = newUrl.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    activeBaseUrl = cleaned;
    dio.options.baseUrl = cleaned;
  }

  static String? resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    final baseUri = Uri.tryParse(activeBaseUrl);
    if (baseUri == null) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    // Relative path (/storage/media/...)
    if (!uri.hasScheme) {
      return baseUri.resolve(trimmed).toString();
    }

    final host = uri.host.toLowerCase();

    // If host is staging and scheme is http, upgrade to https
    if (host == 'akrili.fawatirs.com' && uri.scheme == 'http') {
      return uri.replace(scheme: 'https').toString();
    }

    // Remap local/dev hosts (akrili.test, *.test, *.local, localhost, 127.0.0.1, 0.0.0.0) to active Base URL
    if (host == 'akrili.test' ||
        host.endsWith('.test') ||
        host.endsWith('.local') ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0') {
      return Uri(
        scheme: baseUri.scheme,
        userInfo: uri.userInfo.isNotEmpty ? uri.userInfo : null,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: uri.path,
        query: uri.hasQuery ? uri.query : null,
        fragment: uri.hasFragment ? uri.fragment : null,
      ).toString();
    }

    return trimmed;
  }
}
