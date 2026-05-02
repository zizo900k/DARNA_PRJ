import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AppNotification {
  final int id;
  final String? type;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    this.type,
    this.title,
    this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      data: json['data'] is String ? jsonDecode(json['data']) : json['data'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _userId;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/notifications');
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      _notifications = data.map((n) => AppNotification.fromJson(n)).toList();
      
      final countResponse = await ApiService.get('/notifications/unread-count');
      _unreadCount = countResponse['count'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.put('/notifications/$notificationId/read');
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          data: _notifications[index].data,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.put('/notifications/read-all');
      _notifications = _notifications.map((n) {
        if (n.isRead) return n;
        return AppNotification(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  void initWebSocket(String userId) {
    if (_userId == userId) return;
    _userId = userId;

    WebSocketService().subscribe('private-user.$userId', _onWebSocketEvent);
  }

  void _onWebSocketEvent(dynamic rawEvent) {
    // rawEvent is PusherEvent
    if (rawEvent.eventName == 'NotificationCreated') {
      try {
        final data = rawEvent.data is String ? jsonDecode(rawEvent.data) : rawEvent.data;
        if (data != null && data['notification'] != null) {
          final newNotification = AppNotification.fromJson(data['notification']);
          _notifications.insert(0, newNotification);
          _unreadCount++;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error parsing NotificationCreated event: $e');
      }
    }
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    if (_userId != null) {
      WebSocketService().unsubscribe('private-user.$_userId');
      _userId = null;
    }
    notifyListeners();
  }
}
