import 'package:flutter/material.dart';
import 'warehouse_management_screen.dart';
import 'transport_management_screen.dart';
import 'order_management_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String userName = 'User';
  DashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardStats();
  }

  void _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        userName = user.fullName;
      });
    }
  }

  void _loadDashboardStats() async {
    try {
      final stats = await ApiService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/analytics');
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
        title: const Text('TMS Dashboard'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level 1 - Main Processes
            _buildLevelHeader('Level 1 - Core Business Processes'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildProcessCard(
                  context,
                  'Warehouse\nManagement',
                  Icons.warehouse,
                  Colors.brown,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const WarehouseManagementScreen(),
                  )),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildProcessCard(
                  context,
                  'Transport\nManagement',
                  Icons.local_shipping,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const TransportManagementScreen(),
                  )),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildProcessCard(
                  context,
                  'Order\nManagement',
                  Icons.shopping_cart,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const OrderManagementScreen(),
                  )),
                )),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Dashboard Stats
            _buildStatsSection(),
            
            const SizedBox(height: 32),
            
            // Level 2 - Support Processes
            _buildLevelHeader('Level 2 - Support Processes'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildProcessCard(
                  context,
                  'Management\nGPS',
                  Icons.gps_fixed,
                  Colors.orange,
                  () => _showComingSoon(context, 'Management GPS'),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildProcessCard(
                  context,
                  'Management\nArmada',
                  Icons.directions_car,
                  Colors.purple,
                  () => _showComingSoon(context, 'Management Armada'),
                )),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF1976D2), size: 30),
                ),
                SizedBox(height: 12),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Transport Management',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSection('Operational Processes', [
                  _buildDrawerItem(Icons.app_registration, 'Registrasi Armada', () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Fleet Registration');
                  }),
                  _buildDrawerItem(Icons.gps_not_fixed, 'Registrasi GPS', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/gps-registration');
                  }),
                  _buildDrawerItem(Icons.integration_instructions, 'Integrasi Armada', () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Fleet Management');
                  }),
                ]),
                _buildDrawerSection('Management & Analytics', [
                  _buildDrawerItem(Icons.trending_up, 'Performance Management', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/analytics');
                  }),
                  _buildDrawerItem(Icons.tune, 'Optimisasi Performance', () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Optimisasi Performance');
                  }),
                  _buildDrawerItem(Icons.my_location, 'Real-Time Tracking', () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Real-Time Tracking');
                  }),
                  _buildDrawerItem(Icons.assessment, 'Laporan Operational', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/analytics');
                  }),
                  _buildDrawerItem(Icons.warning, 'Peringatan Performance', () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Peringatan Performance');
                  }),
                  _buildDrawerItem(Icons.analytics, 'Analisis Performa Armada', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/analytics');
                  }),
                ]),
                Divider(),
                _buildDrawerItem(Icons.logout, 'Keluar', () {
                  Navigator.pushReplacementNamed(context, '/');
                }, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...items,
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700], size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.grey[800],
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return Container(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Sistem',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Armada',
                _stats?.totalVehicles.toString() ?? '0',
                Icons.local_shipping,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Trip Aktif',
                _stats?.ongoingTrips.toString() ?? '0',
                Icons.route,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Driver Aktif',
                _stats?.activeDrivers.toString() ?? '0',
                Icons.person,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Trip Selesai',
                _stats?.completedTrips.toString() ?? '0',
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProcessCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon')),
    );
  }
}