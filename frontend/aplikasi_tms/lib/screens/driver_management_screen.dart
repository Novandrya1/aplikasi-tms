import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../models/models.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  List<Driver> drivers = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final loadedDrivers = await DriverService.getDrivers();
      setState(() {
        drivers = loadedDrivers ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _showAddDriverDialog() {
    final userIdController = TextEditingController();
    final licenseController = TextEditingController();
    final expiryController = TextEditingController();
    String selectedStatus = 'available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter user ID',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: licenseController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                hintText: 'Enter license number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'License Expiry',
                hintText: 'YYYY-MM-DD',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  expiryController.text = date.toIso8601String().split('T')[0];
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available')),
                DropdownMenuItem(value: 'busy', child: Text('Busy')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) => selectedStatus = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DriverService.createDriver(
                  userId: int.tryParse(userIdController.text) ?? 0,
                  licenseNumber: licenseController.text,
                  licenseExpiry: expiryController.text,
                  status: selectedStatus,
                );
                Navigator.pop(context);
                _loadDrivers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Driver added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total Drivers', drivers.length.toString(), Colors.blue),
                _buildStatCard(
                  'Available', 
                  drivers.where((d) => d.status == 'available').length.toString(), 
                  Colors.green
                ),
                _buildStatCard(
                  'Busy', 
                  drivers.where((d) => d.status == 'busy').length.toString(), 
                  Colors.orange
                ),
              ],
            ),
          ),
          
          // Driver List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $error'),
                            ElevatedButton(
                              onPressed: _loadDrivers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : drivers.isEmpty
                        ? const Center(child: Text('No drivers found'))
                        : RefreshIndicator(
                            onRefresh: _loadDrivers,
                            child: ListView.builder(
                              itemCount: drivers.length,
                              itemBuilder: (context, index) {
                                final driver = drivers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(driver.status),
                                      child: Text(
                                        driver.licenseNumber.length >= 2 
                                            ? driver.licenseNumber.substring(0, 2).toUpperCase()
                                            : driver.licenseNumber.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      driver.user?.fullName ?? 'Driver ${driver.id}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('License: ${driver.licenseNumber}'),
                                        Text('Expires: ${driver.licenseExpiry.toLocal().toString().split(' ')[0]}'),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(driver.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        driver.status.toUpperCase(),
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
        onPressed: _showAddDriverDialog,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}