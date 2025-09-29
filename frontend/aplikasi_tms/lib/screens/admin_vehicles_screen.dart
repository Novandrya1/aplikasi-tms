import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';
import '../services/admin_service.dart';
import 'vehicle_verification_detail_screen.dart';

class AdminVehiclesScreen extends StatefulWidget {
  final String filter; // 'pending', 'all', 'history'

  const AdminVehiclesScreen({super.key, required this.filter});

  @override
  _AdminVehiclesScreenState createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _allVehicles = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending';
  Timer? _refreshTimer;
  int _previousPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    // Auto refresh every 5 seconds for real-time updates
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadVehicles();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      // Load real-time data from localStorage (only real registrations)
      final storage = html.window.localStorage;
      final registrationsData = storage['vehicle_registrations'] ?? '[]';
      final List<dynamic> realRegistrations = jsonDecode(registrationsData);
      
      // Convert to proper format - only use real data from user registrations
      _allVehicles = realRegistrations.map((reg) => Map<String, dynamic>.from(reg)).toList();
      
      // Check for new registrations
      final currentPendingCount = _allVehicles.where((v) => 
        v['verification_status'] == 'pending'
      ).length;
      
      if (_previousPendingCount > 0 && currentPendingCount > _previousPendingCount) {
        // New registration detected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notification_important, color: Colors.white),
                SizedBox(width: 8),
                Text('Registrasi kendaraan baru masuk!'),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Lihat',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedFilter = 'pending';
                });
                _filterVehicles();
              },
            ),
          ),
        );
      }
      
      _previousPendingCount = currentPendingCount;
      
      // Filter based on selected filter
      _filterVehicles();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _filterVehicles() {
    List<Map<String, dynamic>> filtered;
    
    switch (_selectedFilter) {
      case 'pending':
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'pending' || 
          v['verification_substatus'] == 'under_review' ||
          v['verification_substatus'] == 'auto_validating'
        ).toList();
        break;
      case 'needs_correction':
        filtered = _allVehicles.where((v) => 
          v['verification_substatus'] == 'needs_correction'
        ).toList();
        break;
      case 'approved':
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'approved'
        ).toList();
        break;
      case 'rejected':
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'rejected'
        ).toList();
        break;
      default: // 'all'
        filtered = _allVehicles;
    }
    
    setState(() {
      _vehicles = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Armada'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _clearAllData,
            tooltip: 'Hapus Semua Data',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadVehicles,
                    child: _vehicles.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _vehicles.length,
                            itemBuilder: (context, index) {
                              return _buildVehicleCard(_vehicles[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Menunggu Verifikasi', 'pending', Icons.pending_actions),
            SizedBox(width: 8),
            _buildFilterChip('Perlu Perbaikan', 'needs_correction', Icons.warning),
            SizedBox(width: 8),
            _buildFilterChip('Disetujui', 'approved', Icons.check_circle),
            SizedBox(width: 8),
            _buildFilterChip('Ditolak', 'rejected', Icons.cancel),
            SizedBox(width: 8),
            _buildFilterChip('Semua', 'all', Icons.list),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status, IconData icon) {
    bool isSelected = _selectedFilter == status;
    int count = _getFilterCount(status);
    
    return FilterChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.red[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.red[600] : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = status;
        });
        _filterVehicles();
      },
      selectedColor: Colors.red[600],
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            'Menampilkan ${_vehicles.length} dari ${_allVehicles.length} kendaraan',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Spacer(),
          if (_selectedFilter == 'pending')
            Text(
              'Perlu Verifikasi: ${_getFilterCount('pending')}',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  int _getFilterCount(String status) {
    switch (status) {
      case 'pending':
        return _allVehicles.where((v) => 
          v['verification_status'] == 'pending' || 
          v['verification_substatus'] == 'under_review' ||
          v['verification_substatus'] == 'auto_validating'
        ).length;
      case 'needs_correction':
        return _allVehicles.where((v) => 
          v['verification_substatus'] == 'needs_correction'
        ).length;
      case 'approved':
        return _allVehicles.where((v) => 
          v['verification_status'] == 'approved'
        ).length;
      case 'rejected':
        return _allVehicles.where((v) => 
          v['verification_status'] == 'rejected'
        ).length;
      default:
        return _allVehicles.length;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.filter == 'pending' 
                ? Icons.pending_actions 
                : widget.filter == 'history'
                    ? Icons.history
                    : Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            widget.filter == 'pending' 
                ? 'Tidak Ada Kendaraan Pending'
                : widget.filter == 'history'
                    ? 'Tidak Ada Riwayat Verifikasi'
                    : 'Tidak Ada Kendaraan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.filter == 'pending'
                ? 'Semua kendaraan sudah diverifikasi'
                : widget.filter == 'history'
                    ? 'Belum ada riwayat verifikasi kendaraan'
                    : 'Belum ada kendaraan yang disetujui',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final status = vehicle['verification_status'] ?? 'pending';
    final substatus = vehicle['verification_substatus'] ?? 'initial';
    
    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    IconData statusIcon = Icons.pending;
    
    // Enhanced status display
    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'Disetujui';
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Ditolak';
      statusIcon = Icons.cancel;
    } else if (substatus == 'needs_correction') {
      statusColor = Colors.orange;
      statusText = 'Perlu Perbaikan';
      statusIcon = Icons.warning;
    } else if (substatus == 'under_review') {
      statusColor = Colors.purple;
      statusText = 'Sedang Ditinjau';
      statusIcon = Icons.rate_review;
    } else if (substatus == 'auto_validating') {
      statusColor = Colors.blue;
      statusText = 'Validasi Otomatis';
      statusIcon = Icons.auto_fix_high;
    }
    
    // Determine owner type
    String ownerType = 'Individu';
    String ownerInfo = vehicle['owner_name'] ?? 'N/A';
    
    if (vehicle['company_name'] != null && vehicle['company_name'].toString().isNotEmpty) {
      ownerType = 'Perusahaan';
      ownerInfo = vehicle['company_name'];
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car, color: Colors.blue[600]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['registration_number'] ?? '',
                        style: TextStyle(
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Owner Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ownerType == 'Perusahaan' ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ownerType,
                          style: TextStyle(
                            color: ownerType == 'Perusahaan' ? Colors.blue[700] : Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ownerInfo,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${vehicle['owner_name'] ?? 'N/A'} • ${vehicle['owner_email'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  if (vehicle['created_at'] != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text(
                          'Daftar: ${_formatDate(vehicle['created_at'])}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Show different buttons based on verification substatus
                if (status == 'pending') ...[
                  if (substatus == 'document_review') ...[
                    ElevatedButton.icon(
                      onPressed: () => _approveDocuments(vehicle),
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Setujui Dokumen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                  ] else if (substatus == 'technical_inspection' && vehicle['technical_inspection']?['completed'] != true) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showTechnicalInspection(vehicle),
                      icon: Icon(Icons.engineering, size: 16),
                      label: Text('Inspeksi Teknis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                  ] else if (substatus == 'inspection_completed') ...[
                    ElevatedButton.icon(
                      onPressed: () => _finalApproval(vehicle),
                      icon: Icon(Icons.verified, size: 16),
                      label: Text('Setujui Final'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ],
                ElevatedButton.icon(
                  onPressed: () => _navigateToDetail(vehicle),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
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

  void _showTechnicalInspection(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.engineering, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Inspeksi Teknis - ${vehicle['registration_number']}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              Text(
                'Checklist Pemeriksaan Kendaraan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              
              ...vehicle['technical_inspection']['checklist'].entries.map((entry) {
                return _buildInspectionChecklistItem(
                  entry.key,
                  entry.value,
                  (value) {
                    setState(() {
                      vehicle['technical_inspection']['checklist'][entry.key] = value;
                    });
                  },
                );
              }).toList(),
              
              SizedBox(height: 20),
              
              TextField(
                decoration: InputDecoration(
                  labelText: 'Catatan Inspeksi',
                  border: OutlineInputBorder(),
                  hintText: 'Tambahkan catatan hasil inspeksi...',
                ),
                maxLines: 3,
                onChanged: (value) {
                  vehicle['technical_inspection']['notes'] = value;
                },
              ),
              
              SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _completeTechnicalInspection(vehicle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Selesai Inspeksi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionChecklistItem(String item, bool isChecked, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isChecked ? Colors.green[300]! : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (value) => onChanged(value!),
            activeColor: Colors.green,
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isChecked ? Colors.green[800] : Colors.grey[700],
              ),
            ),
          ),
          if (isChecked)
            Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  void _approveDocuments(Map<String, dynamic> vehicle) {
    setState(() {
      vehicle['verification_substatus'] = 'technical_inspection';
    });
    
    _saveToLocalStorage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dokumen disetujui. Lanjut ke inspeksi teknis.'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _completeTechnicalInspection(Map<String, dynamic> vehicle) {
    final checklist = vehicle['technical_inspection']['checklist'] as Map<String, dynamic>;
    final allChecked = checklist.values.every((checked) => checked == true);
    
    if (!allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon lengkapi semua checklist inspeksi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      vehicle['technical_inspection']['completed'] = true;
      vehicle['technical_inspection']['inspector'] = 'Admin';
      vehicle['technical_inspection']['inspection_date'] = DateTime.now().toIso8601String();
      vehicle['verification_substatus'] = 'inspection_completed';
    });
    
    _saveToLocalStorage();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inspeksi teknis selesai. Siap untuk persetujuan final.'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _finalApproval(Map<String, dynamic> vehicle) {
    setState(() {
      vehicle['verification_status'] = 'approved';
      vehicle['verification_substatus'] = 'completed';
      vehicle['approved_at'] = DateTime.now().toIso8601String();
    });
    
    _saveToLocalStorage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kendaraan ${vehicle['registration_number']} berhasil disetujui!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _saveToLocalStorage() {
    final storage = html.window.localStorage;
    storage['vehicle_registrations'] = jsonEncode(_allVehicles);
  }
  
  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Semua Data'),
        content: Text('Apakah Anda yakin ingin menghapus semua data registrasi kendaraan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final storage = html.window.localStorage;
              storage.remove('vehicle_registrations');
              Navigator.pop(context);
              _loadVehicles();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Semua data berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleVerificationDetailScreen(
          vehicleId: vehicle['id'],
        ),
      ),
    ).then((_) => _loadVehicles()); // Refresh when returning
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