import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import 'call_provider.dart';

class ChatProvider with ChangeNotifier {
  int _unreadCount = 0;
  int? _currentUserId;
  Timer? _pingTimer;

  int get unreadCount => _unreadCount;

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await ChatService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      // Silently fail — user might not be logged in
      debugPrint('ChatProvider: $e');
    }
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  void decrementBy(int count) {
    _unreadCount = (_unreadCount - count).clamp(0, 99999);
    notifyListeners();
  }

  Future<void> initRealTime(int userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    await WebSocketService().init();
    await WebSocketService().subscribe('private-user.$userId', _onUserEvent);

    // Start periodic ping for online presence
    _pingTimer?.cancel();
    ChatService.ping(); // Immediate first ping
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ChatService.ping();
    });
  }

  void _onUserEvent(dynamic event) {
    // When a conversation is updated (new message received)
    fetchUnreadCount();

    try {
      final payloadStr = event is Map ? (event['data'] ?? '{}') : event.data;
      final payload = payloadStr is String ? json.decode(payloadStr) : payloadStr;
      
      final eventName = event is Map ? event['eventName'] : event.eventName;
      if (eventName == 'call.signal' || eventName == r'App\Events\CallSignal') {
         CallProvider.instance.handleSignal(payload);
         return; // Don't process as a normal message
      }

      if (payload['conversation_id'] != null) {
        ChatService.markDelivered(payload['conversation_id']).catchError((_) {});
      }
    } catch (_) {}

    notifyListeners();
  }

  void stopRealTime() {
    _pingTimer?.cancel();
    _pingTimer = null;
    if (_currentUserId != null) {
      WebSocketService().unsubscribe('private-user.$_currentUserId');
    }
    _currentUserId = null;
    WebSocketService().disconnect();
  }
}
