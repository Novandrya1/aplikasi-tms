import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _webBaseUrl = ''; // Use relative URLs for proxy
  static const String _mobileBaseUrl = 'http://10.0.2.2:8080';
  
  static String get baseUrl {
    if (kIsWeb) {
      return _webBaseUrl;
    }
    return _mobileBaseUrl;
  }
  
  static String get healthUrl {
    if (kIsWeb) {
      return '/health'; // Nginx proxy
    }
    return 'http://10.0.2.2:8080/health';
  }
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}