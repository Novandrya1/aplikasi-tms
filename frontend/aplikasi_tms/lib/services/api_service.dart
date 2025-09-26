import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  static Future<http.Response> _makeRequest(Uri uri) async {
    return await http.get(uri).timeout(Duration(seconds: 30));
  }
  static String get baseUrl {
    final apiBase = ApiConfig.baseUrl;
    return apiBase.isEmpty ? '/api/v1' : '$apiBase/api/v1';
  }
  
  static String _validateUrl(String endpoint) {
    try {
      final url = '$baseUrl$endpoint';
      Uri.parse(url);
      return url;
    } catch (e) {
      return '/api/v1$endpoint';
    }
  }
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    if (token != null) {
      return ApiConfig.authHeaders(token);
    }
    return ApiConfig.headers;
  }
  
  static Future<Map<String, dynamic>> ping() async {
    final response = await _makeRequest(
      Uri.parse('$baseUrl/ping'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to ping API: ${response.statusCode}');
  }
  
  static Future<Map<String, dynamic>> getHealth() async {
    final response = await _makeRequest(
      Uri.parse(ApiConfig.healthUrl),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get health status: ${response.statusCode}');
  }
  
  static Future<Map<String, dynamic>> getDbStatus() async {
    final response = await _makeRequest(
      Uri.parse('$baseUrl/db-status'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get database status: ${response.statusCode}');
  }
  
  static Future<DashboardStats> getDashboardStats() async {
    final response = await http.get(
      Uri.parse(_validateUrl('/dashboard/stats')),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DashboardStats.fromJson(data['stats']);
    }
    throw Exception('Failed to get dashboard stats: ${response.statusCode}');
  }
  
  static Future<List<Vehicle>> getVehicles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehiclesJson = data['vehicles'];
      return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
    }
    throw Exception('Failed to get vehicles: ${response.statusCode}');
  }
  
  static Future<List<Driver>> getDrivers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/drivers'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> driversJson = data['drivers'];
      return driversJson.map((json) => Driver.fromJson(json)).toList();
    }
    throw Exception('Failed to get drivers: ${response.statusCode}');
  }
  
  static Future<List<Trip>> getTrips() async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> tripsJson = data['trips'];
      return tripsJson.map((json) => Trip.fromJson(json)).toList();
    }
    throw Exception('Failed to get trips: ${response.statusCode}');
  }
}