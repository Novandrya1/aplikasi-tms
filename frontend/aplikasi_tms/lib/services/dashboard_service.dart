import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

class DashboardService {
  static String get baseUrl {
    final apiBase = ApiConfig.baseUrl;
    return apiBase.isEmpty ? '/api/v1' : '$apiBase/api/v1';
  }

  static Future<List<Map<String, dynamic>>> getNotifications({int limit = 20}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/notifications?limit=$limit'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    } else {
      throw Exception('Failed to get notifications');
    }
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<List<Map<String, dynamic>>> getVehicleTracking() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/fleet/tracking'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['tracking'] ?? []);
    } else {
      throw Exception('Failed to get vehicle tracking');
    }
  }

  static Future<Map<String, dynamic>> getRevenueAnalytics({int days = 30}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/fleet/analytics?days=$days'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['analytics'];
    } else {
      throw Exception('Failed to get revenue analytics');
    }
  }

  static String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  static String getNotificationIcon(String type) {
    switch (type) {
      case 'success':
        return '✅';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      default:
        return 'ℹ️';
    }
  }

  static String getVehicleStatusIcon(String status) {
    switch (status) {
      case 'moving':
        return '🚛';
      case 'maintenance':
        return '🔧';
      default:
        return '⏸️';
    }
  }
}