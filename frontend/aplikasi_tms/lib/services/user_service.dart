import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class UserService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<bool> hasVehicles() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['vehicles'] as List).isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasGPSDevices() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/gps-devices'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['devices'] as List).isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isNewUser() async {
    final hasVehicle = await hasVehicles();
    final hasGPS = await hasGPSDevices();
    return !hasVehicle && !hasGPS;
  }
}