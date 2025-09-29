import 'package:flutter/material.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  State<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends State<MaintenanceManagementScreen> {
  List<Map<String, dynamic>> _maintenanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRecords();
  }

  Future<void> _loadMaintenanceRecords() async {
    // TODO: Load from API
    setState(() {
      _maintenanceRecords = [
        {
          'id': 1,
          'vehicle_registration': 'B 1234 ABC',
          'type': 'scheduled',
          'description': 'Oil change and filter replacement',
          'status': 'pending',
          'scheduled_date': DateTime.now().add(const Duration(days: 3)),
          'mechanic': 'Ahmad Mechanic',
        }
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Management'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _maintenanceRecords.length,
              itemBuilder: (context, index) {
                final record = _maintenanceRecords[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getTypeIcon(record['type']),
                              color: _getStatusColor(record['status']),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              record['vehicle_registration'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(record['status']),
                              backgroundColor: _getStatusColor(record['status']).withOpacity(0.1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Type: ${record['type']}'),
                        Text('Description: ${record['description']}'),
                        Text('Mechanic: ${record['mechanic']}'),
                        Text('Scheduled: ${_formatDate(record['scheduled_date'])}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(record['id'], 'in_progress'),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showMaintenanceDetails(record),
                              icon: const Icon(Icons.info, size: 16),
                              label: const Text('Details'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleMaintenanceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'scheduled': return Icons.schedule;
      case 'repair': return Icons.build;
      case 'inspection': return Icons.search;
      default: return Icons.settings;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateStatus(int id, String status) {
    // TODO: Update via API
    setState(() {
      final index = _maintenanceRecords.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _maintenanceRecords[index]['status'] = status;
      }
    });
  }

  void _showMaintenanceDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${record['vehicle_registration']}'),
            Text('Type: ${record['type']}'),
            Text('Status: ${record['status']}'),
            Text('Description: ${record['description']}'),
            Text('Mechanic: ${record['mechanic']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showScheduleMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Vehicle Registration')),
            TextField(decoration: InputDecoration(labelText: 'Maintenance Type')),
            TextField(decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Schedule maintenance
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}