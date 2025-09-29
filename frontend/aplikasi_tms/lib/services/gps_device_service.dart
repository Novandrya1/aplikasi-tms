import 'dart:convert';
import 'package:http/http.dart' as http;

class GPSDeviceService {
  static const String baseUrl = '/api/v1';

  static Future<List<Map<String, dynamic>>> getAllDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/gps-devices'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['devices'] ?? []);
    } else {
      throw Exception('Failed to get GPS devices');
    }
  }

  static Future<void> assignDevice(String deviceId, int vehicleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gps-devices/assign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'vehicle_id': vehicleId,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to assign device');
    }
  }

  static Future<void> updateDeviceStatus(String deviceId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/gps-devices/$deviceId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update status');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableVehicles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles?status=approved'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
    } else {
      throw Exception('Failed to get vehicles');
    }
  }
}