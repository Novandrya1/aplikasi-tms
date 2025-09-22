import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/fleet_models.dart';
import 'auth_service.dart';

class FleetService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    if (token != null) {
      return ApiConfig.authHeaders(token);
    }
    return ApiConfig.headers;
  }

  static Future<FleetOwner> registerFleetOwner(FleetOwnerRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/register'),
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return FleetOwner.fromJson(data['fleet_owner']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to register fleet owner');
    }
  }

  static Future<FleetOwner?> getFleetProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fleet/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FleetOwner.fromJson(data['fleet_owner']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> registerVehicle(dynamic vehicle) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/vehicles'),
      headers: await _getHeaders(),
      body: jsonEncode(vehicle is VehicleRegistration ? vehicle.toJson() : vehicle),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to register vehicle');
    }
  }

  static Future<List<Map<String, dynamic>>> getFleetVehicles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/vehicles'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['vehicles']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get fleet vehicles');
    }
  }
}