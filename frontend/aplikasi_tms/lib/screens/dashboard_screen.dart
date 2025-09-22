import 'package:flutter/material.dart';
import 'warehouse_management_screen.dart';
import 'transport_management_screen.dart';
import 'order_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TMS Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
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
            
            // Level 3 - Detailed Processes
            _buildLevelHeader('Level 3 - Operational Processes'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSmallCard('Registrasi\nArmada', Icons.app_registration, Colors.red),
                _buildSmallCard('Registrasi GPS', Icons.gps_not_fixed, Colors.orange),
                _buildSmallCard('Integrasi\nArmada', Icons.integration_instructions, Colors.blue),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Level 4 - Management Processes
            _buildLevelHeader('Level 4 - Management & Analytics'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildSmallCard('Management\nperformance', Icons.trending_up, Colors.green),
                _buildSmallCard('Optimisasi &\nPerformance', Icons.tune, Colors.blue),
                _buildSmallCard('Dashboards', Icons.dashboard, Colors.purple),
                _buildSmallCard('Real-Time\nTracking &\nGPS', Icons.my_location, Colors.red),
                _buildSmallCard('Laporan &\nOperational', Icons.assessment, Colors.orange),
                _buildSmallCard('Peringatan\nPerformance', Icons.warning, Colors.amber),
                _buildSmallCard('Analisis\nperforma\narmada', Icons.analytics, Colors.indigo),
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