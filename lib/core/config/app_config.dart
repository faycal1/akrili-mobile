import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String appName = 'Akrili';

  // Environments
  static const String stagingBaseUrl = 'https://akrili.fawatirs.com';
  static const String localEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String localDesktopBaseUrl = 'http://127.0.0.1:8000';

  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    const env = String.fromEnvironment('ENV');
    if (env == 'staging' || env == 'prod' || env == 'production') {
      return stagingBaseUrl;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return localEmulatorBaseUrl;
    }
    return localDesktopBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
