import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ConnectionTestScreen extends StatefulWidget {
  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isLoading = false;
  String _status = '';
  DashboardStats? _stats;
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _testConnections();
  }

  Future<void> _testConnections() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connections...';
    });

    try {
      // Test API ping
      await ApiService.ping();
      setState(() {
        _status = 'API connected ✅\n';
      });

      // Test database
      await ApiService.getDbStatus();
      setState(() {
        _status += 'Database connected ✅\n';
      });

      // Load dashboard stats
      final stats = await ApiService.getDashboardStats();
      setState(() {
        _stats = stats;
        _status += 'Dashboard stats loaded ✅\n';
      });

      // Load vehicles
      final vehicles = await ApiService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _status += 'Vehicles loaded (${vehicles.length}) ✅\n';
      });

      // Load drivers
      final drivers = await ApiService.getDrivers();
      setState(() {
        _drivers = drivers;
        _status += 'Drivers loaded (${drivers.length}) ✅\n';
      });

      // Load trips
      final trips = await ApiService.getTrips();
      setState(() {
        _trips = trips;
        _status += 'Trips loaded (${trips.length}) ✅\n';
      });

      setState(() {
        _status += '\n🎉 All connections successful!';
      });

    } catch (e) {
      setState(() {
        _status += 'Error: $e ❌';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _testConnections,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_isLoading)
                      Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Testing connections...'),
                        ],
                      )
                    else
                      Text(
                        _status,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            if (_stats != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildStatRow('Total Vehicles', _stats!.totalVehicles.toString()),
                      _buildStatRow('Active Vehicles', _stats!.activeVehicles.toString()),
                      _buildStatRow('Total Drivers', _stats!.totalDrivers.toString()),
                      _buildStatRow('Active Drivers', _stats!.activeDrivers.toString()),
                      _buildStatRow('Total Trips', _stats!.totalTrips.toString()),
                      _buildStatRow('Ongoing Trips', _stats!.ongoingTrips.toString()),
                      _buildStatRow('Completed Trips', _stats!.completedTrips.toString()),
                      _buildStatRow('Total Distance', '${_stats!.totalDistance.toStringAsFixed(1)} km'),
                      _buildStatRow('Maintenance Due', _stats!.maintenanceDue.toString()),
                    ],
                  ),
                ),
              ),
            ],

            if (_vehicles.isNotEmpty) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Vehicles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ..._vehicles.take(3).map((vehicle) => 
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('${vehicle.registrationNumber} - ${vehicle.brand} ${vehicle.model}'),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: vehicle.operationalStatus == 'active' ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  vehicle.operationalStatus,
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}