import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _currentIndex = 1;

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
            // Stats Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Armada', '25', Icons.directions_car, Colors.blue)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pengiriman Aktif', '12', Icons.local_shipping, Colors.orange)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Driver Aktif', '18', Icons.person, Colors.green)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Rute Selesai', '156', Icons.check_circle, Colors.purple)),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Chart Placeholder
            Text(
              'Grafik Pengiriman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Grafik akan ditampilkan di sini', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Recent Activities
            Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            ...List.generate(5, (index) {
              final activities = [
                'Pengiriman #1001 telah selesai',
                'Driver John telah check-in',
                'Kendaraan B1234ABC sedang maintenance',
                'Rute Jakarta-Bandung dioptimalkan',
                'Pengiriman baru #1005 dibuat',
              ];
              final icons = [
                Icons.check_circle,
                Icons.login,
                Icons.build,
                Icons.route,
                Icons.add_circle,
              ];
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(icons[index], color: Colors.blue),
                  title: Text(activities[index]),
                  subtitle: Text('${index + 1} jam yang lalu'),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
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