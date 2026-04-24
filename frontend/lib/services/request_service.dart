import 'api_service.dart';

class RequestService {
  /// Create a new property request
  static Future<Map<String, dynamic>> createRequest(
      int propertyId, Map<String, dynamic> data) async {
    final response = await ApiService.post('/properties/$propertyId/requests', body: data);
    return response;
  }

  /// Get user requests (sent and received)
  static Future<Map<String, dynamic>> getRequests() async {
    final response = await ApiService.get('/requests');
    return response;
  }

  /// Update request status (owner only)
  static Future<Map<String, dynamic>> updateStatus(
      int requestId, String status) async {
    final response = await ApiService.put('/requests/$requestId/status', body: {
      'status': status,
    });
    return response;
  }
}
