import 'package:flutter/material.dart';
import 'warehouse_management_screen.dart';
import 'transport_management_screen.dart';
import 'order_management_screen.dart';
import 'admin_vehicles_screen.dart';
import 'admin_verification_dashboard_screen.dart';
import 'ocr_demo_screen.dart';
import 'admin_document_verification_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Admin - TMS Dashboard'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const AdminVehiclesScreen(filter: 'history'),
              ));
            },
            tooltip: 'Riwayat Verifikasi',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola sistem TMS dengan akses penuh',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Level 1 - Core Business Processes
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
            
            // Admin Specific Functions
            _buildLevelHeader('Admin Functions'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildAdminCard('Verifikasi\nArmada', Icons.verified, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AdminVerificationDashboardScreen(),
                  ));
                }),
                _buildAdminCard('Kelola\nKendaraan', Icons.directions_car, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AdminVehiclesScreen(filter: 'all'),
                  ));
                }),
                _buildAdminCard('User\nManagement', Icons.people, Colors.purple, () {
                  _showComingSoon(context, 'User Management');
                }),
                _buildAdminCard('System\nSettings', Icons.settings, Colors.grey, () {
                  _showComingSoon(context, 'System Settings');
                }),
                _buildAdminCard('Revenue\nAnalytics', Icons.trending_up, Colors.teal, () {
                  Navigator.pushNamed(context, '/revenue-analytics');
                }),
                _buildAdminCard('Shipment\nManagement', Icons.local_shipping, Colors.indigo, () {
                  Navigator.pushNamed(context, '/shipment-management');
                }),
                _buildAdminCard('OCR\nDemo', Icons.document_scanner, Colors.cyan, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const OCRDemoScreen(),
                  ));
                }),
                _buildAdminCard('Verifikasi\nDokumen', Icons.description, Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AdminDocumentVerificationScreen(),
                  ));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF1976D2).withOpacity(0.2)),
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

  Widget _buildAdminCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon')),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
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
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Transport Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.verified),
            title: Text('Verifikasi Armada'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-verification');
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_car),
            title: Text('Kelola Kendaraan'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.trending_up),
            title: Text('Revenue Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/revenue-analytics');
            },
          ),
          ListTile(
            leading: Icon(Icons.local_shipping),
            title: Text('Shipment Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/shipment-management');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }
}