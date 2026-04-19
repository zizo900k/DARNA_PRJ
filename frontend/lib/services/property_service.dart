import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class PropertyService {
  static Future<Map<String, dynamic>> getProperties({Map<String, dynamic>? filters}) async {
    String queryParams = '';
    if (filters != null && filters.isNotEmpty) {
      queryParams = '?';
      filters.forEach((key, value) {
        if (value != null) {
          if (value is List) {
             for (var item in value) {
               queryParams += '${Uri.encodeComponent(key)}[]=${Uri.encodeComponent(item.toString())}&';
             }
          } else {
             queryParams += '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}&';
          }
        }
      });
      if (queryParams.endsWith('&')) {
        queryParams = queryParams.substring(0, queryParams.length - 1);
      }
    }

    final response = await ApiService.get('/properties$queryParams', requiresAuth: false);
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getProperty(int id) async {
    final response = await ApiService.get('/properties/$id', requiresAuth: false);
    return response as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getNearby(int id, {int limit = 5}) async {
    final response = await ApiService.get('/properties/nearby/$id?limit=$limit', requiresAuth: false);
    if (response is List) return response;
    return [];
  }

  static Future<Map<String, dynamic>> getCategories() async {
    final response = await ApiService.get('/categories', requiresAuth: false);
    return {'data': response};
  }
  
  static Future<Map<String, dynamic>> getLocations() async {
    final response = await ApiService.get('/locations', requiresAuth: false);
    return {'data': response};
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/stats', requiresAuth: false);
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProperty(Map<String, dynamic> data) async {
    final response = await ApiService.post('/properties', body: data);
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProperty(int id, Map<String, dynamic> data) async {
    final response = await ApiService.put('/properties/$id', body: data);
    return response as Map<String, dynamic>;
  }

  static Future<void> deleteProperty(int id) async {
    await ApiService.delete('/properties/$id');
  }

  static Future<Map<String, dynamic>> getTypes() async {
    final response = await ApiService.get('/properties/types', requiresAuth: false);
    return {'data': response};
  }

  static Future<Map<String, dynamic>> getStatuses() async {
    final response = await ApiService.get('/properties/statuses', requiresAuth: false);
    return {'data': response};
  }

  static Future<Map<String, dynamic>> uploadPhotos(int propertyId, List<XFile> images) async {
    final response = await ApiService.postMultipart(
      '/properties/$propertyId/photos',
      fileField: 'photos',
      files: images,
    );
    return response as Map<String, dynamic>;
  }

  static Future<void> deletePhoto(int propertyId, int photoId) async {
    await ApiService.delete('/properties/$propertyId/photos/$photoId');
  }
}

