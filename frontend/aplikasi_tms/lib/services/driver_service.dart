import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class DriverService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Driver>?> getDrivers() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/drivers'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> driversJson = data['drivers'] ?? [];
        return driversJson.map((json) => Driver.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Driver> createDriver({
    required int userId,
    required String licenseNumber,
    required String licenseExpiry,
    required String status,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/drivers'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'license_number': licenseNumber,
          'license_expiry': licenseExpiry,
          'status': status,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Driver.fromJson(data['driver']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create driver');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> getDriverProfile() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/driver/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Origin': 'http://localhost:3000',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['driver'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get driver profile');
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverTrips({String? status}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    String url = '$baseUrl/driver/trips';
    if (status != null) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Origin': 'http://localhost:3000',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['trips'] ?? []);
    } else {
      throw Exception('Failed to get driver trips');
    }
  }

  static Future<void> updateTripStatus(int tripId, String status) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.put(
      Uri.parse('$baseUrl/driver/trips/$tripId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Origin': 'http://localhost:3000',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update trip status');
    }
  }

  static Future<void> recordTripTracking(int tripId, double latitude, double longitude, {double speed = 0}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/tracking'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Origin': 'http://localhost:3000',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to record tracking');
    }
  }

  static String getTripStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Ditugaskan';
      case 'started':
        return 'Dimulai';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  static String getTripStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return '📋';
      case 'started':
        return '🚛';
      case 'completed':
        return '✅';
      default:
        return '📦';
    }
  }

  static String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}