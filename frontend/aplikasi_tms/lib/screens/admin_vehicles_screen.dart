import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';
import '../services/admin_service.dart';
import '../services/vehicle_data_service.dart';
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
    _selectedFilter = widget.filter == 'all' ? 'all' : 'pending';
    _loadVehicles();
    
    // Listen for real-time vehicle registration events
    html.window.addEventListener('vehicle_registered', _onVehicleRegistered);
    html.window.addEventListener('vehicle_data_updated', _onVehicleDataUpdated);
    html.window.addEventListener('storage', _onStorageChanged);
    
    // Auto refresh every 10 seconds for real-time updates
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadVehicles();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    html.window.removeEventListener('vehicle_registered', _onVehicleRegistered);
    html.window.removeEventListener('vehicle_data_updated', _onVehicleDataUpdated);
    html.window.removeEventListener('storage', _onStorageChanged);
    super.dispose();
  }
  
  void _onVehicleRegistered(html.Event event) {
    if (mounted) {
      _loadVehicles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.notification_important, color: Colors.white),
              SizedBox(width: 8),
              Text('Kendaraan baru terdaftar!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _onVehicleDataUpdated(html.Event event) {
    if (mounted) {
      _loadVehicles();
    }
  }
  
  void _onStorageChanged(html.Event event) {
    final storageEvent = event as html.StorageEvent;
    if ((storageEvent.key == 'vehicle_registrations' || storageEvent.key == 'vehicle_verifications') && mounted) {
      _loadVehicles();
    }
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      // Clear any sample data first
      VehicleDataService.clearSampleData();
      
      // Load all vehicles from service (only real data)
      _allVehicles = VehicleDataService.getAllVehicles();
      
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
        // Kendaraan yang masih dalam proses verifikasi (belum masuk sistem kelola)
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == null ||
          v['verification_status'] == 'pending' || 
          v['verification_status'] == 'inspection_scheduled' ||
          v['verification_status'] == 'in_progress' ||
          v['verification_status'] == 'inspection_completed'
        ).toList();
        break;
      case 'needs_correction':
        // Kendaraan yang perlu perbaikan dokumen/kondisi
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'needs_repair'
        ).toList();
        break;
      case 'approved':
        // Kendaraan yang sudah disetujui dan aktif dalam sistem
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'approved' &&
          v['management_status'] == 'active'
        ).toList();
        break;
      case 'rejected':
        // Kendaraan yang ditolak
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'rejected'
        ).toList();
        break;
      default: // 'all'
        // Semua kendaraan yang sudah masuk sistem kelola (approved, needs_repair, rejected)
        filtered = _allVehicles.where((v) => 
          v['verification_status'] == 'approved' ||
          v['verification_status'] == 'needs_repair' ||
          v['verification_status'] == 'rejected'
        ).toList();
    }
    
    setState(() {
      _vehicles = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kendaraan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Filter Status Kendaraan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Menunggu Verifikasi', 'pending', Icons.pending_actions),
                SizedBox(width: 8),
                _buildFilterChip('Perlu Perbaikan', 'needs_correction', Icons.build),
                SizedBox(width: 8),
                _buildFilterChip('Disetujui & Aktif', 'approved', Icons.check_circle),
                SizedBox(width: 8),
                _buildFilterChip('Ditolak', 'rejected', Icons.cancel),
                SizedBox(width: 8),
                _buildFilterChip('Semua Kendaraan', 'all', Icons.list),
              ],
            ),
          ),
        ],
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
                color: isSelected ? Colors.white : Colors.blue[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.blue[600] : Colors.white,
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
      selectedColor: Colors.blue[600],
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
            'Menampilkan ${_vehicles.length} dari ${_allVehicles.length} kendaraan • Filter: ${_getFilterDescription()}',
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
          v['verification_status'] == null ||
          v['verification_status'] == 'pending' || 
          v['verification_status'] == 'inspection_scheduled' ||
          v['verification_status'] == 'in_progress' ||
          v['verification_status'] == 'inspection_completed'
        ).length;
      case 'needs_correction':
        return _allVehicles.where((v) => 
          v['verification_status'] == 'needs_repair'
        ).length;
      case 'approved':
        return _allVehicles.where((v) => 
          v['verification_status'] == 'approved' &&
          v['management_status'] == 'active'
        ).length;
      case 'rejected':
        return _allVehicles.where((v) => 
          v['verification_status'] == 'rejected'
        ).length;
      default:
        return _allVehicles.where((v) => 
          v['verification_status'] == 'approved' ||
          v['verification_status'] == 'needs_repair' ||
          v['verification_status'] == 'rejected'
        ).length;
    }
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'pending':
        icon = Icons.pending_actions;
        title = 'Tidak Ada Kendaraan Menunggu';
        subtitle = 'Semua kendaraan sudah diproses verifikasi';
        break;
      case 'needs_correction':
        icon = Icons.build;
        title = 'Tidak Ada Kendaraan Perlu Perbaikan';
        subtitle = 'Semua kendaraan dalam kondisi baik';
        break;
      case 'approved':
        icon = Icons.check_circle;
        title = 'Tidak Ada Kendaraan Aktif';
        subtitle = 'Belum ada kendaraan yang disetujui dan aktif';
        break;
      case 'rejected':
        icon = Icons.cancel;
        title = 'Tidak Ada Kendaraan Ditolak';
        subtitle = 'Semua kendaraan berhasil diverifikasi';
        break;
      default:
        icon = Icons.directions_car_outlined;
        title = 'Tidak Ada Kendaraan';
        subtitle = 'Belum ada kendaraan dalam sistem kelola';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
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
    
    // Enhanced status display with clearer workflow
    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'Aktif';
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Ditolak';
      statusIcon = Icons.cancel;
    } else if (status == 'needs_repair') {
      statusColor = Colors.orange;
      statusText = 'Perlu Perbaikan';
      statusIcon = Icons.build;
    } else if (status == 'inspection_completed') {
      statusColor = Colors.purple;
      statusText = 'Menunggu Keputusan';
      statusIcon = Icons.gavel;
    } else if (status == 'inspection_scheduled') {
      statusColor = Colors.blue;
      statusText = 'Terjadwal Inspeksi';
      statusIcon = Icons.schedule;
    } else if (status == 'in_progress') {
      statusColor = Colors.indigo;
      statusText = 'Sedang Inspeksi';
      statusIcon = Icons.engineering;
    } else {
      // Default untuk kendaraan baru yang belum diverifikasi
      statusColor = Colors.orange;
      statusText = 'Menunggu Verifikasi';
      statusIcon = Icons.pending;
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
            
            // Action Buttons - Simplified workflow
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Show action based on current status
                if (status == 'needs_repair') ...[
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _VehicleDetailDialog(
                        vehicle: vehicle,
                        mode: 'repair',
                      ),
                    ),
                    icon: Icon(Icons.build, size: 16),
                    label: Text('Detail Perbaikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                ] else if (status == 'approved') ...[
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _VehicleDetailDialog(
                        vehicle: vehicle,
                        mode: 'manage',
                        onAction: (action) {
                          Navigator.pop(context);
                          if (action == 'deactivate') {
                            _deactivateVehicle(vehicle);
                          } else if (action == 'schedule_maintenance') {
                            _scheduleMaintenanceDialog(vehicle);
                          }
                        },
                      ),
                    ),
                    icon: Icon(Icons.settings, size: 16),
                    label: Text('Kelola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                ] else if (status == 'rejected') ...[
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _VehicleDetailDialog(
                        vehicle: vehicle,
                        mode: 'rejected',
                      ),
                    ),
                    icon: Icon(Icons.info, size: 16),
                    label: Text('Alasan Penolakan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => _VehicleDetailDialog(
                      vehicle: vehicle,
                      mode: 'view',
                    ),
                  ),
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


  
  void _showRepairDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDetailDialog(
        vehicle: vehicle,
        mode: 'repair',
      ),
    );
  }
  
  String _getInspectionLabel(String key) {
    switch (key) {
      case 'engine_condition': return 'Kondisi Mesin';
      case 'body_condition': return 'Kondisi Body';
      case 'tire_condition': return 'Kondisi Ban';
      case 'brake_condition': return 'Kondisi Rem';
      case 'light_condition': return 'Kondisi Lampu';
      case 'document_completeness': return 'Kelengkapan Dokumen';
      default: return key;
    }
  }
  
  void _showVehicleActions(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDetailDialog(
        vehicle: vehicle,
        mode: 'manage',
        onAction: (action) {
          Navigator.pop(context);
          if (action == 'deactivate') {
            _deactivateVehicle(vehicle);
          } else if (action == 'schedule_maintenance') {
            _scheduleMaintenanceDialog(vehicle);
          }
        },
      ),
    );
  }
  
  void _deactivateVehicle(Map<String, dynamic> vehicle) {
    setState(() {
      vehicle['management_status'] = 'inactive';
      vehicle['deactivated_at'] = DateTime.now().toIso8601String();
    });
    
    _saveToLocalStorage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kendaraan ${vehicle['registration_number']} dinonaktifkan'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  void _scheduleMaintenanceDialog(Map<String, dynamic> vehicle) {
    DateTime selectedDate = DateTime.now().add(Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Jadwal Maintenance - ${vehicle['registration_number']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih tanggal maintenance:'),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
                icon: Icon(Icons.calendar_today),
                label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  vehicle['next_maintenance'] = selectedDate.toIso8601String();
                  vehicle['maintenance_scheduled_at'] = DateTime.now().toIso8601String();
                });
                _saveToLocalStorage();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maintenance dijadwalkan untuk ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Jadwalkan'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveToLocalStorage() {
    // Save individual vehicle updates through service
    for (var vehicle in _allVehicles) {
      VehicleDataService.saveVehicle(vehicle);
    }
  }
  


  void _navigateToDetail(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDetailDialog(
        vehicle: vehicle,
        mode: 'view',
      ),
    );
  }

  String _getFilterDescription() {
    switch (_selectedFilter) {
      case 'pending': return 'Menunggu Verifikasi';
      case 'needs_correction': return 'Perlu Perbaikan';
      case 'approved': return 'Disetujui & Aktif';
      case 'rejected': return 'Ditolak';
      default: return 'Semua Kendaraan';
    }
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

class _VehicleDetailDialog extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final String mode; // 'view', 'repair', 'manage', 'rejected'
  final Function(String)? onAction;

  const _VehicleDetailDialog({
    required this.vehicle,
    this.mode = 'view',
    this.onAction,
  });

  @override
  State<_VehicleDetailDialog> createState() => _VehicleDetailDialogState();
}

