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
    final response = await ApiService.post(
      '/register',
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
    await google_auth.GoogleSignIn.instance.initialize(
      clientId: '498032892592-v3kgf2h9h0ton7c3572v0rkb4l6t0m38.apps.googleusercontent.com',
    );
    
    final google_auth.GoogleSignInAccount googleUser = await google_auth.GoogleSignIn.instance.authenticate();
    
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

