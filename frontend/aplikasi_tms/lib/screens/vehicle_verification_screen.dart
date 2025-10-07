import 'package:flutter/material.dart';
import '../services/vehicle_verification_service.dart';

class VehicleVerificationScreen extends StatefulWidget {
  const VehicleVerificationScreen({super.key});

  @override
  State<VehicleVerificationScreen> createState() => _VehicleVerificationScreenState();
}

class _VehicleVerificationScreenState extends State<VehicleVerificationScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _verifications = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _currentFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadVerifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVerifications() {
    setState(() {
      _isLoading = true;
      switch (_currentFilter) {
        case 'all':
          _verifications = VehicleVerificationService().getAllVerifications();
          break;
        case 'in_inspection':
          _verifications = VehicleVerificationService().getVerificationsByStatus('in_progress');
          break;
        case 'awaiting_decision':
          _verifications = VehicleVerificationService().getVerificationsByStatus('inspection_completed');
          break;
        case 'history':
          _verifications = VehicleVerificationService().getVerificationsByStatus('approved')
            ..addAll(VehicleVerificationService().getVerificationsByStatus('rejected'))
            ..addAll(VehicleVerificationService().getVerificationsByStatus('needs_repair'));
          break;
        default:
          _verifications = VehicleVerificationService().getVerificationsByStatus(_currentFilter);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Kendaraan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          onTap: (index) {
            final filters = ['pending', 'inspection_scheduled', 'in_inspection', 'awaiting_decision', 'history'];
            _currentFilter = filters[index];
            _loadVerifications();
          },
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending, size: 16)),
            Tab(text: 'Terjadwal', icon: Icon(Icons.schedule, size: 16)),
            Tab(text: 'Inspeksi', icon: Icon(Icons.engineering, size: 16)),
            Tab(text: 'Keputusan', icon: Icon(Icons.gavel, size: 16)),
            Tab(text: 'Riwayat', icon: Icon(Icons.history, size: 16)),
          ],
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: VehicleVerificationService().pendingCount,
            builder: (context, count, child) {
              return count > 0
                  ? Badge(
                      label: Text('$count'),
                      child: IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {},
                      ),
                    )
                  : const SizedBox();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadVerifications(),
              child: _verifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Tidak ada kendaraan yang perlu diverifikasi'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _verifications.length,
                      itemBuilder: (context, index) {
                        final verification = _verifications[index];
                        final vehicleData = verification['vehicleData'] as Map<String, dynamic>;
                        return _buildVerificationCard(verification, vehicleData);
                      },
                    ),
            ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> verification, Map<String, dynamic> vehicleData) {
    final status = verification['status'] as String;
    final submittedAt = DateTime.parse(verification['submittedAt'] as String);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleData['registration_number'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vehicleData['brand']} ${vehicleData['model']} (${vehicleData['year']})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_getStatusText(status)),
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: _getStatusColor(status)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pemilik: ${vehicleData['owner_name']}'),
                      Text('Email: ${vehicleData['owner_email']}'),
                      Text('Tipe: ${vehicleData['ownership_type'] == 'personal' ? 'Pribadi' : 'Perusahaan'}'),
                      Text('Diajukan: ${_formatDate(submittedAt)}'),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showVerificationDetails(verification, vehicleData),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => _scheduleInspection(verification['id']),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Jadwal Inspeksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (status == 'inspection_scheduled') ...[
                  ElevatedButton.icon(
                    onPressed: () => _startInspection(verification['id']),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Mulai Inspeksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (status == 'in_progress') ...[
                  ElevatedButton.icon(
                    onPressed: () => _showInspectionForm(verification['id']),
                    icon: const Icon(Icons.engineering, size: 16),
                    label: const Text('Lakukan Inspeksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (status == 'inspection_completed') ...[
                  ElevatedButton.icon(
                    onPressed: () => _showDecisionDialog(verification['id']),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('Buat Keputusan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'inspection_scheduled': return Colors.blue;
      case 'in_progress': return Colors.indigo;
      case 'inspection_completed': return Colors.purple;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'needs_repair': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'inspection_scheduled': return Icons.schedule;
      case 'in_progress': return Icons.engineering;
      case 'inspection_completed': return Icons.assignment_turned_in;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'needs_repair': return Icons.build;
      default: return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Menunggu Jadwal';
      case 'inspection_scheduled': return 'Siap Inspeksi';
      case 'in_progress': return 'Sedang Inspeksi';
      case 'inspection_completed': return 'Menunggu Keputusan';
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      case 'needs_repair': return 'Perlu Perbaikan';
      default: return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showVerificationDetails(Map<String, dynamic> verification, Map<String, dynamic> vehicleData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Verifikasi - ${vehicleData['registration_number']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Nomor Polisi', vehicleData['registration_number']),
                _buildDetailRow('Merek', vehicleData['brand']),
                _buildDetailRow('Model', vehicleData['model']),
                _buildDetailRow('Tahun', vehicleData['year']),
                _buildDetailRow('Warna', vehicleData['color']),
                _buildDetailRow('Nomor Rangka', vehicleData['chassis_number']),
                _buildDetailRow('Nomor Mesin', vehicleData['engine_number']),
                const Divider(),
                _buildDetailRow('Nama Pemilik', vehicleData['owner_name']),
                _buildDetailRow('Email', vehicleData['owner_email']),
                _buildDetailRow('Telepon', vehicleData['owner_phone']),
                if (vehicleData['company_name'] != null) ...[
                  _buildDetailRow('Perusahaan', vehicleData['company_name']),
                  _buildDetailRow('Alamat Perusahaan', vehicleData['company_address']),
                ],
                const Divider(),
                const Text('Dokumen:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._buildDocumentList(vehicleData['documents']),
                if (verification['inspectionReport'] != null) ...[
                  const Divider(),
                  const Text('Laporan Inspeksi:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._buildInspectionReport(verification['inspectionReport']),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  List<Widget> _buildDocumentList(Map<String, dynamic>? documents) {
    if (documents == null) return [const Text('Tidak ada dokumen')];
    
    return documents.entries.map((entry) {
      final docName = _getDocumentName(entry.key);
      final isUploaded = entry.value != null;
      
      return ListTile(
        dense: true,
        leading: Icon(
          isUploaded ? Icons.check_circle : Icons.cancel,
          color: isUploaded ? Colors.green : Colors.red,
          size: 20,
        ),
        title: Text(docName),
        subtitle: Text(isUploaded ? 'Tersedia' : 'Tidak tersedia'),
        trailing: isUploaded ? TextButton(
          onPressed: () => _showImageDialog(entry.value),
          child: const Text('Lihat'),
        ) : null,
      );
    }).toList();
  }

  List<Widget> _buildInspectionReport(Map<String, dynamic> report) {
    return [
      _buildDetailRow('Inspector', report['inspector']),
      _buildDetailRow('Tanggal Inspeksi', report['date']),
      _buildDetailRow('Kondisi Mesin', report['engine_condition']),
      _buildDetailRow('Kondisi Body', report['body_condition']),
      _buildDetailRow('Kondisi Ban', report['tire_condition']),
      _buildDetailRow('Kelengkapan Dokumen', report['document_completeness']),
      _buildDetailRow('Catatan', report['notes']),
      _buildDetailRow('Rekomendasi', report['recommendation']),
    ];
  }

  void _showImageDialog(String? imagePath) {
    if (imagePath == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Dokumen'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Preview gambar akan ditampilkan di sini'),
                        Text('(Integrasi dengan storage diperlukan)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _scheduleInspection(String verificationId) {
    showDialog(
      context: context,
      builder: (context) {
        DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
        final notesController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Jadwal Inspeksi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Tanggal Inspeksi'),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  VehicleVerificationService().scheduleInspection(
                    verificationId,
                    selectedDate,
                    notesController.text,
                  );
                  Navigator.pop(context);
                  _loadVerifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inspeksi berhasil dijadwalkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Jadwalkan'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDecisionDialog(String verificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keputusan Verifikasi'),
        content: const Text('Pilih keputusan berdasarkan hasil inspeksi:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRejectDialog(verificationId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRepairDialog(verificationId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Perlu Perbaikan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveVerification(verificationId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String verificationId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Verifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan alasan penolakan:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                VehicleVerificationService().rejectVerification(
                  verificationId, 
                  reasonController.text.trim(), 
                  'Admin'
                );
                Navigator.pop(context);
                _loadVerifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verifikasi ditolak'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _showRepairDialog(String verificationId) {
    final reasonController = TextEditingController();
    final List<String> repairItems = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Perlu Perbaikan'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih dokumen/kondisi yang perlu diperbaiki:'),
                const SizedBox(height: 12),
                
                // Checklist dokumen yang perlu diperbaiki
                ..._buildRepairChecklist(repairItems, setState),
                
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Detail tambahan perbaikan',
                    border: OutlineInputBorder(),
                    hintText: 'Jelaskan detail perbaikan yang diperlukan...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (repairItems.isNotEmpty || reasonController.text.trim().isNotEmpty) {
                  final repairDetails = {
                    'repair_items': repairItems,
                    'additional_notes': reasonController.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                  };
                  
                  VehicleVerificationService().requireRepair(
                    verificationId, 
                    repairDetails.toString(), 
                    'Admin'
                  );
                  Navigator.pop(context);
                  _loadVerifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kendaraan dikembalikan untuk perbaikan'),
                      backgroundColor: Colors.amber,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih minimal satu item yang perlu diperbaiki'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Kirim untuk Perbaikan'),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildRepairChecklist(List<String> repairItems, StateSetter setState) {
    final items = [
      'STNK tidak jelas/rusak',
      'BPKB tidak sesuai',
      'KTP pemilik tidak jelas',
      'Foto kendaraan tidak jelas',
      'Nomor rangka tidak terbaca',
      'Nomor mesin tidak sesuai',
      'Kondisi body kendaraan',
      'Kondisi mesin bermasalah',
      'Ban perlu diganti',
      'Dokumen perusahaan tidak lengkap',
    ];
    
    return items.map((item) {
      final isSelected = repairItems.contains(item);
      return CheckboxListTile(
        dense: true,
        title: Text(item, style: const TextStyle(fontSize: 13)),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              repairItems.add(item);
            } else {
              repairItems.remove(item);
            }
          });
        },
        activeColor: Colors.amber,
      );
    }).toList();
  }

  void _startInspection(String verificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai Inspeksi'),
        content: const Text('Apakah Anda yakin ingin memulai proses inspeksi kendaraan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              VehicleVerificationService().startInspection(verificationId, 'Inspector');
              Navigator.pop(context);
              _loadVerifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspeksi dimulai. Silakan lakukan pemeriksaan kendaraan.'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Mulai Inspeksi'),
          ),
        ],
      ),
    );
  }

  void _showInspectionForm(String verificationId) {
    final verification = _verifications.firstWhere((v) => v['id'] == verificationId);
    final vehicleData = verification['vehicleData'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => _InspectionFormDialog(
        verificationId: verificationId,
        vehicleData: vehicleData,
        onCompleted: () {
          _loadVerifications();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inspeksi selesai. Menunggu keputusan admin.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _approveVerification(String verificationId) {
    VehicleVerificationService().approveVerification(verificationId, 'Admin');
    _loadVerifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kendaraan berhasil disetujui dan masuk ke sistem kelola kendaraan'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _InspectionFormDialog extends StatefulWidget {
  final String verificationId;
  final Map<String, dynamic> vehicleData;
  final VoidCallback onCompleted;

  const _InspectionFormDialog({
    required this.verificationId,
    required this.vehicleData,
    required this.onCompleted,
  });

  @override
  State<_InspectionFormDialog> createState() => _InspectionFormDialogState();
}

class _InspectionFormDialogState extends State<_InspectionFormDialog> {
  final _notesController = TextEditingController();
  final Map<String, String> _inspectionResults = {};
  
  final List<Map<String, String>> _inspectionItems = [
    {'key': 'engine_condition', 'label': 'Kondisi Mesin'},
    {'key': 'body_condition', 'label': 'Kondisi Body'},
    {'key': 'tire_condition', 'label': 'Kondisi Ban'},
    {'key': 'brake_condition', 'label': 'Kondisi Rem'},
    {'key': 'light_condition', 'label': 'Kondisi Lampu'},
    {'key': 'document_completeness', 'label': 'Kelengkapan Dokumen'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    for (var item in _inspectionItems) {
      _inspectionResults[item['key']!] = 'Baik';
    }
  }

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
                const Icon(Icons.engineering, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Form Inspeksi - ${widget.vehicleData['registration_number']}',
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
                    // Vehicle Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.vehicleData['brand']} ${widget.vehicleData['model']} (${widget.vehicleData['year']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Pemilik: ${widget.vehicleData['owner_name']}'),
                          Text('Warna: ${widget.vehicleData['color']}'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Text(
                      'Hasil Pemeriksaan:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Inspection Items
                    ..._inspectionItems.map((item) => _buildInspectionItem(
                      item['key']!,
                      item['label']!,
                    )),
                    
                    const SizedBox(height: 20),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Inspeksi',
                        border: OutlineInputBorder(),
                        hintText: 'Tambahkan catatan hasil inspeksi...',
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _completeInspection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Selesai Inspeksi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionItem(String key, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  dense: true,
                  title: const Text('Baik', style: TextStyle(fontSize: 12)),
                  value: 'Baik',
                  groupValue: _inspectionResults[key],
                  onChanged: (value) {
                    setState(() {
                      _inspectionResults[key] = value!;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  dense: true,
                  title: const Text('Cukup', style: TextStyle(fontSize: 12)),
                  value: 'Cukup',
                  groupValue: _inspectionResults[key],
                  onChanged: (value) {
                    setState(() {
                      _inspectionResults[key] = value!;
                    });
                  },
                  activeColor: Colors.orange,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  dense: true,
                  title: const Text('Buruk', style: TextStyle(fontSize: 12)),
                  value: 'Buruk',
                  groupValue: _inspectionResults[key],
                  onChanged: (value) {
                    setState(() {
                      _inspectionResults[key] = value!;
                    });
                  },
                  activeColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _completeInspection() {
    final inspectionReport = {
      'inspector': 'Inspector',
      'date': DateTime.now().toIso8601String(),
      'results': _inspectionResults,
      'notes': _notesController.text.trim(),
      'recommendation': _getRecommendation(),
    };

    VehicleVerificationService().completeInspection(
      widget.verificationId,
      inspectionReport,
      'Inspector',
    );

    Navigator.pop(context);
    widget.onCompleted();
  }

  String _getRecommendation() {
    final badConditions = _inspectionResults.values.where((v) => v == 'Buruk').length;
    final fairConditions = _inspectionResults.values.where((v) => v == 'Cukup').length;
    
    if (badConditions > 0) {
      return 'Perlu Perbaikan';
    } else if (fairConditions > 2) {
      return 'Perlu Perhatian';
    } else {
      return 'Layak Disetujui';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}