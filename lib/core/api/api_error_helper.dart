import 'package:dio/dio.dart';
import '../localization/app_localizations.dart';

class ApiErrorHelper {
  /// Extracts a human-friendly error message from any exception or API response.
  static String parse(dynamic error, [AppLocalizations? tr]) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return tr?.connectionTimeoutMsg ??
            'Délai de connexion dépassé. Vérifiez votre réseau ou le serveur.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return tr?.cannotConnectMsg ??
            'Impossible de joindre le serveur. Vérifiez les paramètres de connexion.';
      }

      final response = error.response;
      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // Laravel validation errors object: {"message": "...", "errors": {"field": ["msg"]}}
          if (data.containsKey('errors') && data['errors'] is Map) {
            final errorsMap = data['errors'] as Map;
            if (errorsMap.isNotEmpty) {
              final firstValue = errorsMap.values.first;
              if (firstValue is List && firstValue.isNotEmpty) {
                return firstValue.first.toString();
              } else if (firstValue is String) {
                return firstValue;
              }
            }
          }

          if (data.containsKey('message') &&
              data['message'] is String &&
              (data['message'] as String).trim().isNotEmpty) {
            return data['message'] as String;
          }
        }
      }

      final statusCode = response?.statusCode;
      if (statusCode == 401) {
        return tr?.invalidCredentialsMsg ?? 'Non autorisé. Veuillez vous reconnecter.';
      }
      if (statusCode == 403) {
        return tr?.cannotBookOwnProperty ?? 'Action non autorisée sur cette annonce.';
      }
      if (statusCode == 422) {
        return tr?.checkBookingInfoMsg ?? 'Veuillez vérifier les informations de réservation.';
      }
      if (statusCode == 429) {
        return tr?.tooManyAttemptsMsg ?? 'Trop de requêtes. Veuillez patienter un instant.';
      }
      if (statusCode == 500) {
        return tr?.serverErrorMsg ?? 'Erreur serveur. Veuillez réessayer ultérieurement.';
      }

      final rawMessage = error.message;
      if (rawMessage != null &&
          rawMessage.isNotEmpty &&
          !rawMessage.contains('status code of') &&
          !rawMessage.contains('bad response')) {
        return rawMessage;
      }

      return tr?.serverErrorMsg ?? 'Une erreur est survenue lors de la communication avec le serveur.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
