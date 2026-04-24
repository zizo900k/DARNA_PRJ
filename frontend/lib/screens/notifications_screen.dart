import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case 'new_message':
      case 'new_voice_message':
      case 'missed_call':
        if (data['conversation_id'] != null) {
          context.push('/chat/${data['conversation_id']}');
        }
        break;
      case 'new_request':
      case 'request_accepted':
      case 'request_rejected':
        if (data['property_id'] != null) {
          // Could also go to /requests if we want
          context.push('/property/${data['property_id']}');
        } else {
          context.push('/requests');
        }
        break;
      case 'new_review':
        if (data['property_id'] != null) {
          context.push('/property/${data['property_id']}');
        }
        break;
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'new_voice_message':
        return Icons.mic_none;
      case 'missed_call':
        return Icons.phone_missed;
      case 'new_request':
        return Icons.calendar_today_outlined;
      case 'request_accepted':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'new_review':
        return Icons.star_border;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('notifications') ?? 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('no_notifications') ?? 'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return Material(
                color: notification.isRead 
                    ? Colors.transparent 
                    : (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.05)),
                child: InkWell(
                  onTap: () => _handleNotificationTap(notification),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? DarkColors.card : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: notification.isRead 
                                  ? theme.dividerColor.withValues(alpha: 0.2) 
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            _getIconForType(notification.type),
                            color: notification.isRead ? theme.iconTheme.color : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeago.format(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
