import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all categories from the backend
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/categories');
      if (response is List) {
        _categories = List<Map<String, dynamic>>.from(response);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create a new category (admin)
  Future<Map<String, dynamic>> createCategory(String name, {String? slug}) async {
    final body = {'name': name};
    if (slug != null && slug.isNotEmpty) body['slug'] = slug;
    
    final response = await ApiService.post('/categories', body: body);
    final result = response as Map<String, dynamic>;
    await fetchCategories(); // Refresh list
    return result;
  }

  /// Update a category (admin)
  Future<Map<String, dynamic>> updateCategory(int id, String name, {String? slug}) async {
    final body = {'name': name};
    if (slug != null && slug.isNotEmpty) body['slug'] = slug;

    final response = await ApiService.put('/categories/$id', body: body);
    final result = response as Map<String, dynamic>;
    await fetchCategories(); // Refresh list
    return result;
  }

  /// Delete a category (admin)
  Future<Map<String, dynamic>> deleteCategory(int id) async {
    final response = await ApiService.delete('/categories/$id');
    final result = response as Map<String, dynamic>;
    await fetchCategories(); // Refresh list
    return result;
  }
}
