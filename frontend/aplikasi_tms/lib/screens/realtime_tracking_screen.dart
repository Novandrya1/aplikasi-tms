import 'package:flutter/material.dart';
import 'dart:async';

class RealtimeTrackingScreen extends StatefulWidget {
  const RealtimeTrackingScreen({super.key});

  @override
  State<RealtimeTrackingScreen> createState() => _RealtimeTrackingScreenState();
}

class _RealtimeTrackingScreenState extends State<RealtimeTrackingScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  bool _isRealTimeConnected = false;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _startSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _vehicles = [
        {
          'registration': 'B 1234 ABC',
          'device_id': 'GPS001',
          'status': 'moving',
          'speed': 45.5,
          'latitude': -6.2088,
          'longitude': 106.8456,
          'timestamp': DateTime.now().toIso8601String(),
        },
        {
          'registration': 'B 5678 DEF',
          'device_id': 'GPS002',
          'status': 'stopped',
          'speed': 0.0,
          'latitude': -6.2100,
          'longitude': 106.8500,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
      ];
      _isLoading = false;
      _isRealTimeConnected = true;
    });
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          for (var vehicle in _vehicles) {
            if (vehicle['status'] == 'moving') {
              vehicle['latitude'] += (DateTime.now().millisecond % 10 - 5) * 0.0001;
              vehicle['longitude'] += (DateTime.now().millisecond % 10 - 5) * 0.0001;
              vehicle['speed'] = 30.0 + (DateTime.now().millisecond % 30);
              vehicle['timestamp'] = DateTime.now().toIso8601String();
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Tracking'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          Icon(
            _isRealTimeConnected ? Icons.wifi : Icons.wifi_off,
            color: _isRealTimeConnected ? Colors.white : Colors.red[300],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Map view coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _simulateGPSData,
            tooltip: 'Simulate GPS Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVehicles,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                color: _getStatusColor(vehicle['status']),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                vehicle['registration'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Chip(
                                label: Text(vehicle['status']),
                                backgroundColor: _getStatusColor(vehicle['status']).withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Device: ${vehicle['device_id'] ?? 'N/A'}'),
                          Text('Speed: ${vehicle['speed']?.toStringAsFixed(1) ?? '0.0'} km/h'),
                          Text('Position: ${vehicle['latitude']?.toStringAsFixed(4)}, ${vehicle['longitude']?.toStringAsFixed(4)}'),
                          Text('Last Update: ${_formatTime(DateTime.parse(vehicle['timestamp'] ?? DateTime.now().toIso8601String()))}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Map view for ${vehicle['registration']} coming soon')),
                                  );
                                },
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('View on Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _showTrackingHistory(vehicle['device_id']),
                                icon: const Icon(Icons.history, size: 16),
                                label: const Text('History'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'moving': return Colors.green;
      case 'stopped': return Colors.orange;
      case 'offline': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _simulateGPSData() {
    setState(() {
      for (var vehicle in _vehicles) {
        vehicle['latitude'] += (DateTime.now().millisecond % 20 - 10) * 0.0001;
        vehicle['longitude'] += (DateTime.now().millisecond % 20 - 10) * 0.0001;
        vehicle['speed'] = 20.0 + (DateTime.now().millisecond % 40);
        vehicle['timestamp'] = DateTime.now().toIso8601String();
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS data simulated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showTrackingHistory(String? deviceId) {
    if (deviceId == null) return;
    
    final history = List.generate(10, (index) => {
      'latitude': -6.2088 + index * 0.001,
      'longitude': 106.8456 + index * 0.001,
      'speed': 30.0 + index * 2,
      'timestamp': DateTime.now().subtract(Duration(minutes: index * 5)).toIso8601String(),
    });
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Tracking History - $deviceId'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final point = history[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, size: 16),
                  title: Text('${(point['latitude'] as double).toStringAsFixed(4)}, ${(point['longitude'] as double).toStringAsFixed(4)}'),
                  subtitle: Text('Speed: ${(point['speed'] as double).toStringAsFixed(1)} km/h'),
                  trailing: Text(_formatTime(DateTime.parse(point['timestamp'] as String))),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}