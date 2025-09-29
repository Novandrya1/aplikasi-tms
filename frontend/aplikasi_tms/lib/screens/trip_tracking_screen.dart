import 'package:flutter/material.dart';
import 'dart:async';

class TripTrackingScreen extends StatefulWidget {
  final int tripId;

  const TripTrackingScreen({super.key, required this.tripId});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  Timer? _trackingTimer;
  bool _isTracking = false;
  bool _isLoading = false;
  double _currentLat = -6.2088;
  double _currentLng = 106.8456;
  double _currentSpeed = 0;
  int _trackingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    setState(() => _isLoading = true);
    // Simulate loading
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _startTracking() {
    setState(() => _isTracking = true);
    _trackingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _simulateGPSUpdate();
    });
  }

  void _stopTracking() {
    setState(() => _isTracking = false);
    _trackingTimer?.cancel();
  }

  void _simulateGPSUpdate() {
    setState(() {
      _currentLat += (0.001 * (DateTime.now().millisecond % 10 - 5));
      _currentLng += (0.001 * (DateTime.now().millisecond % 10 - 5));
      _currentSpeed = 40 + (DateTime.now().millisecond % 40);
      _trackingCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Tracking'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
            onPressed: _isTracking ? _stopTracking : _startTracking,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTripInfo(),
                  SizedBox(height: 16),
                  _buildTrackingStatus(),
                  SizedBox(height: 16),
                  _buildLocationInfo(),
                  SizedBox(height: 16),
                  _buildMapPlaceholder(),
                  SizedBox(height: 16),
                  _buildTrackingStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildTripInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text(
                  'TRIP-${widget.tripId}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.radio_button_checked, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Jakarta Pusat')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Bandung')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStatus() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isTracking ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                _isTracking ? Icons.gps_fixed : Icons.gps_off,
                color: _isTracking ? Colors.green[600] : Colors.grey[600],
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isTracking ? 'GPS Tracking Aktif' : 'GPS Tracking Nonaktif',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isTracking ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    _isTracking 
                        ? 'Lokasi diperbarui setiap 5 detik'
                        : 'Tekan tombol play untuk memulai tracking',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Lokasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLocationItem(
                    'Latitude',
                    _currentLat.toStringAsFixed(6),
                    Icons.my_location,
                  ),
                ),
                Expanded(
                  child: _buildLocationItem(
                    'Longitude',
                    _currentLng.toStringAsFixed(6),
                    Icons.place,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLocationItem(
                    'Kecepatan',
                    '${_currentSpeed.toStringAsFixed(1)} km/h',
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildLocationItem(
                    'Update Terakhir',
                    DateTime.now().toString().substring(11, 19),
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Card(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'Peta GPS',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              'Lat: ${_currentLat.toStringAsFixed(4)}, Lng: ${_currentLng.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStats() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Tracking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Update',
                    _trackingCount.toString(),
                    Icons.update,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Durasi',
                    '${(_trackingCount * 5 / 60).toStringAsFixed(1)} menit',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}