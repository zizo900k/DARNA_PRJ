import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator, or your local IP for physical devices.
  // LOCAL DEV: 10.32.92.245:8888 | PRODUCTION: 68.221.171.205
  static const String baseUrl = 'http://127.0.0.1:8888/api';
  
  static const String _tokenKey = 'auth_token';

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Headers builder
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic request handler
  static Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return json.decode(response.body);
      } catch (_) {
        return response.body; 
      }
    } else {
      // Decode error if possible
      try {
        final error = json.decode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          message: error['message'] ?? 'An error occurred',
          data: error['errors'] ?? error['data'],
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Server error: ${response.statusCode}',
        );
      }
    }
  }

  // GET
  static Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // POST
  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return await _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // POST Multipart (for file uploads)
  // Each file is sent as fieldName[] so Laravel receives it as an array (photos.*)
  static Future<dynamic> postMultipart(String endpoint, {required String fileField, required List<XFile> files, Map<String, String>? fields, bool requiresAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      if (requiresAuth) {
        final token = await getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Use array notation so Laravel validates as photos.*
      final arrayFieldName = '$fileField[]';
      for (var file in files) {
        if (kIsWeb) {
           final bytes = await file.readAsBytes();
           request.files.add(http.MultipartFile.fromBytes(arrayFieldName, bytes, filename: file.name));
        } else {
           request.files.add(await http.MultipartFile.fromPath(arrayFieldName, file.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return await _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // POST Multipart for a Single File
  static Future<dynamic> postMultipartSingle(String endpoint, {required String fileField, required XFile file, Map<String, String>? fields, bool requiresAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      if (requiresAuth) {
        final token = await getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (kIsWeb) {
         final bytes = await file.readAsBytes();
         String fileName = file.name;
         if (!fileName.contains('.')) {
           fileName = '$fileName.webm';
         }
         request.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: fileName));
      } else {
         request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return await _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // PUT
  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return await _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // DELETE
  static Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
      return await _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  static Exception _handleException(dynamic e) {
    if (e is ApiException) return e;
    return Exception('Network error: $e');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    if (data != null && data is Map) {
      // Extract the first error message from the validation errors
      final firstErrorKey = (data as Map).keys.first;
      final firstErrorMsg = (data as Map)[firstErrorKey][0];
      return firstErrorMsg;
    }
    return message;
  }
}

