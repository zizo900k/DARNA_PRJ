import 'api_service.dart';

class ReviewService {
  static Future<Map<String, dynamic>> getReviews(int propertyId) async {
    final response = await ApiService.get('/properties/$propertyId/reviews', requiresAuth: false);
    return {'data': response};
  }

  static Future<Map<String, dynamic>> addReview(int propertyId, Map<String, dynamic> data) async {
    final body = Map<String, dynamic>.from(data);
    body['property_id'] = propertyId;
    final response = await ApiService.post('/reviews', body: body);
    return response as Map<String, dynamic>;
  }
}

