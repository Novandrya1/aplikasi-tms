import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class AdminService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stats'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get dashboard stats');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingVehicles() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/admin/vehicles/pending'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get pending vehicles');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllVehicles() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/admin/vehicles'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get vehicles');
    }
  }

  static Future<Map<String, dynamic>> getVehicleDetails(int vehicleId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/admin/vehicles/$vehicleId'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['vehicle'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get vehicle details');
    }
  }

  static Future<void> verifyVehicle(int vehicleId, String status, {String? notes}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.put(
      Uri.parse('$baseUrl/admin/vehicles/$vehicleId/verify'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({
        'status': status,
        'notes': notes ?? '',
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to verify vehicle');
    }
  }

  static Future<List<Map<String, dynamic>>> getVehicleAttachments(int vehicleId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/$vehicleId/attachments'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['attachments'] ?? []);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get vehicle attachments');
    }
  }
}