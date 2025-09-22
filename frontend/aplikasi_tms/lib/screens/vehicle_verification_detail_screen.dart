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
      final attachments = await _getVehicleAttachments(widget.vehicleId);
      
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Kendaraan'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
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
                        _vehicle!['registration_number'] ?? '',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_vehicle!['brand']} ${_vehicle!['model']} (${_vehicle!['year']})',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.green[600]),
                SizedBox(width: 8),
                Text(
                  'Informasi Pemilik',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow(Icons.apartment, 'Perusahaan', _vehicle!['company_name']),
            _buildInfoRow(Icons.person, 'Nama Pemilik', _vehicle!['owner_name']),
            _buildInfoRow(Icons.email, 'Email', _vehicle!['owner_email']),
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
                  'Informasi Teknis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow(Icons.confirmation_number, 'No. Rangka', _vehicle!['chassis_number']),
            _buildInfoRow(Icons.settings, 'No. Mesin', _vehicle!['engine_number']),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
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
                  'Dokumen Pendukung',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '${_attachments.length} dokumen',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_attachments.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    SizedBox(width: 8),
                    Text(
                      'Belum ada dokumen yang diupload',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _attachments.map((doc) => _buildDocumentItem(doc)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.blue[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['attachment_type'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  doc['file_name'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _viewDocument(doc),
            icon: Icon(Icons.visibility, color: Colors.blue[600]),
            tooltip: 'Lihat Dokumen',
          ),
        ],
      ),
    );
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocument(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dokumen: ${doc['file_name']}'),
        content: Text('Preview dokumen akan ditampilkan di sini'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
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