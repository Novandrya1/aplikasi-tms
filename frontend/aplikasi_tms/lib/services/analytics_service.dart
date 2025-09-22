import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DashboardStats {
  final int totalVehicles;
  final int activeVehicles;
  final int totalDrivers;
  final int activeDrivers;
  final int totalTrips;
  final int ongoingTrips;
  final int completedTrips;
  final double totalDistance;
  final int maintenanceDue;

  DashboardStats({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalTrips,
    required this.ongoingTrips,
    required this.completedTrips,
    required this.totalDistance,
    required this.maintenanceDue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalVehicles: json['total_vehicles'],
      activeVehicles: json['active_vehicles'],
      totalDrivers: json['total_drivers'],
      activeDrivers: json['active_drivers'],
      totalTrips: json['total_trips'],
      ongoingTrips: json['ongoing_trips'],
      completedTrips: json['completed_trips'],
      totalDistance: json['total_distance'].toDouble(),
      maintenanceDue: json['maintenance_due'],
    );
  }
}

class VehicleUtilization {
  final int vehicleId;
  final String registrationNumber;
  final int totalTrips;
  final double totalDistance;
  final double utilizationRate;

  VehicleUtilization({
    required this.vehicleId,
    required this.registrationNumber,
    required this.totalTrips,
    required this.totalDistance,
    required this.utilizationRate,
  });

  factory VehicleUtilization.fromJson(Map<String, dynamic> json) {
    return VehicleUtilization(
      vehicleId: json['vehicle_id'],
      registrationNumber: json['registration_number'],
      totalTrips: json['total_trips'],
      totalDistance: json['total_distance'].toDouble(),
      utilizationRate: json['utilization_rate'].toDouble(),
    );
  }
}

class AnalyticsService {
  static Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardStats.fromJson(data['stats']);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<VehicleUtilization>> getVehicleUtilization() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/vehicle-utilization'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> utilizationJson = data['utilization'] ?? [];
        return utilizationJson.map((json) => VehicleUtilization.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicle utilization');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}