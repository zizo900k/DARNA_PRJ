import 'package:image_picker/image_picker.dart';
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

  /// send audio message
  static Future<Map<String, dynamic>> sendAudioMessage({
    required int conversationId,
    required String audioPath,
    int? durationMs,
  }) async {
    final fields = <String, String>{};
    if (durationMs != null) fields['duration'] = durationMs.toString();

    // ApiService utility expects XFile
    final xFile = XFile(audioPath);
    
    final response = await ApiService.postMultipartSingle(
      '/conversations/$conversationId/audio',
      fileField: 'audio',
      file: xFile,
      fields: fields,
    );
    return Map<String, dynamic>.from(response);
  }

  /// Mark all messages as read.
  static Future<void> markAsRead(int conversationId) async {
    await ApiService.put('/conversations/$conversationId/read');
  }

  /// Mark all messages as delivered.
  static Future<void> markDelivered(int conversationId) async {
    await ApiService.put('/conversations/$conversationId/delivered');
  }

  /// Get total unread count.
  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/conversations/unread-count');
    if (response is Map) return response['unread_count'] ?? 0;
    return 0;
  }

  /// Ping server to update online presence.
  static Future<void> ping() async {
    try {
      await ApiService.post('/users/ping');
    } catch (_) {}
  }

  /// Get a user's online status.
  static Future<Map<String, dynamic>> getUserStatus(int userId) async {
    final response = await ApiService.get('/users/$userId/status');
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'is_online': false, 'last_seen_at': null};
  }

  /// Delete a message for the current user only.
  static Future<void> deleteMessageForMe(int conversationId, int messageId) async {
    await ApiService.delete('/conversations/$conversationId/messages/$messageId/for-me');
  }

  /// Delete a message for everyone.
  static Future<void> deleteMessageForEveryone(int conversationId, int messageId) async {
    await ApiService.delete('/conversations/$conversationId/messages/$messageId/for-everyone');
  }
}
