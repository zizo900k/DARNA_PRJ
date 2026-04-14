import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  int _unreadCount = 0;

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
}
