import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import 'trip_tracking_screen.dart';

class DriverTripsScreen extends StatefulWidget {
  final String? initialFilter;

  DriverTripsScreen({this.initialFilter});

  @override
  _DriverTripsScreenState createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Map<String, dynamic>>> _tripsByStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set initial tab based on filter
    if (widget.initialFilter == 'started') {
      _tabController.index = 1;
    }
    
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final allTrips = await DriverService.getDriverTrips();
      final assignedTrips = await DriverService.getDriverTrips(status: 'assigned');
      final startedTrips = await DriverService.getDriverTrips(status: 'started');
      final completedTrips = await DriverService.getDriverTrips(status: 'completed');
      
      setState(() {
        _tripsByStatus = {
          'all': allTrips,
          'assigned': assignedTrips,
          'started': startedTrips,
          'completed': completedTrips,
        };
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
        title: Text('Perjalanan Saya'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Semua'),
            Tab(text: 'Ditugaskan'),
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList('all'),
                _buildTripsList('assigned'),
                _buildTripsList('started'),
                _buildTripsList('completed'),
              ],
            ),
    );
  }

  Widget _buildTripsList(String status) {
    final trips = _tripsByStatus[status] ?? [];
    
    if (trips.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'assigned':
        message = 'Tidak ada perjalanan yang ditugaskan';
        icon = Icons.assignment_outlined;
        break;
      case 'started':
        message = 'Tidak ada perjalanan aktif';
        icon = Icons.navigation_outlined;
        break;
      case 'completed':
        message = 'Belum ada perjalanan selesai';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'Belum ada perjalanan';
        icon = Icons.route_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = trip['status'] ?? '';
    
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
                    color: _getTripStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DriverService.getTripStatusIcon(status),
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['trip_number'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(trip['scheduled_start']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTripStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DriverService.getTripStatusText(status),
                    style: TextStyle(
                      color: _getTripStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Route Info
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
                      Icon(Icons.radio_button_checked, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['origin_address'] ?? '',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['destination_address'] ?? '',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (trip['cargo_description'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip['cargo_description'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (trip['driver_fee'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: Colors.green[600]),
                  SizedBox(width: 8),
                  Text(
                    'Fee: ${DriverService.formatCurrency(trip['driver_fee'].toDouble())}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'assigned')
                  ElevatedButton.icon(
                    onPressed: () => _startTrip(trip),
                    icon: Icon(Icons.play_arrow, size: 16),
                    label: Text('Mulai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status == 'started') ...[
                  TextButton.icon(
                    onPressed: () => _openTracking(trip),
                    icon: Icon(Icons.navigation, size: 16),
                    label: Text('Tracking'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _completeTrip(trip),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Selesai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTripStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'started':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _startTrip(Map<String, dynamic> trip) async {
    try {
      await DriverService.updateTripStatus(trip['id'], 'started');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perjalanan dimulai!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTrips();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeTrip(Map<String, dynamic> trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selesaikan Perjalanan'),
        content: Text('Apakah Anda yakin perjalanan sudah selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Selesai'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DriverService.updateTripStatus(trip['id'], 'completed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perjalanan selesai!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTrips();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openTracking(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripTrackingScreen(trip: trip),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}