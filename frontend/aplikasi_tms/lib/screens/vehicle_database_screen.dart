import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/vehicle_data_service.dart';

class VehicleDatabaseScreen extends StatefulWidget {
  const VehicleDatabaseScreen({super.key});

  @override
  State<VehicleDatabaseScreen> createState() => _VehicleDatabaseScreenState();
}

class _VehicleDatabaseScreenState extends State<VehicleDatabaseScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _filteredVehicles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    
    try {
      // Load from local storage first
      final localVehicles = VehicleDataService.getAllVehicles();
      
      // Try to sync with backend
      final backendVehicles = await _fetchFromBackend();
      
      // Merge data (backend takes priority)
      final allVehicles = [...localVehicles];
      for (var backendVehicle in backendVehicles) {
        final existingIndex = allVehicles.indexWhere(
          (v) => v['registration_number'] == backendVehicle['registration_number']
        );
        if (existingIndex >= 0) {
          allVehicles[existingIndex] = {...allVehicles[existingIndex], ...backendVehicle};
        } else {
          allVehicles.add(backendVehicle);
        }
      }
      
      setState(() {
        _vehicles = allVehicles;
        _filteredVehicles = allVehicles;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      // Fallback to local data if backend fails
      setState(() {
        _vehicles = VehicleDataService.getAllVehicles();
        _filteredVehicles = _vehicles;
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/vehicles'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
      }
    } catch (e) {
      print('Backend fetch error: $e');
    }
    return [];
  }

  void _applyFilters() {
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            vehicle['registration_number']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            vehicle['brand']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            vehicle['model']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            vehicle['owner_name']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

        // Status filter
        final matchesStatus = _selectedStatus == 'all' ||
            vehicle['verification_status'] == _selectedStatus;

        // Type filter
        final matchesType = _selectedType == 'all' ||
            (_selectedType == 'personal' && vehicle['company_name'] == null) ||
            (_selectedType == 'company' && vehicle['company_name'] != null);

        return matchesSearch && matchesStatus && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Kendaraan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadVehicles,
                    child: _filteredVehicles.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredVehicles.length,
                            itemBuilder: (context, index) {
                              return _buildVehicleCard(_filteredVehicles[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari nomor polisi, merek, model, atau pemilik...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'approved', child: Text('Disetujui')),
                    DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                    DropdownMenuItem(value: 'needs_repair', child: Text('Perlu Perbaikan')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tipe Pemilik',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua Tipe')),
                    DropdownMenuItem(value: 'personal', child: Text('Pribadi')),
                    DropdownMenuItem(value: 'company', child: Text('Perusahaan')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalVehicles = _vehicles.length;
    final approvedVehicles = _vehicles.where((v) => v['verification_status'] == 'approved').length;
    final pendingVehicles = _vehicles.where((v) => v['verification_status'] == 'pending').length;
    final rejectedVehicles = _vehicles.where((v) => v['verification_status'] == 'rejected').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatChip('Total', totalVehicles, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatChip('Disetujui', approvedVehicles, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatChip('Pending', pendingVehicles, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatChip('Ditolak', rejectedVehicles, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final status = vehicle['verification_status'] ?? 'pending';
    final isCompany = vehicle['company_name'] != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompany ? Icons.business : Icons.person,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['registration_number'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vehicle['brand']} ${vehicle['model']} (${vehicle['year']})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompany ? Icons.business : Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCompany ? 'Perusahaan' : 'Pribadi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompany ? vehicle['company_name'] : vehicle['owner_name'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (vehicle['owner_email'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      vehicle['owner_email'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (vehicle['created_at'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Terdaftar: ${_formatDate(vehicle['created_at'])}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showVehicleDetail(vehicle),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'approved':
        color = Colors.green;
        text = 'Disetujui';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Ditolak';
        break;
      case 'needs_repair':
        color = Colors.orange;
        text = 'Perlu Perbaikan';
        break;
      default:
        color = Colors.grey;
        text = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storage, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada kendaraan ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetail(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDetailDialog(vehicle: vehicle),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export data akan segera tersedia'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _VehicleDetailDialog extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _VehicleDetailDialog({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Database Kendaraan - ${vehicle['registration_number']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Informasi Kendaraan', [
                      _buildDetailRow('Nomor Polisi', vehicle['registration_number']),
                      _buildDetailRow('Merek', vehicle['brand']),
                      _buildDetailRow('Model', vehicle['model']),
                      _buildDetailRow('Tahun', vehicle['year']?.toString()),
                      _buildDetailRow('Warna', vehicle['color']),
                      _buildDetailRow('Nomor Rangka', vehicle['chassis_number']),
                      _buildDetailRow('Nomor Mesin', vehicle['engine_number']),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildSection('Informasi Pemilik', [
                      _buildDetailRow('Nama Pemilik', vehicle['owner_name']),
                      _buildDetailRow('Email', vehicle['owner_email']),
                      _buildDetailRow('Telepon', vehicle['owner_phone']),
                      _buildDetailRow('Alamat', vehicle['owner_address']),
                      if (vehicle['company_name'] != null) ...[ 
                        _buildDetailRow('Nama Perusahaan', vehicle['company_name']),
                        _buildDetailRow('Alamat Perusahaan', vehicle['company_address']),
                      ],
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildSection('Status & Riwayat', [
                      _buildStatusRow('Status Verifikasi', vehicle['verification_status'] ?? 'pending'),
                      if (vehicle['created_at'] != null)
                        _buildDetailRow('Tanggal Registrasi', _formatDateTime(vehicle['created_at'])),
                      if (vehicle['approved_at'] != null)
                        _buildDetailRow('Tanggal Disetujui', _formatDateTime(vehicle['approved_at'])),
                      if (vehicle['rejected_at'] != null)
                        _buildDetailRow('Tanggal Ditolak', _formatDateTime(vehicle['rejected_at'])),
                    ]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Disetujui';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'needs_repair':
        statusColor = Colors.orange;
        statusText = 'Perlu Perbaikan';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Pending';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}