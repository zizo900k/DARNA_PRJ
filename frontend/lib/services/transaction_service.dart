import 'api_service.dart';

class TransactionService {
  /// ---------- SALES ----------

  /// Get all sales (as buyer or seller)
  static Future<List<dynamic>> getSales() async {
    final response = await ApiService.get('/sales');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) return response['data'] as List;
    return [];
  }

  /// Initiate a property sale
  static Future<Map<String, dynamic>> initiateSale(int propertyId) async {
    final response = await ApiService.post('/sales', body: {
      'property_id': propertyId,
    });
    return response as Map<String, dynamic>;
  }

  /// Update sale status (owner only)
  static Future<Map<String, dynamic>> updateSaleStatus(int saleId, String status) async {
    final response = await ApiService.put('/sales/$saleId', body: {
      'status': status,
    });
    return response as Map<String, dynamic>;
  }

  /// ---------- RENTS ----------

  /// Get all rents (as tenant or owner)
  static Future<List<dynamic>> getRents() async {
    final response = await ApiService.get('/rents');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) return response['data'] as List;
    return [];
  }

  /// Initiate a property rent
  static Future<Map<String, dynamic>> initiateRent(int propertyId, String startDate, int months) async {
    final response = await ApiService.post('/rents', body: {
      'property_id': propertyId,
      'start_date': startDate,
      'number_of_months': months,
    });
    return response as Map<String, dynamic>;
  }

  /// Update rent status (owner only)
  static Future<Map<String, dynamic>> updateRentStatus(int rentId, String status) async {
    final response = await ApiService.put('/rents/$rentId', body: {
      'status': status,
    });
    return response as Map<String, dynamic>;
  }
}
