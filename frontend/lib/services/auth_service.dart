import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      '/login',
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    return await requestCode(fullName: fullName, email: email, password: password, phone: phone);
  }

  static Future<Map<String, dynamic>> requestCode({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await ApiService.post(
      '/register/request-code',
      body: {
        'name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null) 'phone': phone,
      },
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    final response = await ApiService.post(
      '/register/verify-code',
      body: {
        'email': email,
        'code': code,
      },
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    final response = await ApiService.post(
      '/register/resend-code',
      body: {
        'email': email,
      },
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiService.post(
      '/password/forgot',
      body: {'email': email},
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/password/reset',
      body: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      },
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/logout');
    } catch (e) {
      // Ignore errors on logout, just clear local token
    }
    try {
      await google_auth.GoogleSignIn.instance.signOut();
    } catch (_) {}
    await ApiService.removeToken();
  }

  static Future<Map<String, dynamic>> googleLogin() async {
    final google_auth.GoogleSignInAccount? googleUser = await google_auth.GoogleSignIn.instance.authenticate();
    
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled or failed.');
    }
    
    final google_auth.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    final idToken = googleAuth.idToken;
    
    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }
    
    final response = await ApiService.post(
      '/auth/google',
      body: {'id_token': idToken},
      requiresAuth: false,
    );
    
    return response as Map<String, dynamic>;
  }
}