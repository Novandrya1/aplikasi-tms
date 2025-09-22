import 'package:flutter/material.dart';
import 'warehouse_management_screen.dart';
import 'transport_management_screen.dart';
import 'order_management_screen.dart';
import 'admin_vehicles_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - TMS Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => AdminVehiclesScreen(filter: 'history'),
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
                  colors: [Colors.red[400]!, Colors.red[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
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
              children: [
                _buildAdminCard('Verifikasi\nKendaraan', Icons.verified, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AdminVehiclesScreen(filter: 'pending'),
                  ));
                }),
                _buildAdminCard('Semua\nKendaraan', Icons.directions_car, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AdminVehiclesScreen(filter: 'all'),
                  ));
                }),
                _buildAdminCard('User\nManagement', Icons.people, Colors.purple, () {
                  _showComingSoon(context, 'User Management');
                }),
                _buildAdminCard('System\nSettings', Icons.settings, Colors.grey, () {
                  _showComingSoon(context, 'System Settings');
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
}