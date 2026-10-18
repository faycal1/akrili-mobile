import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(client: client);
});

final notificationsListProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) {
    return const [];
  }
  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) {
    return 0;
  }
  final asyncNotifications = ref.watch(notificationsListProvider);
  return asyncNotifications.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
