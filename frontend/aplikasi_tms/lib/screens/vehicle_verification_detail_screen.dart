import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class VehicleVerificationDetailScreen extends StatefulWidget {
  final int vehicleId;

  const VehicleVerificationDetailScreen({super.key, required this.vehicleId});

  @override
  _VehicleVerificationDetailScreenState createState() => _VehicleVerificationDetailScreenState();
}

class _VehicleVerificationDetailScreenState extends State<VehicleVerificationDetailScreen> {
  Map<String, dynamic>? _vehicle;
  List<Map<String, dynamic>> _attachments = [];
  List<Map<String, dynamic>> _crossCheckResults = [];
  bool _isLoading = true;
  String _selectedStatus = 'approved';
  List<String> _selectedCorrectionItems = [];
  List<Map<String, dynamic>> _correctionOptions = [
    {'id': 'stnk_blur', 'label': 'Foto STNK buram/tidak jelas'},
    {'id': 'bpkb_missing', 'label': 'BPKB belum diupload'},
    {'id': 'insurance_expired', 'label': 'Asuransi sudah habis masa berlaku'},
    {'id': 'vehicle_photo_incomplete', 'label': 'Foto kendaraan tidak lengkap (4 sisi)'},
    {'id': 'ktp_mismatch', 'label': 'Data KTP tidak sesuai dengan pemilik'},
    {'id': 'selfie_unclear', 'label': 'Foto selfie + KTP tidak jelas'},
    {'id': 'tax_expired', 'label': 'Pajak kendaraan sudah habis'},
    {'id': 'kir_missing', 'label': 'KIR belum diupload (untuk angkutan umum)'},
    {'id': 'company_docs', 'label': 'Dokumen perusahaan tidak lengkap'},
    {'id': 'power_of_attorney', 'label': 'Surat kuasa diperlukan'},
  ];
  final _notesController = TextEditingController();
  final _inspectionLocationController = TextEditingController();
  DateTime? _selectedInspectionDate;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleDetails();
  }

  Future<void> _loadVehicleDetails() async {
    setState(() => _isLoading = true);
    try {
      final vehicle = await AdminService.getVehicleDetails(widget.vehicleId);
      
      // Use documents from vehicle details response if available
      List<Map<String, dynamic>> attachments = [];
      if (vehicle['documents'] != null) {
        attachments = List<Map<String, dynamic>>.from(vehicle['documents']);
      }
      
      // Also try to get vehicle attachments
      try {
        final vehicleAttachments = await _getVehicleAttachments(widget.vehicleId);
        attachments.addAll(vehicleAttachments);
      } catch (e) {
        print('Could not load vehicle attachments: $e');
      }
      
      setState(() {
        _vehicle = vehicle;
        _attachments = attachments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getVehicleAttachments(int vehicleId) async {
    try {
      return await AdminService.getVehicleAttachments(vehicleId);
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true to indicate refresh needed
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text('Verifikasi Kendaraan'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
        actions: [
          IconButton(
            onPressed: _showVerificationHistory,
            icon: Icon(Icons.history),
            tooltip: 'Riwayat Verifikasi',
          ),
          if (_vehicle?['verification_status'] == 'pending')
            IconButton(
              onPressed: _showQuickVerificationDialog,
              icon: Icon(Icons.verified),
              tooltip: 'Verifikasi Cepat',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _vehicle == null
              ? Center(child: Text('Kendaraan tidak ditemukan'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleInfoCard(),
                      SizedBox(height: 16),
                      _buildOwnerInfoCard(),
                      SizedBox(height: 16),
                      _buildTechnicalInfoCard(),
                      SizedBox(height: 16),
                      _buildCrossCheckCard(),
                      SizedBox(height: 16),
                      _buildDocumentsCard(),
                      SizedBox(height: 16),
                      _buildVerificationCard(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    final status = _vehicle!['verification_status'] ?? 'pending';
    final substatus = _vehicle!['verification_substatus'] ?? 'initial';
    
    Color statusColor = Colors.orange;
    String statusText = 'Menunggu Verifikasi';
    IconData statusIcon = Icons.pending;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        switch (substatus) {
          case 'needs_correction':
            statusColor = Colors.orange;
            statusText = 'Perlu Perbaikan';
            statusIcon = Icons.warning;
            break;
          case 'under_review':
            statusColor = Colors.purple;
            statusText = 'Sedang Ditinjau';
            statusIcon = Icons.rate_review;
            break;
          default:
            statusColor = Colors.orange;
            statusText = 'Menunggu Verifikasi';
            statusIcon = Icons.pending;
        }
        break;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vehicle!['registration_number'] ?? 'Nomor Polisi Belum Diisi',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: (_vehicle!['registration_number'] ?? '').isEmpty ? Colors.red : Colors.black,
                        ),
                      ),
                      Text(
                        '${_vehicle!['brand'] ?? 'N/A'} ${_vehicle!['model'] ?? 'N/A'} (${_vehicle!['year'] ?? 'N/A'})',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      if ((_vehicle!['days_waiting'] ?? 0) > 0)
                        Text(
                          'Menunggu ${_vehicle!['days_waiting']} hari',
                          style: TextStyle(
                            fontSize: 12, 
                            color: (_vehicle!['days_waiting'] ?? 0) > 7 ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    final ownerType = _vehicle!['owner_type'] ?? 'individual';
    final isCompany = ownerType == 'company';
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isCompany ? Icons.business : Icons.person, color: Colors.green[600]),
                SizedBox(width: 8),
                Text(
                  'Informasi Pemilik ${isCompany ? 'Perusahaan' : 'Individu'}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (isCompany) ...[
              _buildInfoRow(Icons.apartment, 'Nama Perusahaan', _vehicle!['company_name']),
              _buildInfoRow(Icons.description, 'SIUP/NIB', _vehicle!['business_license']),
            ],
            _buildInfoRow(Icons.person, 'Nama Pemilik', _vehicle!['owner_name']),
            _buildInfoRow(Icons.badge, 'No. KTP', _vehicle!['ktp_number']),
            if (isCompany)
              _buildInfoRow(Icons.receipt_long, 'NPWP', _vehicle!['npwp']),
            _buildInfoRow(Icons.email, 'Email', _vehicle!['owner_email']),
            _buildInfoRow(Icons.phone, 'Telepon', _vehicle!['owner_phone']),
            _buildInfoRow(Icons.location_on, 'Alamat', _vehicle!['owner_address']),
            _buildInfoRow(Icons.account_circle, 'Username', _vehicle!['owner_username']),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange[600]),
                SizedBox(width: 8),
                Text(
                  'Spesifikasi Teknis Armada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow(Icons.confirmation_number, 'No. Polisi', _vehicle!['registration_number']),
            _buildInfoRow(Icons.directions_car, 'Jenis Kendaraan', _vehicle!['vehicle_type']),
            _buildInfoRow(Icons.branding_watermark, 'Merek', _vehicle!['brand']),
            _buildInfoRow(Icons.model_training, 'Model/Tipe', _vehicle!['model']),
            _buildInfoRow(Icons.calendar_today, 'Tahun', _vehicle!['year']?.toString()),
            _buildInfoRow(Icons.confirmation_number, 'No. Rangka', _vehicle!['chassis_number']),
            _buildInfoRow(Icons.settings, 'No. Mesin', _vehicle!['engine_number']),
            _buildInfoRow(Icons.palette, 'Warna', _vehicle!['color']),
            if (_vehicle!['capacity_weight'] != null)
              _buildInfoRow(Icons.fitness_center, 'Kapasitas Berat', '${_vehicle!['capacity_weight']} kg'),
            if (_vehicle!['capacity_volume'] != null)
              _buildInfoRow(Icons.all_inbox, 'Kapasitas Volume', '${_vehicle!['capacity_volume']} m³'),
            _buildInfoRow(Icons.business_center, 'Status Kepemilikan', _vehicle!['ownership_status']),
            _buildInfoRow(Icons.traffic, 'Status Operasional', _vehicle!['operational_status']),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    // Group documents by category
    Map<String, List<Map<String, dynamic>>> groupedDocs = {
      'Dokumen Pemilik': [],
      'Dokumen Kendaraan': [],
      'Foto Kendaraan': [],
      'Dokumen Perusahaan': [],
    };
    
    for (var doc in _attachments) {
      String type = doc['attachment_type'] ?? '';
      if (type.contains('ktp') || type.contains('selfie')) {
        groupedDocs['Dokumen Pemilik']!.add(doc);
      } else if (type.contains('stnk') || type.contains('bpkb') || type.contains('tax') || type.contains('insurance')) {
        groupedDocs['Dokumen Kendaraan']!.add(doc);
      } else if (type.contains('vehicle_photo')) {
        groupedDocs['Foto Kendaraan']!.add(doc);
      } else if (type.contains('business') || type.contains('npwp')) {
        groupedDocs['Dokumen Perusahaan']!.add(doc);
      }
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open, color: Colors.purple[600]),
                SizedBox(width: 8),
                Text(
                  'Dokumen Lengkap Registrasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _attachments.length >= 6 ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_attachments.length} dokumen',
                    style: TextStyle(
                      color: _attachments.length >= 6 ? Colors.green[700] : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_attachments.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tidak ada dokumen yang diupload. Registrasi tidak lengkap!',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: groupedDocs.entries.map((entry) {
                  if (entry.value.isEmpty) return SizedBox.shrink();
                  return _buildDocumentGroup(entry.key, entry.value);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentGroup(String groupName, List<Map<String, dynamic>> docs) {
    Color groupColor = Colors.blue;
    IconData groupIcon = Icons.folder;
    
    switch (groupName) {
      case 'Dokumen Pemilik':
        groupColor = Colors.green;
        groupIcon = Icons.person;
        break;
      case 'Dokumen Kendaraan':
        groupColor = Colors.orange;
        groupIcon = Icons.directions_car;
        break;
      case 'Foto Kendaraan':
        groupColor = Colors.purple;
        groupIcon = Icons.camera_alt;
        break;
      case 'Dokumen Perusahaan':
        groupColor = Colors.indigo;
        groupIcon = Icons.business;
        break;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: groupColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: groupColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(groupIcon, color: groupColor, size: 18),
                SizedBox(width: 8),
                Text(
                  groupName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: groupColor,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: groupColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${docs.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: docs.map((doc) => _buildDocumentItem(doc)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    String docType = doc['attachment_type'] ?? '';
    String displayName = _getDocumentDisplayName(docType);
    
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getDocumentIcon(docType),
              color: Colors.blue[600],
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  doc['file_name'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewDocument(doc),
                icon: Icon(Icons.visibility, size: 18),
                tooltip: 'Lihat',
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () => _downloadDocument(doc),
                icon: Icon(Icons.download, size: 18),
                tooltip: 'Download',
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDocumentDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'ktp': return 'KTP Pemilik';
      case 'selfie_ktp': return 'Foto Selfie + KTP';
      case 'stnk': return 'STNK';
      case 'bpkb': return 'BPKB';
      case 'tax_receipt': return 'Bukti Pajak';
      case 'insurance': return 'Asuransi';
      case 'business_license': return 'SIUP/NIB';
      case 'npwp': return 'NPWP';
      default:
        if (type.contains('vehicle_photo')) {
          return 'Foto Kendaraan ${type.split('_').last}';
        }
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ktp':
      case 'selfie_ktp':
        return Icons.badge;
      case 'stnk':
      case 'bpkb':
        return Icons.description;
      case 'tax_receipt':
        return Icons.receipt;
      case 'insurance':
        return Icons.security;
      case 'business_license':
      case 'npwp':
        return Icons.business;
      default:
        if (type.contains('vehicle_photo')) {
          return Icons.photo;
        }
        return Icons.insert_drive_file;
    }
  }

  Widget _buildVerificationCard() {
    final status = _vehicle!['verification_status'] ?? 'pending';
    
    if (status == 'approved' || status == 'rejected') {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    status == 'approved' ? Icons.check_circle : Icons.cancel,
                    color: status == 'approved' ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Status Verifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                status == 'approved' ? 'Kendaraan telah disetujui' : 'Kendaraan ditolak',
                style: TextStyle(
                  color: status == 'approved' ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text(
                  'Verifikasi Kendaraan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Text('Keputusan Verifikasi:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Setujui'),
                  selected: _selectedStatus == 'approved',
                  onSelected: (selected) => setState(() => _selectedStatus = 'approved'),
                  selectedColor: Colors.green[100],
                ),
                ChoiceChip(
                  label: Text('Tolak'),
                  selected: _selectedStatus == 'rejected',
                  onSelected: (selected) => setState(() => _selectedStatus = 'rejected'),
                  selectedColor: Colors.red[100],
                ),
              ],
            ),
            
            SizedBox(height: 16),
            Text('Catatan Verifikasi:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Tambahkan catatan untuk keputusan verifikasi...',
              ),
              maxLines: 3,
            ),
            
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : _verifyVehicle,
                icon: _isVerifying 
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_selectedStatus == 'approved' ? Icons.check : Icons.close),
                label: Text(_selectedStatus == 'approved' ? 'Setujui Kendaraan' : 'Tolak Kendaraan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedStatus == 'approved' ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossCheckCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check, color: Colors.purple[600]),
                SizedBox(width: 8),
                Text(
                  'Cross-check & Validasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildValidationButton('Cek Samsat', Icons.local_police, Colors.blue, () => _performCrossCheck('samsat')),
                _buildValidationButton('Validasi KIR', Icons.verified, Colors.green, () => _performCrossCheck('kir')),
                _buildValidationButton('Cek Asuransi', Icons.security, Colors.orange, () => _performCrossCheck('insurance')),
                _buildValidationButton('Cek Duplikasi', Icons.content_copy, Colors.red, () => _performCrossCheck('duplicate')),
              ],
            ),
            
            if (_crossCheckResults.isNotEmpty) ...[ 
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hasil Validasi:', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    ..._crossCheckResults.map((result) => _buildCheckResult(result)).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildCheckResult(Map<String, dynamic> result) {
    Color resultColor = result['status'] == 'passed' ? Colors.green : Colors.red;
    IconData resultIcon = result['status'] == 'passed' ? Icons.check_circle : Icons.error;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(resultIcon, color: resultColor, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['check_type'] ?? '', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                Text(result['message'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    final isEmpty = (value ?? '').isEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isEmpty ? Colors.red[400] : Colors.grey[600]),
          SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                fontSize: 13,
                color: isEmpty ? Colors.red[600] : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isEmpty ? 'Belum diisi' : value!,
              style: TextStyle(
                fontSize: 13,
                color: isEmpty ? Colors.red[600] : Colors.black87,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (isEmpty)
            Icon(Icons.warning, size: 14, color: Colors.red[400]),
        ],
      ),
    );
  }

  void _viewDocument(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDocumentDisplayName(doc['attachment_type'] ?? ''),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File: ${doc['file_name'] ?? 'Unknown'}'),
                      Text('Tipe: ${doc['attachment_type'] ?? 'Unknown'}'),
                      SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 64, color: Colors.grey[400]),
                                SizedBox(height: 8),
                                Text(
                                  'Preview dokumen',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Klik download untuk melihat file asli',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _downloadDocument(doc),
                      icon: Icon(Icons.download),
                      label: Text('Download'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadDocument(Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mengunduh ${doc['file_name']}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showQuickVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verifikasi Cepat'),
        content: Text('Setujui kendaraan ini tanpa catatan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedStatus = 'approved');
              _verifyVehicle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showVerificationHistory() async {
    try {
      final history = await AdminService.getVerificationHistory(widget.vehicleId);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Riwayat Verifikasi'),
          content: Container(
            width: 400,
            height: 300,
            child: history.isEmpty
                ? Center(child: Text('Belum ada riwayat verifikasi'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return ListTile(
                        title: Text(item['new_status'] ?? ''),
                        subtitle: Text(item['admin_notes'] ?? ''),
                        trailing: Text(item['verified_at'] ?? ''),
                      );
                    },
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyVehicle() async {
    setState(() => _isVerifying = true);
    
    try {
      await AdminService.verifyVehicle(
        widget.vehicleId,
        _selectedStatus,
        notes: _notesController.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kendaraan berhasil diverifikasi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadVehicleDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _performCrossCheck(String checkType) async {
    try {
      final result = await AdminService.performCrossCheck(widget.vehicleId, checkType);
      
      setState(() {
        _crossCheckResults.removeWhere((r) => r['check_type'] == checkType);
        _crossCheckResults.add(result);
      });
      
      final status = result['status'];
      final message = result['message'];
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: status == 'passed' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _inspectionLocationController.dispose();
    super.dispose();
  }
}