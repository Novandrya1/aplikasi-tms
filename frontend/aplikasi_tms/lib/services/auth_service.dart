import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static Future<LoginResponse> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      
      final response = await http.post(
        Uri.parse('${baseUrl}/api/v1/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          final loginResponse = LoginResponse.fromJson(jsonData);
          final prefs = await SharedPreferences.getInstance();
          
          await prefs.setString('token', loginResponse.token);
          await prefs.setString('user', jsonEncode(loginResponse.user.toJson()));
          
          return loginResponse;
        } catch (e) {
          print('JSON decode error: $e');
          throw Exception('Invalid response format from server');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Login failed');
        } catch (e) {
          throw Exception('Login failed with status ${response.statusCode}');
        }
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your connection.');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Server response format error. Please check connection.');
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // For development, always show login first
      if (token == null || token.isEmpty) {
        return false;
      }
      
      // Validate token with backend
      try {
        final response = await http.get(
          Uri.parse('${baseUrl}/api/v1/ping'),
          headers: authHeaders(token),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          return true;
        } else {
          await logout();
          return false;
        }
      } on http.ClientException catch (e) {
        print('Network error during token validation: $e');
        return false; // Don't logout on network errors
      } catch (e) {
        print('Token validation error: $e');
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        return User.fromJson(jsonDecode(userString));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
  }

  static Future<LoginResponse> register(
    String username,
    String email,
    String password,
    String fullName,
  ) async {
    final request = RegisterRequest(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
    );
    
    print('Register URL: $baseUrl/register');
    print('Register payload: ${jsonEncode(request.toJson())}');
    
    final response = await http.post(
      Uri.parse('${baseUrl}/api/v1/register'),
      headers: ApiConfig.headers,
      body: jsonEncode(request.toJson()),
    );
    
    print('Register response status: ${response.statusCode}');
    print('Register response body: ${response.body}');

    if (response.statusCode == 201) {
      final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('token', loginResponse.token);
      await prefs.setString('user', jsonEncode(loginResponse.user.toJson()));
      
      return loginResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } catch (e) {
      print('Logout error: $e');
    }
  }
}