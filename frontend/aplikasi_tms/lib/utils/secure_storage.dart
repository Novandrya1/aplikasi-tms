import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const String _key = 'tms_secure_key';
  
  static String _encrypt(String data) {
    final bytes = utf8.encode(data + _key);
    return base64.encode(bytes);
  }
  
  static String _decrypt(String encrypted) {
    try {
      final bytes = base64.decode(encrypted);
      final decoded = utf8.decode(bytes);
      return decoded.replaceAll(_key, '');
    } catch (e) {
      return '';
    }
  }
  
  static Future<void> store(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _encrypt(value));
  }
  
  static Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(key);
    return encrypted != null ? _decrypt(encrypted) : null;
  }
  
  static Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}