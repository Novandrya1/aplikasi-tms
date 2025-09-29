import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class EnhancedAdminService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Cache untuk mengurangi API calls
  static Map<String, dynamic> _cache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Enhanced error handling
  static Future<T> _handleApiCall<T>(Future<http.Response> apiCall, T Function(Map<String, dynamic>) parser) async {
    try {
      final response = await apiCall;
      
      switch (response.statusCode) {
        case 200:
        case 201:
          final data = jsonDecode(response.body);
          return parser(data);
        case 401:
          await AuthService.logout();
          throw Exception('Session expired. Please login again.');
        case 403:
          throw Exception('Access denied. Insufficient permissions.');
        case 404:
          throw Exception('Resource not found.');
        case 422:
          final error = jsonDecode(response.body);
          throw Exception('Validation error: ${error['message'] ?? 'Invalid data'}');
        case 500:
          throw Exception('Server error. Please try again later.');
        default:
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: Please check your connection');
    }
  }

  // Cached dashboard data
  static Future<Map<String, dynamic>> getVerificationDashboardCached() async {
    final now = DateTime.now();
    
    if (_cache.containsKey('dashboard') && 
        _lastCacheUpdate != null && 
        now.difference(_lastCacheUpdate!).compareTo(_cacheTimeout) < 0) {
      return _cache['dashboard'];
    }

    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final data = await _handleApiCall(
      http.get(
        Uri.parse('$baseUrl/api/v1/admin/verification-dashboard'),
        headers: ApiConfig.authHeaders(token),
      ),
      (data) => data['dashboard'] as Map<String, dynamic>,
    );

    _cache['dashboard'] = data;
    _lastCacheUpdate = now;
    return data;
  }

  // Paginated vehicle list
  static Future<Map<String, dynamic>> getVehiclesPaginated({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (search != null) 'search': search,
    };

    final uri = Uri.parse('$baseUrl/api/v1/admin/vehicles').replace(
      queryParameters: queryParams,
    );

    return await _handleApiCall(
      http.get(uri, headers: ApiConfig.authHeaders(token)),
      (data) => {
        'vehicles': data['vehicles'] as List,
        'pagination': data['pagination'] as Map<String, dynamic>,
      },
    );
  }

  // Enhanced verification with validation
  static Future<void> verifyVehicleEnhanced({
    required int vehicleId,
    required String status,
    String? notes,
    List<String>? correctionItems,
    Map<String, dynamic>? validationResults,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    // Client-side validation
    if (status.isEmpty) throw Exception('Status is required');
    if (status == 'rejected' && (notes?.isEmpty ?? true)) {
      throw Exception('Notes are required for rejection');
    }

    final body = {
      'status': status,
      'notes': notes ?? '',
      'timestamp': DateTime.now().toIso8601String(),
      if (correctionItems != null) 'correction_items': correctionItems,
      if (validationResults != null) 'validation_results': validationResults,
    };

    await _handleApiCall(
      http.put(
        Uri.parse('$baseUrl/api/v1/admin/vehicles/$vehicleId/verify'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      ),
      (data) => data,
    );

    // Clear cache after update
    _cache.remove('dashboard');
  }

  // Batch operations
  static Future<void> batchVerifyVehicles({
    required List<int> vehicleIds,
    required String status,
    String? notes,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    await _handleApiCall(
      http.post(
        Uri.parse('$baseUrl/api/v1/admin/vehicles/batch-verify'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'vehicle_ids': vehicleIds,
          'status': status,
          'notes': notes ?? '',
        }),
      ),
      (data) => data,
    );

    _cache.clear(); // Clear all cache after batch operation
  }

  // Clear cache manually
  static void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }
}