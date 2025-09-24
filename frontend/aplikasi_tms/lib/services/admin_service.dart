import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class AdminService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Status constants for verification workflow
  static const String statusSubmitted = 'submitted';
  static const String statusPending = 'pending';
  static const String statusNeedsCorrection = 'needs_correction';
  static const String statusUnderReview = 'under_review';
  static const String statusPendingInspection = 'pending_inspection';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusSuspended = 'suspended';

  // Cross-check types
  static const String checkTypeSamsat = 'samsat';
  static const String checkTypeKIR = 'kir';
  static const String checkTypeInsurance = 'insurance';
  static const String checkTypeDuplicate = 'duplicate';

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/admin/dashboard'),
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
      Uri.parse('$baseUrl/api/v1/admin/vehicles/pending'),
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
      Uri.parse('$baseUrl/api/v1/admin/vehicles'),
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
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId'),
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
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/verify'),
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
      Uri.parse('$baseUrl/api/v1/vehicles/$vehicleId/attachments'),
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

  static Future<List<Map<String, dynamic>>> getVerificationHistory(int vehicleId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/history'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get verification history');
    }
  }

  // Enhanced verification methods
  static Future<Map<String, dynamic>> getVerificationDashboard() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/admin/verification-dashboard'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['dashboard'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get verification dashboard');
    }
  }

  static Future<List<Map<String, dynamic>>> getVehiclesByStatus(String status) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/admin/vehicles/status/$status'),
      headers: ApiConfig.authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get vehicles by status');
    }
  }

  static Future<void> requestCorrection(int vehicleId, List<String> correctionItems, String notes) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/correction'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({
        'correction_items': correctionItems,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to request correction');
    }
  }

  static Future<Map<String, dynamic>> performCrossCheck(int vehicleId, String checkType) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/cross-check'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({
        'check_type': checkType,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to perform cross-check');
    }
  }

  static Future<void> scheduleInspection(int vehicleId, DateTime inspectionDate, String location, {String? notes}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/schedule-inspection'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({
        'inspection_date': inspectionDate.toIso8601String(),
        'location': location,
        'notes': notes ?? '',
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to schedule inspection');
    }
  }

  static Future<void> verifyVehicleEnhanced(int vehicleId, String status, {
    String? notes,
    List<String>? correctionItems,
    bool requiresInspection = false,
    Map<String, dynamic>? validationChecks,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final body = {
      'status': status,
      'notes': notes ?? '',
      'requires_inspection': requiresInspection,
    };

    if (correctionItems != null && correctionItems.isNotEmpty) {
      body['correction_items'] = correctionItems;
    }

    if (validationChecks != null) {
      body['validation_checks'] = validationChecks;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/verify'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to verify vehicle');
    }
  }
}