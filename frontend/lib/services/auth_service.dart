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
    await ApiService.removeToken();
  }

  static Future<Map<String, dynamic>> socialLogin(String provider, String token, String email, String fullName, [String? avatar]) async {
    final response = await ApiService.post(
      '/auth/social',
      body: {
        'provider': provider,
        'provider_id': token, // Simplified for this implementation
        'email': email,
        'full_name': fullName,
        if (avatar != null) 'avatar': avatar,
      },
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  static Future<void> forgotPassword(String email) async {
    await ApiService.post(
      '/auth/forgot-password',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  static Future<void> resetPassword(String email, String token, String password, String passwordConfirmation) async {
    await ApiService.post(
      '/auth/reset-password',
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      requiresAuth: false,
    );
  }
}

