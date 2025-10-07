import 'dart:html' as html;
import 'dart:convert';

class VehicleDataService {
  static const String _storageKey = 'vehicle_registrations';
  
  // Get all vehicles from localStorage
  static List<Map<String, dynamic>> getAllVehicles() {
    final storage = html.window.localStorage;
    final data = storage[_storageKey] ?? '[]';
    final List<dynamic> vehicles = jsonDecode(data);
    return vehicles.map((v) => Map<String, dynamic>.from(v)).toList();
  }
  
  // Save vehicle to localStorage
  static void saveVehicle(Map<String, dynamic> vehicle) {
    final vehicles = getAllVehicles();
    
    // Check if vehicle already exists (update) or new (add)
    final existingIndex = vehicles.indexWhere((v) => v['id'] == vehicle['id']);
    
    if (existingIndex >= 0) {
      vehicles[existingIndex] = vehicle;
    } else {
      vehicles.add(vehicle);
    }
    
    _saveToStorage(vehicles);
    _triggerStorageEvent();
  }
  
  // Update vehicle status
  static void updateVehicleStatus(String vehicleId, String status, String substatus) {
    final vehicles = getAllVehicles();
    final vehicleIndex = vehicles.indexWhere((v) => v['id'] == vehicleId);
    
    if (vehicleIndex >= 0) {
      vehicles[vehicleIndex]['verification_status'] = status;
      vehicles[vehicleIndex]['verification_substatus'] = substatus;
      vehicles[vehicleIndex]['updated_at'] = DateTime.now().toIso8601String();
      
      if (status == 'approved') {
        vehicles[vehicleIndex]['approved_at'] = DateTime.now().toIso8601String();
      }
      
      _saveToStorage(vehicles);
      _triggerStorageEvent();
    }
  }
  
  // Get vehicles by status
  static List<Map<String, dynamic>> getVehiclesByStatus(String status) {
    final vehicles = getAllVehicles();
    
    switch (status) {
      case 'pending':
        return vehicles.where((v) => 
          v['verification_status'] == 'pending' || 
          v['verification_substatus'] == 'under_review' ||
          v['verification_substatus'] == 'document_review'
        ).toList();
      case 'approved':
        return vehicles.where((v) => v['verification_status'] == 'approved').toList();
      case 'rejected':
        return vehicles.where((v) => v['verification_status'] == 'rejected').toList();
      case 'needs_repair':
        return vehicles.where((v) => v['verification_status'] == 'needs_repair').toList();
      default:
        return vehicles;
    }
  }

  // Get managed vehicles (approved, rejected, needs_repair)
  static List<Map<String, dynamic>> getManagedVehicles() {
    final vehicles = getAllVehicles();
    return vehicles.where((v) => 
      v['verification_status'] == 'approved' ||
      v['verification_status'] == 'rejected' ||
      v['verification_status'] == 'needs_repair'
    ).toList();
  }

  // Add vehicle from verification
  static void addVehicle(Map<String, dynamic> vehicle) {
    final vehicles = getAllVehicles();
    
    // Check if vehicle already exists (update instead of add)
    final existingIndex = vehicles.indexWhere((v) => 
      v['registration_number'] == vehicle['registration_number'] ||
      (v['id'] != null && v['id'] == vehicle['id'])
    );
    
    if (existingIndex != -1) {
      vehicles[existingIndex] = vehicle;
    } else {
      vehicles.add(vehicle);
    }
    
    _saveToStorage(vehicles);
    _triggerStorageEvent();
  }
  
  // Sample data completely removed - only real data from registration
  static List<Map<String, dynamic>> getSampleData() {
    return [];
  }
  
  // Initialize with sample data if empty - DISABLED
  static void initializeSampleData() {
    // Completely disabled - only use real data from vehicle registration
    return;
  }
  
  // Private methods
  static void _saveToStorage(List<Map<String, dynamic>> vehicles) {
    final storage = html.window.localStorage;
    storage[_storageKey] = jsonEncode(vehicles);
  }
  
  static void _triggerStorageEvent() {
    html.window.dispatchEvent(html.CustomEvent('vehicle_data_updated'));
  }
  
  // Clear all data (for testing)
  static void clearAllData() {
    final storage = html.window.localStorage;
    storage.remove(_storageKey);
    storage.remove('vehicle_verifications'); // Also clear verification data
    _triggerStorageEvent();
  }
  
  // Clear sample data specifically
  static void clearSampleData() {
    final vehicles = getAllVehicles();
    final realVehicles = vehicles.where((v) => 
      v['id'] == null || 
      !v['id'].toString().startsWith('sample_')
    ).toList();
    _saveToStorage(realVehicles);
    _triggerStorageEvent();
  }
}