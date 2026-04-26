import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../theme/language_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsScreen(),
    );
  }

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

    // Pop the bottom sheet before navigating
    Navigator.of(context).pop();

    switch (notification.type) {
      case 'new_message':
      case 'new_voice_message':
      case 'missed_call':
        if (data['conversation_id'] != null) {
          final extra = <String, dynamic>{};
          if (data['sender'] != null) {
            extra['otherUser'] = data['sender'];
          }
          context.push('/chat/${data['conversation_id']}', extra: extra);
        }
        break;
      case 'new_request':
        context.push('/requests');
        break;
      case 'request_accepted':
      case 'request_rejected':
        if (data['property_id'] != null) {
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
        return Icons.chat_bubble_rounded;
      case 'new_voice_message':
        return Icons.mic_rounded;
      case 'missed_call':
        return Icons.phone_missed_rounded;
      case 'new_request':
        return Icons.calendar_month_rounded;
      case 'request_accepted':
        return Icons.check_circle_rounded;
      case 'request_rejected':
        return Icons.cancel_rounded;
      case 'new_review':
        return Icons.star_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
  
  Color _getColorForType(String? type) {
    switch (type) {
      case 'new_message':
      case 'new_voice_message':
        return const Color(0xFF3B82F6); // Blue
      case 'missed_call':
        return const Color(0xFFEF4444); // Red
      case 'new_request':
        return const Color(0xFFF59E0B); // Amber
      case 'request_accepted':
        return const Color(0xFF10B981); // Green
      case 'request_rejected':
        return const Color(0xFFEF4444); // Red
      case 'new_review':
        return const Color(0xFFF59E0B); // Amber
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.background : LightColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('notifications') ?? 'Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.done_all_rounded, color: AppColors.primary),
                      tooltip: 'Mark all as read',
                      onPressed: () {
                        context.read<NotificationProvider>().markAllAsRead();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? DarkColors.divider : LightColors.divider),
              // Content
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    if (provider.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 64,
                                color: AppColors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              context.tr('no_notifications') ?? 'No notifications yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'When you get notifications, they\'ll show up here',
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = provider.notifications[index];
                        final data = notification.data;
                        final sender = data?['sender'];
                        String? avatarUrl = sender?['full_avatar_url'] ?? sender?['avatar'];
                        
                        if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
                          final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
                          avatarUrl = '$baseUrl/proxy/storage/' + avatarUrl.replaceFirst('/', '');
                        }
                        
                        final typeColor = _getColorForType(notification.type);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? DarkColors.card : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: !notification.isRead 
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : (isDark ? DarkColors.divider : LightColors.divider),
                              width: !notification.isRead ? 1.5 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _handleNotificationTap(notification),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon / Avatar
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(28),
                                                  child: CachedNetworkImage(
                                                    imageUrl: avatarUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) => Icon(
                                                      _getIconForType(notification.type),
                                                      color: typeColor,
                                                      size: 28,
                                                    ),
                                                  ),
                                                )
                                              : Icon(
                                                  _getIconForType(notification.type),
                                                  color: typeColor,
                                                  size: 28,
                                                ),
                                        ),
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: typeColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark ? DarkColors.card : Colors.white,
                                                width: 2.5,
                                              ),
                                            ),
                                            child: Icon(
                                              _getIconForType(notification.type),
                                              color: Colors.white,
                                              size: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                                    color: theme.textTheme.bodyLarge?.color,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                              ),
                                              if (!notification.isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8, top: 4),
                                                  width: 10,
                                                  height: 10,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors.primary,
                                                        blurRadius: 6,
                                                        spreadRadius: -2,
                                                      )
                                                    ]
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notification.body ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: notification.isRead ? 0.7 : 0.9),
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeago.format(notification.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
