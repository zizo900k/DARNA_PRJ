import 'api_service.dart';

class ChatService {
  /// Get all conversations for the logged-in user.
  static Future<List<dynamic>> getConversations() async {
    final response = await ApiService.get('/conversations');
    if (response is List) return response;
    return [];
  }

  /// Create or get existing conversation.
  static Future<Map<String, dynamic>> getOrCreateConversation({
    required int user2Id,
    int? propertyId,
  }) async {
    final body = <String, dynamic>{
      'user2_id': user2Id,
    };
    if (propertyId != null) body['property_id'] = propertyId;
    final response = await ApiService.post('/conversations', body: body);
    return Map<String, dynamic>.from(response);
  }

  /// Get messages for a conversation.
  static Future<List<dynamic>> getMessages(int conversationId) async {
    final response = await ApiService.get('/conversations/$conversationId/messages');
    if (response is List) return response;
    return [];
  }

  /// Send a message.
  static Future<Map<String, dynamic>> sendMessage(int conversationId, String message) async {
    final response = await ApiService.post(
      '/conversations/$conversationId/messages',
      body: {'message': message},
    );
    return Map<String, dynamic>.from(response);
  }

  /// Mark all messages as read.
  static Future<void> markAsRead(int conversationId) async {
    await ApiService.put('/conversations/$conversationId/read');
  }

  /// Get total unread count.
  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/conversations/unread-count');
    if (response is Map) return response['unread_count'] ?? 0;
    return 0;
  }
}
