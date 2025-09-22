import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class VehicleService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> registerVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
        body: json.encode(vehicleData),
      );

      print('Register vehicle response: ${response.statusCode}');
      print('Register vehicle body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Vehicle registration failed');
      }
    } catch (e) {
      print('Register vehicle error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>?> getVehicles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vehicles'),
        headers: headers,
      );

      print('Get vehicles response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> vehiclesJson = data['vehicles'] ?? [];
        return vehiclesJson.where((v) => v['verification_status'] == 'approved').toList();
      } else {
        print('Get vehicles error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get vehicles error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getVehicle(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'http://localhost:3000',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to get vehicle');
    }
  }

  static Future<void> uploadVehicleAttachment(int vehicleId, String attachmentType, Map<String, dynamic> fileInfo) async {
    try {
      final headers = await _getHeaders();
      
      // Send file data including base64 image
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/$vehicleId/attachments'),
        headers: headers,
        body: json.encode({
          'attachment_type': attachmentType,
          'file_name': fileInfo['name'],
          'file_size': fileInfo['size'],
          'mime_type': fileInfo['type'],
          'data': fileInfo['data'] ?? '', // Include base64 image data
        }),
      );

      print('Upload attachment response: ${response.statusCode}');
      
      if (response.statusCode != 201) {
        print('Upload attachment error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to upload attachment');
      }
    } catch (e) {
      print('Upload attachment error: $e');
      throw Exception('Network error: $e');
    }
  }
}