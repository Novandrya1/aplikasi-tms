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
  String _currentFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  void _loadVerifications() {
    setState(() {
      _isLoading = true;
      switch (_currentFilter) {
        case 'all':
          _verifications = VehicleVerificationService().getAllVerifications();
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
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'needs_repair': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'needs_repair': return Icons.build;
      default: return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Menunggu Keputusan';
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



  void _showDecisionDialog(String verificationId) {
    final verification = _verifications.firstWhere((v) => v['id'] == verificationId);
    final vehicleData = verification['vehicleData'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => _DocumentReviewDialog(
        verificationId: verificationId,
        vehicleData: vehicleData,
        onDecision: (decision, notes) {
          Navigator.pop(context);
          if (decision == 'approve') {
            _approveVerification(verificationId);
          } else if (decision == 'reject') {
            _rejectWithReason(verificationId, notes);
          } else if (decision == 'repair') {
            _requireRepairWithDetails(verificationId, notes);
          }
          _loadVerifications();
        },
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



  void _approveVerification(String verificationId) {
    VehicleVerificationService().approveVerification(verificationId, 'Admin');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kendaraan berhasil disetujui dan masuk ke sistem kelola kendaraan'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _rejectWithReason(String verificationId, String reason) {
    VehicleVerificationService().rejectVerification(verificationId, reason, 'Admin');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kendaraan ditolak'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _requireRepairWithDetails(String verificationId, String details) {
    VehicleVerificationService().requireRepair(verificationId, details, 'Admin');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kendaraan dikembalikan untuk perbaikan'),
        backgroundColor: Colors.amber,
      ),
    );
  }
}

class _DocumentReviewDialog extends StatefulWidget {
  final String verificationId;
  final Map<String, dynamic> vehicleData;
  final Function(String decision, String notes) onDecision;

  const _DocumentReviewDialog({
    required this.verificationId,
    required this.vehicleData,
    required this.onDecision,
  });

  @override
  State<_DocumentReviewDialog> createState() => _DocumentReviewDialogState();
}

class _DocumentReviewDialogState extends State<_DocumentReviewDialog> {
  final _notesController = TextEditingController();
  final Map<String, bool> _documentStatus = {};
  final Map<String, String> _documentNotes = {};
  
  final List<Map<String, String>> _requiredDocuments = [
    {'key': 'stnk', 'name': 'STNK', 'description': 'Surat Tanda Nomor Kendaraan'},
    {'key': 'bpkb', 'name': 'BPKB', 'description': 'Buku Pemilik Kendaraan Bermotor'},
    {'key': 'ktp', 'name': 'KTP Pemilik', 'description': 'Kartu Tanda Penduduk pemilik kendaraan'},
    {'key': 'uji_kir', 'name': 'Uji KIR', 'description': 'Sertifikat Uji Kendaraan Bermotor'},
    {'key': 'surat_polisi', 'name': 'Surat Polisi', 'description': 'Surat keterangan dari kepolisian'},
    {'key': 'asuransi', 'name': 'Asuransi', 'description': 'Dokumen asuransi kendaraan'},
    {'key': 'vehicle_photo_front', 'name': 'Foto Depan', 'description': 'Foto kendaraan tampak depan'},
    {'key': 'vehicle_photo_back', 'name': 'Foto Belakang', 'description': 'Foto kendaraan tampak belakang'},
    {'key': 'vehicle_photo_right', 'name': 'Foto Kanan', 'description': 'Foto kendaraan tampak kanan'},
    {'key': 'vehicle_photo_left', 'name': 'Foto Kiri', 'description': 'Foto kendaraan tampak kiri'},
  ];

  @override
  void initState() {
    super.initState();
    final documents = widget.vehicleData['documents'] as Map<String, dynamic>? ?? {};
    for (var doc in _requiredDocuments) {
      _documentStatus[doc['key']!] = documents[doc['key']] != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review Dokumen - ${widget.vehicleData['registration_number']}',
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
                  Text('Email: ${widget.vehicleData['owner_email']}'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Checklist Dokumen:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _requiredDocuments.map((doc) => _buildDocumentCheckItem(doc)).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Verifikasi',
                border: OutlineInputBorder(),
                hintText: 'Tambahkan catatan untuk keputusan ini...',
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canApprove() ? () => _makeDecision('approve') : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeDecision('repair'),
                    icon: const Icon(Icons.build),
                    label: const Text('Perlu Perbaikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeDecision('reject'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Tolak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCheckItem(Map<String, String> doc) {
    final key = doc['key']!;
    final isAvailable = _documentStatus[key] ?? false;
    final isValid = _documentStatus['${key}_valid'] ?? isAvailable;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.description : Icons.warning,
                  color: isAvailable ? (isValid ? Colors.green : Colors.orange) : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        doc['description']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isAvailable) ...[
                  TextButton.icon(
                    onPressed: () => _viewDocument(key),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Lihat'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 12)),
                  ChoiceChip(
                    label: const Text('Valid', style: TextStyle(fontSize: 11)),
                    selected: isValid,
                    onSelected: (selected) {
                      setState(() {
                        _documentStatus['${key}_valid'] = selected;
                        if (!selected) {
                          _documentNotes[key] = _documentNotes[key] ?? 'Dokumen tidak valid';
                        }
                      });
                    },
                    selectedColor: Colors.green[100],
                    labelStyle: TextStyle(color: isValid ? Colors.green[700] : Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Tidak Valid', style: TextStyle(fontSize: 11)),
                    selected: !isValid,
                    onSelected: (selected) {
                      setState(() {
                        _documentStatus['${key}_valid'] = !selected;
                        if (selected) {
                          _showDocumentIssueDialog(key, doc['name']!);
                        }
                      });
                    },
                    selectedColor: Colors.red[100],
                    labelStyle: TextStyle(color: !isValid ? Colors.red[700] : Colors.grey[600]),
                  ),
                ],
              ),
              if (!isValid && _documentNotes[key] != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Masalah: ${_documentNotes[key]}',
                    style: TextStyle(fontSize: 11, color: Colors.red[700]),
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Dokumen tidak tersedia',
                  style: TextStyle(fontSize: 11, color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewDocument(String docKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dokumen ${_getDocumentName(docKey)}'),
        content: Container(
          width: 400,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Preview Dokumen'),
                SizedBox(height: 8),
                Text(
                  'Integrasi dengan storage untuk menampilkan dokumen',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
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

  void _showDocumentIssueDialog(String docKey, String docName) {
    final issueController = TextEditingController(text: _documentNotes[docKey] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Masalah pada $docName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jelaskan masalah pada dokumen ini:'),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi masalah',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Foto tidak jelas, data tidak sesuai, dll.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _documentStatus['${docKey}_valid'] = true;
                _documentNotes.remove(docKey);
              });
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _documentNotes[docKey] = issueController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  bool _canApprove() {
    for (var doc in _requiredDocuments) {
      final key = doc['key']!;
      final isAvailable = _documentStatus[key] ?? false;
      final isValid = _documentStatus['${key}_valid'] ?? isAvailable;
      
      if (!isAvailable || !isValid) {
        return false;
      }
    }
    return true;
  }

  void _makeDecision(String decision) {
    String notes = _notesController.text.trim();
    
    final issues = <String>[];
    for (var doc in _requiredDocuments) {
      final key = doc['key']!;
      final isAvailable = _documentStatus[key] ?? false;
      final isValid = _documentStatus['${key}_valid'] ?? isAvailable;
      
      if (!isAvailable) {
        issues.add('${doc['name']}: Tidak tersedia');
      } else if (!isValid && _documentNotes[key] != null) {
        issues.add('${doc['name']}: ${_documentNotes[key]}');
      }
    }
    
    if (issues.isNotEmpty) {
      notes = issues.join('\n') + (notes.isNotEmpty ? '\n\nCatatan tambahan:\n$notes' : '');
    }
    
    if (decision != 'approve' && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon berikan catatan untuk keputusan ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    widget.onDecision(decision, notes);
  }

  String _getDocumentName(String key) {
    final doc = _requiredDocuments.firstWhere((d) => d['key'] == key, orElse: () => {'name': key});
    return doc['name'] ?? key;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}