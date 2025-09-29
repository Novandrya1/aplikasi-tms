import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class GPSTrackingService {
  static const String baseUrl = '/api/v1';
  static const String wsUrl = 'ws://localhost:8080/api/v1/ws/tracking';
  
  static StreamController<Map<String, dynamic>>? _positionController;
  static Timer? _pollingTimer;

  // Get latest positions of all vehicles
  static Future<List<Map<String, dynamic>>> getLatestPositions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/gps-tracking/positions'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['positions'] ?? []);
    } else {
      throw Exception('Failed to get positions');
    }
  }

  // Get tracking history for specific device
  static Future<List<Map<String, dynamic>>> getTrackingHistory(String deviceId, {int hours = 24}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gps-tracking/history/$deviceId?hours=$hours'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    } else {
      throw Exception('Failed to get tracking history');
    }
  }

  // Simulate GPS data ingestion (for testing)
  static Future<void> simulateGPSData(String deviceId, double lat, double lng, double speed) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gps-tracking/ingest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'latitude': lat,
        'longitude': lng,
        'speed': speed,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send GPS data');
    }
  }

  // Connect to real-time updates using polling
  static Stream<Map<String, dynamic>> connectToRealTimeUpdates() {
    _positionController = StreamController<Map<String, dynamic>>.broadcast();
    _startPolling();
    return _positionController!.stream;
  }



  static void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final positions = await getLatestPositions();
        _positionController?.add({
          'type': 'positions_update',
          'positions': positions,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  static void disconnect() {
    _pollingTimer?.cancel();
    _positionController?.close();
    _pollingTimer = null;
    _positionController = null;
  }

  // Generate mock GPS data for testing
  static List<Map<String, dynamic>> generateMockPositions() {
    return [
      {
        'device_id': 'GPS001',
        'vehicle_id': 1,
        'registration_number': 'B 1234 ABC',
        'latitude': -6.2088,
        'longitude': 106.8456,
        'speed': 45.5,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'moving',
      },
      {
        'device_id': 'GPS002',
        'vehicle_id': 2,
        'registration_number': 'B 5678 DEF',
        'latitude': -6.1751,
        'longitude': 106.8650,
        'speed': 0.0,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        'status': 'stopped',
      },
    ];
  }
}