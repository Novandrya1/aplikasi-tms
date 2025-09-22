import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  _VehicleManagementScreenState createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<dynamic> vehicles = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await VehicleService.getVehicles();
      setState(() {
        vehicles = result ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', vehicles.length.toString(), Colors.blue),
                _buildStatCard(
                  'Approved', 
                  vehicles.where((v) => v['verification_status'] == 'approved').length.toString(), 
                  Colors.green
                ),
                _buildStatCard(
                  'Pending', 
                  vehicles.where((v) => v['verification_status'] == 'pending').length.toString(), 
                  Colors.orange
                ),
                _buildStatCard(
                  'Rejected', 
                  vehicles.where((v) => v['verification_status'] == 'rejected').length.toString(), 
                  Colors.red
                ),
              ],
            ),
          ),
          
          // Vehicle List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text('Error: $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadVehicles,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : vehicles.isEmpty
                        ? const Center(child: Text('No vehicles found'))
                        : RefreshIndicator(
                            onRefresh: _loadVehicles,
                            child: ListView.builder(
                              itemCount: vehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = vehicles[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(vehicle['verification_status']),
                                      child: Icon(
                                        _getStatusIcon(vehicle['verification_status']),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      '${vehicle['registration_number']} - ${vehicle['brand']} ${vehicle['model']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Type: ${vehicle['vehicle_type']}'),
                                        Text('Year: ${vehicle['year']}'),
                                        if (vehicle['verified_at'] != null)
                                          Text('Verified: ${vehicle['verified_at'].toString().split('T')[0]}'),
                                        if (vehicle['admin_notes'] != null)
                                          Text('Notes: ${vehicle['admin_notes']}', 
                                               style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(vehicle['verification_status']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        vehicle['verification_status'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/fleet-register'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}