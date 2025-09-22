import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../widgets/error_widget.dart';
import 'vehicle_registration_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<dynamic> vehicles = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final vehicleList = await VehicleService.getVehicles();
      if (mounted) {
        setState(() {
          vehicles = vehicleList ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Daftar Armada',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VehicleRegistrationScreen()),
                  );
                  _loadVehicles();
                },
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const LoadingWidget(message: 'Memuat daftar armada...')
          : errorMessage != null
              ? ErrorDisplayWidget(
                  message: errorMessage!,
                  onRetry: _loadVehicles,
                )
              : vehicles.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada armada terdaftar',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VehicleRegistrationScreen()),
              );
              _loadVehicles();
            },
            icon: const Icon(Icons.add),
            label: const Text('Daftarkan Armada Pertama'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(vehicle['operational_status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _translateStatus(vehicle['operational_status']) ?? 'TIDAK DIKETAHUI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle['registration_number'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle['brand'] ?? 'N/A'} ${vehicle['model'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle['vehicle_type'] ?? 'N/A'} • ${vehicle['year'] ?? 'N/A'} • ${vehicle['color'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (vehicle['capacity_weight'] != null && vehicle['capacity_weight'].toString().isNotEmpty)
                  _buildInfoChip(Icons.fitness_center, '${vehicle['capacity_weight']} ton', Colors.orange),
                if (vehicle['capacity_volume'] != null && vehicle['capacity_volume'].toString().isNotEmpty)
                  _buildInfoChip(Icons.inventory, '${vehicle['capacity_volume']} m³', Colors.purple),
                _buildInfoChip(Icons.business, vehicle['ownership_status']?.toString() ?? 'N/A', Colors.blue),
              ],
            ),
            if (vehicle['insurance_company'] != null && vehicle['insurance_company'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Asuransi: ${vehicle['insurance_company']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _translateStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'aktif':
        return 'AKTIF';
      case 'inactive':
      case 'tidak aktif':
        return 'TIDAK AKTIF';
      case 'maintenance':
        return 'PERAWATAN';
      default:
        return status?.toUpperCase() ?? 'TIDAK DIKETAHUI';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'aktif':
        return Colors.green;
      case 'inactive':
      case 'tidak aktif':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}