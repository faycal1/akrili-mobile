import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository({required ApiClient client}) : _client = client;

  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    final response = await _client.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page},
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _client.dio.post(ApiEndpoints.readNotification(id));
    return NotificationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> markAllAsRead() async {
    await _client.dio.post(ApiEndpoints.readAllNotifications);
  }
}
