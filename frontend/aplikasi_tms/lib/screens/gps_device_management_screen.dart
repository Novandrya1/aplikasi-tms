import 'package:flutter/material.dart';

class GPSDeviceManagementScreen extends StatefulWidget {
  const GPSDeviceManagementScreen({super.key});

  @override
  State<GPSDeviceManagementScreen> createState() => _GPSDeviceManagementScreenState();
}

class _GPSDeviceManagementScreenState extends State<GPSDeviceManagementScreen> {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _devices = [
        {
          'device_id': 'GPS001',
          'vehicle_registration': 'B 1234 ABC',
          'status': 'active',
          'vehicle_id': 1,
        },
        {
          'device_id': 'GPS002',
          'vehicle_registration': null,
          'status': 'inactive',
          'vehicle_id': null,
        },
      ];
      _vehicles = [
        {'id': 1, 'registration_number': 'B 1234 ABC'},
        {'id': 2, 'registration_number': 'B 5678 DEF'},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Device Management'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.gps_fixed,
                      color: _getStatusColor(device['status']),
                    ),
                    title: Text('Device: ${device['device_id']}'),
                    subtitle: Text('Vehicle: ${device['vehicle_registration'] ?? 'Unassigned'}'),
                    trailing: Chip(
                      label: Text(device['status']),
                      backgroundColor: _getStatusColor(device['status']).withOpacity(0.1),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAssignDeviceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'installed': return Colors.blue;
      case 'inactive': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showAssignDeviceDialog() {
    String? selectedDeviceId;
    int? selectedVehicleId;
    
    final unassignedDevices = _devices.where((d) => d['vehicle_id'] == null).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign GPS Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'GPS Device'),
              items: unassignedDevices.map((device) {
                return DropdownMenuItem<String>(
                  value: device['device_id'],
                  child: Text(device['device_id']),
                );
              }).toList(),
              onChanged: (value) => selectedDeviceId = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Vehicle'),
              items: _vehicles.map((vehicle) {
                return DropdownMenuItem<int>(
                  value: vehicle['id'],
                  child: Text(vehicle['registration_number']),
                );
              }).toList(),
              onChanged: (value) => selectedVehicleId = value,
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
              if (selectedDeviceId != null && selectedVehicleId != null) {
                Navigator.pop(context);
                await _assignDevice(selectedDeviceId!, selectedVehicleId!);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _assignDevice(String deviceId, int vehicleId) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device assigned successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    _loadData();
  }
}