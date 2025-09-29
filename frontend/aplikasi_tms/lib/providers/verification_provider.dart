import 'package:flutter/foundation.dart';
import '../services/enhanced_admin_service.dart';

class VerificationProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<Map<String, dynamic>> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _setLoading(true);
    try {
      _dashboardData = await EnhancedAdminService.getVerificationDashboardCached();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadVehicles({String? status}) async {
    _setLoading(true);
    try {
      final result = await EnhancedAdminService.getVehiclesPaginated(status: status);
      _vehicles = List<Map<String, dynamic>>.from(result['vehicles']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}