import 'api_service.dart';

class NotificationService {
  /// Get all notifications for the authenticated user.
  static Future<List<dynamic>> getNotifications() async {
    final response = await ApiService.get('/notifications');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) return response['data'] as List;
    return [];
  }

  /// Mark a single notification as read.
  static Future<void> markAsRead(int notificationId) async {
    await ApiService.put('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read.
  static Future<void> markAllAsRead() async {
    await ApiService.put('/notifications/read-all');
  }

  /// Delete a notification.
  static Future<void> deleteNotification(int notificationId) async {
    await ApiService.delete('/notifications/$notificationId');
  }
}
