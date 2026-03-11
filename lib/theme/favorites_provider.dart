import 'package:flutter/material.dart';

class FavoritesProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _favorites = [];

  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(int id) => _favorites.any((item) => item['id'] == id);

  void addFavorite(Map<String, dynamic> property) {
    if (!isFavorite(property['id'] as int)) {
      _favorites.add(Map<String, dynamic>.from(property));
      notifyListeners();
    }
  }

  void removeFavorite(int id) {
    _favorites.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void toggleFavorite(Map<String, dynamic> property) {
    final id = property['id'] as int;
    if (isFavorite(id)) {
      removeFavorite(id);
    } else {
      addFavorite(property);
    }
  }

  void clearAll() {
    _favorites.clear();
    notifyListeners();
  }
}
