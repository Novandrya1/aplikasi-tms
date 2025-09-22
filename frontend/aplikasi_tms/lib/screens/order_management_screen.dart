import 'package:flutter/material.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard('Order Processing', Icons.shopping_cart, Colors.green[600]!),
          _buildCard('Order Tracking', Icons.track_changes, Colors.green[700]!),
          _buildCard('Customer Service', Icons.support_agent, Colors.green[500]!),
          _buildCard('Billing', Icons.receipt, Colors.green[800]!),
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
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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