import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class TripService {
  static Future<List<Trip>?> getTrips() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trips'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tripsJson = data['trips'] ?? [];
        return tripsJson.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Trip> createTrip({
    int? driverId,
    int? vehicleId,
    required String origin,
    required String destination,
    String? departureTime,
    String? arrivalTime,
    String status = 'planned',
    double? distance,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/trips'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'driver_id': driverId,
          'vehicle_id': vehicleId,
          'origin': origin,
          'destination': destination,
          'departure_time': departureTime,
          'arrival_time': arrivalTime,
          'status': status,
          'distance': distance,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Trip.fromJson(data['trip']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create trip');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Trip> getTripById(int id) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trips/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Trip.fromJson(data['trip']);
      } else {
        throw Exception('Trip not found');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}