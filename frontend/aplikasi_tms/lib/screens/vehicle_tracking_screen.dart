import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class VehicleTrackingScreen extends StatefulWidget {
  @override
  _VehicleTrackingScreenState createState() => _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState extends State<VehicleTrackingScreen> {
  List<Map<String, dynamic>> _tracking = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    setState(() => _isLoading = true);
    try {
      final tracking = await DashboardService.getVehicleTracking();
      setState(() {
        _tracking = tracking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Tracking'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTracking,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTracking,
              child: _tracking.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildSummaryCards(),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _tracking.length,
                            itemBuilder: (context, index) {
                              return _buildTrackingCard(_tracking[index]);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Tidak Ada Data Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data tracking kendaraan akan muncul di sini',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final movingCount = _tracking.where((t) => t['status'] == 'moving').length;
    final idleCount = _tracking.where((t) => t['status'] == 'idle').length;
    final maintenanceCount = _tracking.where((t) => t['status'] == 'maintenance').length;

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard('Bergerak', movingCount, Colors.green, Icons.directions_car),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard('Idle', idleCount, Colors.orange, Icons.pause_circle),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard('Maintenance', maintenanceCount, Colors.red, Icons.build),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(Map<String, dynamic> tracking) {
    final status = tracking['status'] ?? 'idle';
    Color statusColor = Colors.orange;
    
    if (status == 'moving') {
      statusColor = Colors.green;
    } else if (status == 'maintenance') {
      statusColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DashboardService.getVehicleStatusIcon(status),
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking['registration_number'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tracking['vehicle_name'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Tracking Info Grid
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrackingInfo(
                          'Kecepatan',
                          '${tracking['speed']?.toStringAsFixed(1) ?? '0'} km/h',
                          Icons.speed,
                        ),
                      ),
                      Expanded(
                        child: _buildTrackingInfo(
                          'Bahan Bakar',
                          '${tracking['fuel_level']?.toStringAsFixed(0) ?? '0'}%',
                          Icons.local_gas_station,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrackingInfo(
                          'Jarak Tempuh',
                          '${tracking['mileage']?.toStringAsFixed(0) ?? '0'} km',
                          Icons.straighten,
                        ),
                      ),
                      Expanded(
                        child: _buildTrackingInfo(
                          'Update Terakhir',
                          _formatLastUpdate(tracking['last_updated']),
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (tracking['latitude'] != null && tracking['longitude'] != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Lat: ${tracking['latitude']?.toStringAsFixed(6)}, Lng: ${tracking['longitude']?.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'moving':
        return 'Bergerak';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Idle';
    }
  }

  String _formatLastUpdate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}