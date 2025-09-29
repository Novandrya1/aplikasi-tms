import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gps_registration.dart';

class GPSService {
  static const String baseUrl = '/api/v1';

  static Future<GPSRegistration> createRegistration(GPSRegistrationRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gps-registration'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return GPSRegistration.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create GPS registration');
    }
  }

  static Future<List<GPSRegistration>> getPendingRegistrations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gps-registration/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GPSRegistration.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get pending registrations');
    }
  }

  static Future<void> approveRegistration(int id, String status, String notes, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/gps-registration/$id/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        'admin_notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update registration');
    }
  }
}