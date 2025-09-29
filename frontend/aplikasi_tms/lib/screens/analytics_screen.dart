import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import 'dart:async';

class AnalyticsScreen extends StatefulWidget {
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _currentIndex = 1;
  DashboardStats? _stats;
  List<Vehicle> _vehicles = [];
  List<Trip> _trips = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadAnalyticsData();
    });
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final stats = await ApiService.getDashboardStats();
      final vehicles = await ApiService.getVehicles();
      final trips = await ApiService.getTrips();
      
      setState(() {
        _stats = stats;
        _vehicles = vehicles;
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        // Already on analytics
        break;
      case 2:
        Navigator.pushNamed(context, '/notifications');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analitik'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-time Stats Cards
            _isLoading ? _buildLoadingStats() : _buildRealTimeStats(),
            
            SizedBox(height: 24),
            
            // Vehicle Analytics Chart
            _buildVehicleAnalytics(),
            
            SizedBox(height: 24),
            
            // Real Activities from Backend
            _buildRealActivities(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analytics Real-Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Total Armada', 
              _stats?.totalVehicles.toString() ?? '0', 
              Icons.directions_car, 
              Colors.blue
            )),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Trip Aktif', 
              _stats?.ongoingTrips.toString() ?? '0', 
              Icons.local_shipping, 
              Colors.orange
            )),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Driver Aktif', 
              _stats?.activeDrivers.toString() ?? '0', 
              Icons.person, 
              Colors.green
            )),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Trip Selesai', 
              _stats?.completedTrips.toString() ?? '0', 
              Icons.check_circle, 
              Colors.purple
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analisis Kendaraan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status Kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_vehicles.length} Total', style: TextStyle(color: Colors.grey)),
                ],
              ),
              SizedBox(height: 16),
              ..._buildVehicleStatusList(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVehicleStatusList() {
    if (_vehicles.isEmpty) {
      return [
        Center(
          child: Text(
            'Tidak ada data kendaraan',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ];
    }

    Map<String, int> statusCount = {};
    Map<String, Color> statusColors = {
      'active': Colors.green,
      'maintenance': Colors.orange,
      'inactive': Colors.red,
    };

    for (var vehicle in _vehicles) {
      statusCount[vehicle.operationalStatus] = 
          (statusCount[vehicle.operationalStatus] ?? 0) + 1;
    }

    return statusCount.entries.map((entry) {
      final percentage = (entry.value / _vehicles.length * 100).round();
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColors[entry.key] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${entry.key.toUpperCase()}: ${entry.value} unit ($percentage%)',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRealActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas Real-Time',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        ..._generateRealActivities(),
      ],
    );
  }

  List<Widget> _generateRealActivities() {
    List<Widget> activities = [];

    // System status activity
    activities.add(
      Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(Icons.system_update, color: Colors.green),
          title: Text('Sistem TMS Aktif'),
          subtitle: Text('${_stats?.totalVehicles ?? 0} kendaraan dan ${_stats?.activeDrivers ?? 0} driver terpantau'),
          trailing: Text('Live', style: TextStyle(color: Colors.green, fontSize: 12)),
        ),
      ),
    );

    // Vehicle activities
    for (int i = 0; i < _vehicles.take(3).length; i++) {
      final vehicle = _vehicles[i];
      activities.add(
        Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              vehicle.operationalStatus == 'active' ? Icons.check_circle : Icons.build,
              color: vehicle.operationalStatus == 'active' ? Colors.green : Colors.orange,
            ),
            title: Text('Kendaraan ${vehicle.registrationNumber}'),
            subtitle: Text('Status: ${vehicle.operationalStatus} - ${vehicle.brand} ${vehicle.model}'),
            trailing: Text('${i + 1}h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
      );
    }

    // Trip activities
    if (_stats?.ongoingTrips != null && _stats!.ongoingTrips > 0) {
      activities.add(
        Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.local_shipping, color: Colors.blue),
            title: Text('Trip Sedang Berlangsung'),
            subtitle: Text('${_stats!.ongoingTrips} trip aktif dalam perjalanan'),
            trailing: Text('Live', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ),
        ),
      );
    }

    return activities;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}