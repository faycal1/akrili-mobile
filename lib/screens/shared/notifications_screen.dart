import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final authUser = ref.watch(authNotifierProvider).valueOrNull;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr.notificationsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 36, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(tr.signInForNotifications, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  tr.notificationsSignInPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(tr.signIn),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(tr.createAccount),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.notificationsTitle),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                await ref.read(notificationRepositoryProvider).markAllAsRead();
                ref.invalidate(notificationsListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: Text(tr.markAllAsRead),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.secondary),
                const SizedBox(height: 12),
                Text('Impossible de charger les notifications', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(notificationsListProvider),
                  child: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 52,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr.noNotificationsYet,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vous recevrez des notifications push et des alertes sur vos réservations et vos messages.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(notificationsListProvider);
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  Color _iconBgColor(String type) {
    if (type.contains('Accepted')) return const Color(0xFF10B981).withOpacity(0.12);
    if (type.contains('Rejected')) return AppTheme.secondary.withOpacity(0.12);
    if (type.contains('Requested')) return const Color(0xFFF59E0B).withOpacity(0.12);
    if (type.contains('Message')) return AppTheme.primary.withOpacity(0.12);
    return Colors.blue.withOpacity(0.12);
  }

  Color _iconColor(String type) {
    if (type.contains('Accepted')) return const Color(0xFF10B981);
    if (type.contains('Rejected')) return AppTheme.secondary;
    if (type.contains('Requested')) return const Color(0xFFF59E0B);
    if (type.contains('Message')) return AppTheme.primary;
    return Colors.blue;
  }

  IconData _iconData(String type) {
    if (type.contains('Accepted')) return Icons.check_circle_outline_rounded;
    if (type.contains('Rejected')) return Icons.highlight_off_rounded;
    if (type.contains('Requested')) return Icons.pending_actions_rounded;
    if (type.contains('Message')) return Icons.chat_bubble_outline_rounded;
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;
    final color = _iconColor(notification.type);
    final bgColor = _iconBgColor(notification.type);

    return ListTile(
      tileColor: isUnread ? AppTheme.primary.withOpacity(0.05) : null,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(_iconData(notification.type), color: color, size: 22),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 13,
              color: isUnread ? Colors.black87 : Colors.grey[600],
            ),
          ),
          if (notification.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt!),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () async {
        if (isUnread) {
          try {
            await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
            ref.invalidate(notificationsListProvider);
          } catch (_) {}
        }

        if (context.mounted) {
          final deepId = notification.deepLinkId;
          if (deepId != null && notification.deepLinkType == 'booking') {
            context.push('/bookings/$deepId');
          }
        }
      },
    );
  }
}
