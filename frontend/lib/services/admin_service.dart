import 'api_service.dart';

class AdminService {
  /// Get all properties for admin (with optional status filter)
  static Future<Map<String, dynamic>> getProperties({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '/admin/properties?page=$page&limit=$limit';
    if (status != null && status != 'all') {
      endpoint += '&status=$status';
    }
    final response = await ApiService.get(endpoint);
    return response as Map<String, dynamic>;
  }

  /// Get admin stats (pending / published / rejected counts)
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/admin/properties/stats');
    return response as Map<String, dynamic>;
  }

  /// Get single property detail for admin
  static Future<Map<String, dynamic>> getProperty(int id) async {
    final response = await ApiService.get('/admin/properties/$id');
    return response as Map<String, dynamic>;
  }

  /// Approve a property
  static Future<Map<String, dynamic>> approve(int id) async {
    final response = await ApiService.put('/admin/properties/$id/approve');
    return response as Map<String, dynamic>;
  }

  /// Reject a property with a reason
  static Future<Map<String, dynamic>> reject(int id, String reason) async {
    final response = await ApiService.put(
      '/admin/properties/$id/reject',
      body: {'rejection_reason': reason},
    );
    return response as Map<String, dynamic>;
  }
}
