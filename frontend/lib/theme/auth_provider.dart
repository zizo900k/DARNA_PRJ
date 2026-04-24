import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = true; // Added for initial load state
  
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user != null ? Map.unmodifiable(_user!) : null;

  AuthProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      try {
        final response = await ProfileService.getProfile();
        _user = response['data'] ?? response;
        _isLoggedIn = true;
      } catch (e) {
        if (e is ApiException && e.statusCode == 401) {
          // Token is actually invalid or expired
          await ApiService.removeToken();
          _isLoggedIn = false;
          _user = null;
        } else {
          // Network error or server error (not 401)
          // Keep the user logged in but we might not have fresh profile data
          _isLoggedIn = true;
        }
      }
    } else {
      _isLoggedIn = false;
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await AuthService.login(email, password);
      
      final token = response['token'] ?? response['data']?['token'];
      final userData = response['user'] ?? response['data']?['user'];
      
      await ApiService.saveToken(token);
      _user = userData;
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String fullName, String email, String password, {String? phone}) async {
    try {
      await AuthService.requestCode(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      // Note: we do NOT log the user in yet or save token!
      // We simply finish the request, the UI must navigate to verify-email.
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      final response = await AuthService.verifyCode(email: email, code: code);
      
      final token = response['token'] ?? response['data']?['token'];
      final userData = response['user'] ?? response['data']?['user'];
      
      await ApiService.saveToken(token);
      _user = userData;
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendCode(String email) async {
    try {
      await AuthService.resendCode(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final response = await AuthService.googleLogin();
      
      final token = response['token'] ?? response['data']?['token'];
      final userData = response['user'] ?? response['data']?['user'];
      
      await ApiService.saveToken(token);
      _user = userData;
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> handleGoogleSignInResponse(Map<String, dynamic> response) async {
    final token = response['token'] ?? response['data']?['token'];
    final userData = response['user'] ?? response['data']?['user'];
    
    await ApiService.saveToken(token);
    _user = userData;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
    } catch (e) {
      // Ignore errors on logout
    }
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updates) {
    if (_user != null) {
      _user!.addAll(updates);
      notifyListeners();
    }
  }
}

