import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavorite(int id) => _favorites.any((item) => item['id'] == id || (item['property'] != null && item['property']['id'] == id));

  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await FavoritesService.getFavorites();
      _favorites = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFavorite(Map<String, dynamic> property) async {
    final propertyId = property['id'] as int;
    if (!isFavorite(propertyId)) {
      // Optimistic update
      _favorites.add({'property': property});
      notifyListeners();

      try {
        await FavoritesService.addFavorite(propertyId);
      } catch (e) {
        // Revert on failure
        _favorites.removeWhere((item) => item['property'] != null && item['property']['id'] == propertyId);
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> removeFavorite(int id) async {
    // Optimistic update
    final index = _favorites.indexWhere((item) => item['id'] == id || (item['property'] != null && item['property']['id'] == id));
    if (index != -1) {
      final removedItem = _favorites[index];
      _favorites.removeAt(index);
      notifyListeners();

      try {
        await FavoritesService.removeFavorite(id);
      } catch (e) {
        // Revert on failure
        _favorites.insert(index, removedItem);
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> property) async {
    final id = property['id'] as int;
    if (isFavorite(id)) {
      await removeFavorite(id);
    } else {
      await addFavorite(property);
    }
  }

  Future<void> clearAll() async {
    // Optimistic update
    final oldFavorites = List<Map<String, dynamic>>.from(_favorites);
    _favorites.clear();
    notifyListeners();

    try {
      await FavoritesService.clearAll();
    } catch (e) {
      // Revert on failure
      _favorites = oldFavorites;
      _error = e.toString();
      notifyListeners();
    }
  }
}

