import 'api_service.dart';

class FavoritesService {
  static Future<List<dynamic>> getFavorites() async {
    final response = await ApiService.get('/favorites');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) return response['data'];
    return [];
  }

  static Future<void> addFavorite(int propertyId) async {
    await ApiService.post('/favorites', body: {'property_id': propertyId});
  }

  static Future<void> removeFavorite(int propertyId) async {
    await ApiService.delete('/favorites/$propertyId');
  }

  static Future<void> clearAll() async {
    await ApiService.delete('/favorites');
  }
}

