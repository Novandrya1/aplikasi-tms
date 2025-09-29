import 'package:flutter/material.dart';

class EnhancedAdminVerificationScreen extends StatefulWidget {
  const EnhancedAdminVerificationScreen({super.key});

  @override
  State<EnhancedAdminVerificationScreen> createState() => _EnhancedAdminVerificationScreenState();
}

class _EnhancedAdminVerificationScreenState extends State<EnhancedAdminVerificationScreen> {
  String _selectedFilter = 'pending';
  bool _isLoading = false;
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Armada Enhanced'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildVehiclesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['pending', 'approved', 'rejected', 'all'];
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: filters.map((filter) {
          return FilterChip(
            label: Text(_getFilterLabel(filter)),
            selected: _selectedFilter == filter,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = filter);
                _loadVehicles();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehiclesList() {
    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Tidak ada kendaraan', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(_vehicles[index]);
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(Icons.directions_car, color: Colors.blue),
        title: Text(vehicle['registration_number'] ?? 'N/A'),
        subtitle: Text('${vehicle['brand']} ${vehicle['model']}'),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(vehicle['status']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            vehicle['status']?.toString().toUpperCase() ?? 'PENDING',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        onTap: () => _navigateToDetail(vehicle),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _loadVehicles() {
    setState(() => _isLoading = true);
    
    // Simulate API call
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _vehicles = [
            {
              'id': 1,
              'registration_number': 'B 1234 ABC',
              'brand': 'Toyota',
              'model': 'Avanza',
              'status': 'pending',
            },
            {
              'id': 2,
              'registration_number': 'B 5678 DEF',
              'brand': 'Honda',
              'model': 'Brio',
              'status': 'approved',
            },
          ];
          _isLoading = false;
        });
      }
    });
  }

  void _refresh() {
    _loadVehicles();
  }

  void _navigateToDetail(Map<String, dynamic> vehicle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detail untuk ${vehicle['registration_number']}')),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'pending': return 'Pending';
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      case 'all': return 'Semua';
      default: return filter;
    }
  }
}