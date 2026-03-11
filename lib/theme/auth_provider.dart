import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;

  final Map<String, dynamic> _user = {
    'name': 'Mohamed Ez-zidany',
    'email': 'zidanim@gmail.com',
    'avatar': 'https://i.pravatar.cc/150?img=60',
    'phone': '+212 624424544',
  };

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic> get user => Map.unmodifiable(_user);

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updates) {
    _user.addAll(updates);
    notifyListeners();
  }
}
