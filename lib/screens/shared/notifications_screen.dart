import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                await ref.read(notificationRepositoryProvider).markAllAsRead();
                ref.invalidate(notificationsListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not mark all as read: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all read'),
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
                Text('Failed to load notifications', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(notificationsListProvider),
                  child: const Text('Retry'),
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
                    const Text(
                      'No notifications yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You will receive instant push notifications and alerts for your booking updates and messages.',
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
    if (type.contains('Accepted')) return Icons.check_circle_rounded;
    if (type.contains('Rejected')) return Icons.cancel_rounded;
    if (type.contains('Requested')) return Icons.calendar_month_rounded;
    if (type.contains('Message')) return Icons.chat_bubble_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () async {
        // Mark as read if not already read
        if (isUnread) {
          try {
            await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
            ref.invalidate(notificationsListProvider);
          } catch (_) {}
        }

        // Deep linking resolution
        final linkType = notification.deepLinkType;
        final linkId = notification.deepLinkId;

        if (linkType == 'booking' && linkId != null) {
          if (context.mounted) {
            context.push('/bookings/$linkId');
          }
        } else if (linkType == 'conversation' && linkId != null) {
          if (context.mounted) {
            context.push('/conversations/$linkId');
          }
        }
      },
      child: Container(
        color: isUnread ? AppTheme.primary.withOpacity(0.04) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconBgColor(notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconData(notification.type),
                size: 20,
                color: _iconColor(notification.type),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: isUnread ? Colors.black87 : Colors.grey[700],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (notification.createdAt != null)
                    Text(
                      DateFormat('MMM d, h:mm a').format(notification.createdAt!),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
