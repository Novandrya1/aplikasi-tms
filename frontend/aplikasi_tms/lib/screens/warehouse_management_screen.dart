import 'package:flutter/material.dart';

class WarehouseManagementScreen extends StatefulWidget {
  const WarehouseManagementScreen({super.key});

  @override
  State<WarehouseManagementScreen> createState() => _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState extends State<WarehouseManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Management'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard('Inventory', Icons.inventory, Colors.brown[600]!),
          _buildCard('Stock Control', Icons.storage, Colors.brown[700]!),
          _buildCard('Receiving', Icons.input, Colors.brown[500]!),
          _buildCard('Shipping', Icons.output, Colors.brown[800]!),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () => _showFeature(title),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon')),
    );
  }
}