class _VehicleDetailDialogState extends State<_VehicleDetailDialog> {

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: 700),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getModeIcon(), color: _getModeColor()),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_getModeTitle()} - ${widget.vehicle['registration_number']}',
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
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Information
                    _buildSection('Informasi Kendaraan', [
                      _buildDetailRow('Nomor Polisi', widget.vehicle['registration_number']),
                      _buildDetailRow('Merek', widget.vehicle['brand']),
                      _buildDetailRow('Model', widget.vehicle['model']),
                      _buildDetailRow('Tahun', widget.vehicle['year']?.toString()),
                      _buildDetailRow('Warna', widget.vehicle['color']),
                      _buildDetailRow('Nomor Rangka', widget.vehicle['chassis_number']),
                      _buildDetailRow('Nomor Mesin', widget.vehicle['engine_number']),
                    ]),
                    
                    SizedBox(height: 16),
                    
                    // Owner Information
                    _buildSection('Informasi Pemilik', [
                      _buildDetailRow('Nama Pemilik', widget.vehicle['owner_name']),
                      _buildDetailRow('Email', widget.vehicle['owner_email']),
                      _buildDetailRow('Telepon', widget.vehicle['owner_phone']),
                      _buildDetailRow('Alamat', widget.vehicle['owner_address']),
                      if (widget.vehicle['company_name'] != null) ...[
                        _buildDetailRow('Nama Perusahaan', widget.vehicle['company_name']),
                        _buildDetailRow('Alamat Perusahaan', widget.vehicle['company_address']),
                      ],
                    ]),
                    
                    SizedBox(height: 16),
                    
                    // Mode-specific content
                    if (widget.mode == 'repair') ..._buildRepairContent(),
                    if (widget.mode == 'manage') ..._buildManageContent(),
                    if (widget.mode == 'rejected') ..._buildRejectedContent(),
                    
                    // Verification Status
                    _buildSection('Status Verifikasi', [
                      _buildStatusRow('Status', widget.vehicle['verification_status'] ?? 'pending'),
                      if (widget.vehicle['verified_by'] != null)
                        _buildDetailRow('Diverifikasi oleh', widget.vehicle['verified_by']),
                      if (widget.vehicle['verified_at'] != null)
                        _buildDetailRow('Tanggal Verifikasi', _formatDateTime(widget.vehicle['verified_at'])),
                      if (widget.vehicle['approved_at'] != null)
                        _buildDetailRow('Tanggal Disetujui', _formatDateTime(widget.vehicle['approved_at'])),
                      if (widget.vehicle['rejected_at'] != null)
                        _buildDetailRow('Tanggal Ditolak', _formatDateTime(widget.vehicle['rejected_at'])),
                    ]),
                    
                    // Inspection Report
                    if (widget.vehicle['inspection_report'] != null) ...[
                      SizedBox(height: 16),
                      _buildInspectionReport(widget.vehicle['inspection_report']),
                    ],
                    
                    // Documents with access
                    SizedBox(height: 16),
                    _buildDocumentsSection(widget.vehicle['documents'] ?? {}),
                    
                    // Maintenance Schedule (for approved vehicles)
                    if (widget.vehicle['verification_status'] == 'approved') ...[
                      SizedBox(height: 16),
                      _buildMaintenanceSection(),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            _buildActionButtons(),
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
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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
    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    
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
      case 'inspection_completed':
        statusColor = Colors.purple;
        statusText = 'Menunggu Keputusan';
        break;
      case 'inspection_scheduled':
        statusColor = Colors.blue;
        statusText = 'Terjadwal Inspeksi';
        break;
      case 'in_progress':
        statusColor = Colors.indigo;
        statusText = 'Sedang Inspeksi';
        break;
      default:
        statusText = 'Menunggu Verifikasi';
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildInspectionReport(Map<String, dynamic> report) {
    return _buildSection('Laporan Inspeksi', [
      if (report['inspector'] != null)
        _buildDetailRow('Inspector', report['inspector']),
      if (report['date'] != null)
        _buildDetailRow('Tanggal Inspeksi', _formatDateTime(report['date'])),
      if (report['results'] != null) ...[
        SizedBox(height: 8),
        Text(
          'Hasil Pemeriksaan:',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        SizedBox(height: 4),
        ...report['results'].entries.map((entry) {
          final condition = entry.value as String;
          final color = condition == 'Baik' ? Colors.green : 
                       condition == 'Cukup' ? Colors.orange : Colors.red;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('${_getInspectionLabel(entry.key)}: $condition'),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      if (report['notes'] != null && report['notes'].toString().isNotEmpty)
        _buildDetailRow('Catatan', report['notes']),
      if (report['recommendation'] != null)
        _buildDetailRow('Rekomendasi', report['recommendation']),
    ]);
  }

  Widget _buildDocumentsSection(Map<String, dynamic> documents) {
    final defaultDocs = {
      'stnk': null,
      'bpkb': null,
      'ktp': null,
      'vehicle_photo': null,
    };
    final allDocs = {...defaultDocs, ...documents};
    
    return _buildSection('Dokumen Kendaraan', [
      ...allDocs.entries.map((entry) {
        final docName = _getDocumentName(entry.key);
        final isUploaded = entry.value != null;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                isUploaded ? Icons.check_circle : Icons.cancel,
                color: isUploaded ? Colors.green : Colors.red,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(docName),
              ),
              if (isUploaded) ...[
                TextButton.icon(
                  onPressed: () => _viewDocument(entry.key, entry.value),
                  icon: Icon(Icons.visibility, size: 14),
                  label: Text('Lihat', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ] else ...[
                Text(
                  'Tidak tersedia',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ]);
  }

  void _viewDocument(String docType, dynamic docData) {
    // Show document viewer dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dokumen ${_getDocumentName(docType)}'),
        content: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 48, color: Colors.grey[600]),
                SizedBox(height: 8),
                Text('Dokumen tersedia'),
                SizedBox(height: 4),
                Text(
                  'Preview dokumen akan ditampilkan di sini',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _getInspectionLabel(String key) {
    switch (key) {
      case 'engine_condition': return 'Kondisi Mesin';
      case 'body_condition': return 'Kondisi Body';
      case 'tire_condition': return 'Kondisi Ban';
      case 'brake_condition': return 'Kondisi Rem';
      case 'light_condition': return 'Kondisi Lampu';
      case 'document_completeness': return 'Kelengkapan Dokumen';
      default: return key;
    }
  }

  String _getDocumentName(String key) {
    switch (key) {
      case 'stnk': return 'STNK';
      case 'bpkb': return 'BPKB';
      case 'ktp': return 'KTP Pemilik';
      case 'vehicle_photo': return 'Foto Kendaraan';
      default: return key;
    }
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

  IconData _getModeIcon() {
    switch (widget.mode) {
      case 'repair': return Icons.build;
      case 'manage': return Icons.settings;
      case 'rejected': return Icons.cancel;
      default: return Icons.directions_car;
    }
  }

  Color _getModeColor() {
    switch (widget.mode) {
      case 'repair': return Colors.orange[600]!;
      case 'manage': return Colors.green[600]!;
      case 'rejected': return Colors.red[600]!;
      default: return Colors.blue[600]!;
    }
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case 'repair': return 'Detail Perbaikan';
      case 'manage': return 'Kelola Kendaraan';
      case 'rejected': return 'Detail Penolakan';
      default: return 'Detail Kendaraan';
    }
  }

  List<Widget> _buildRepairContent() {
    final repairNotes = widget.vehicle['notes'] ?? widget.vehicle['repair_notes'] ?? 'Tidak ada catatan perbaikan';
    return [
      _buildSection('Yang Perlu Diperbaiki', [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Catatan Perbaikan:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(repairNotes),
            ],
          ),
        ),
      ]),
      SizedBox(height: 16),
    ];
  }

  List<Widget> _buildManageContent() {
    final isActive = widget.vehicle['management_status'] != 'inactive';
    final lastMaintenance = widget.vehicle['last_maintenance'];
    final nextMaintenance = widget.vehicle['next_maintenance'];
    
    return [
      _buildSection('Status Operasional', [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: isActive ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (!isActive && widget.vehicle['deactivated_at'] != null)
          _buildDetailRow('Dinonaktifkan', _formatDateTime(widget.vehicle['deactivated_at'])),
      ]),
      SizedBox(height: 16),
    ];
  }

  List<Widget> _buildRejectedContent() {
    final rejectionReason = widget.vehicle['rejection_reason'] ?? 'Tidak ada alasan yang tercatat';
    return [
      _buildSection('Alasan Penolakan', [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Alasan Penolakan:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(rejectionReason),
            ],
          ),
        ),
      ]),
      SizedBox(height: 16),
    ];
  }

  Widget _buildMaintenanceSection() {
    final lastMaintenance = widget.vehicle['last_maintenance'];
    final nextMaintenance = widget.vehicle['next_maintenance'] ?? _calculateNextMaintenance();
    final maintenanceHistory = widget.vehicle['maintenance_history'] ?? [];
    
    return _buildSection('Jadwal Maintenance', [
      _buildDetailRow('Maintenance Terakhir', lastMaintenance != null ? _formatDateTime(lastMaintenance) : 'Belum ada'),
      _buildDetailRow('Maintenance Berikutnya', _formatDateTime(nextMaintenance)),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue[600], size: 16),
            SizedBox(width: 6),
            Text(
              'Maintenance rutin setiap 6 bulan atau 10,000 km',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
          ],
        ),
      ),
    ]);
  }

  String _calculateNextMaintenance() {
    final approvedDate = widget.vehicle['approved_at'];
    if (approvedDate != null) {
      try {
        final approved = DateTime.parse(approvedDate);
        final nextMaintenance = approved.add(Duration(days: 180)); // 6 months
        return nextMaintenance.toIso8601String();
      } catch (e) {
        // Fallback to 6 months from now
        return DateTime.now().add(Duration(days: 180)).toIso8601String();
      }
    }
    return DateTime.now().add(Duration(days: 180)).toIso8601String();
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.mode == 'manage') ...[
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onAction != null) widget.onAction!('schedule_maintenance');
            },
            icon: Icon(Icons.build, size: 16),
            label: Text('Jadwal Maintenance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onAction != null) widget.onAction!('deactivate');
            },
            icon: Icon(Icons.pause_circle, size: 16),
            label: Text('Nonaktifkan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(width: 8),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Tutup'),
        ),
      ],
    );
  }
}