import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'vehicle_data_service.dart';

class VehicleVerificationService {
  static final VehicleVerificationService _instance = VehicleVerificationService._internal();
  factory VehicleVerificationService() => _instance;
  VehicleVerificationService._internal() {
    _loadFromStorage();
  }

  final List<Map<String, dynamic>> _pendingVerifications = [];
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  static const String _storageKey = 'vehicle_verifications';

  void addVerificationRequest(Map<String, dynamic> vehicleData) {
    final verification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'vehicleData': vehicleData,
      'status': 'pending',
      'submittedAt': DateTime.now().toIso8601String(),
      'documents': vehicleData['documents'] ?? {},
      'inspectionDate': null,
      'notes': '',
      'verifiedBy': null,
    };

    _pendingVerifications.insert(0, verification);
    _saveToStorage();
    _updatePendingCount();

    // Notify admin
    NotificationService().notifyVehicleRegistration(vehicleData);
    
    if (kDebugMode) {
      print('New verification request: ${vehicleData['registration_number']}');
    }
  }

  List<Map<String, dynamic>> getPendingVerifications() => List.from(_pendingVerifications);

  void updateVerificationStatus(String id, String status, {
    String? notes,
    String? verifiedBy,
  }) {
    final index = _pendingVerifications.indexWhere((v) => v['id'] == id);
    if (index != -1) {
      _pendingVerifications[index]['status'] = status;
      if (notes != null) _pendingVerifications[index]['notes'] = notes;
      if (verifiedBy != null) _pendingVerifications[index]['verifiedBy'] = verifiedBy;
      _pendingVerifications[index]['updatedAt'] = DateTime.now().toIso8601String();
      
      _saveToStorage();
      _updatePendingCount();
    }
  }

  void approveVerification(String id, String verifiedBy) {
    updateVerificationStatus(id, 'approved', verifiedBy: verifiedBy);
    _moveToVehicleManagement(id);
  }

  void _moveToVehicleManagement(String verificationId) {
    final verification = _pendingVerifications.firstWhere((v) => v['id'] == verificationId);
    final vehicleData = verification['vehicleData'] as Map<String, dynamic>;
    
    // Add to vehicle management with verification status
    final managedVehicle = {
      ...vehicleData,
      'verification_id': verificationId,
      'verification_status': verification['status'],
      'verified_by': verification['verifiedBy'],
      'verified_at': DateTime.now().toIso8601String(),
      'notes': verification['notes'],
      'management_status': 'active',
    };
    
    VehicleDataService.addVehicle(managedVehicle);
  }

  void rejectVerification(String id, String reason, String verifiedBy) {
    updateVerificationStatus(id, 'rejected', notes: reason, verifiedBy: verifiedBy);
    _moveToVehicleManagement(id);
  }

  void requireRepair(String id, String reason, String verifiedBy) {
    updateVerificationStatus(id, 'needs_repair', notes: reason, verifiedBy: verifiedBy);
    _moveToVehicleManagement(id);
  }



  List<Map<String, dynamic>> getVerificationsByStatus(String status) {
    return _pendingVerifications.where((v) => v['status'] == status).toList();
  }

  List<Map<String, dynamic>> getAllVerifications() => List.from(_pendingVerifications);

  void _loadFromStorage() {
    try {
      final storage = html.window.localStorage;
      final data = storage[_storageKey];
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _pendingVerifications.clear();
        _pendingVerifications.addAll(decoded.cast<Map<String, dynamic>>());
        _updatePendingCount();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading verifications from storage: $e');
      }
    }
  }

  void _saveToStorage() {
    try {
      final storage = html.window.localStorage;
      storage[_storageKey] = jsonEncode(_pendingVerifications);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving verifications to storage: $e');
      }
    }
  }

  void _updatePendingCount() {
    pendingCount.value = _pendingVerifications.where((v) => 
      v['status'] == 'pending'
    ).length;
  }
}