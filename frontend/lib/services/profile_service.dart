import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.get('/profile');
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('/profile', body: data);
    return response as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getListings() async {
    final response = await ApiService.get('/profile/listings');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) return response['data'];
    return [];
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/profile/stats');
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadAvatar(XFile image) async {
    final response = await ApiService.postMultipartSingle(
      '/profile', 
      fileField: 'avatar_file',
      file: image,
      fields: {'_method': 'PUT'},
    );
    return response as Map<String, dynamic>;
  }
}
