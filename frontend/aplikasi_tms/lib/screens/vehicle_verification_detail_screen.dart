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
  bool _isLoading = true;
  String _selectedStatus = 'approved';
  final _notesController = TextEditingController();
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
      // Return empty list if no attachments or error
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
    
    // Enhanced status handling
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
          case 'auto_validating':
            statusColor = Colors.blue;
            statusText = 'Validasi Otomatis';
            statusIcon = Icons.auto_fix_high;
            break;
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
          case 'pending_inspection':
            statusColor = Colors.indigo;
            statusText = 'Menunggu Inspeksi';
            statusIcon = Icons.search;
            break;
          default:
            statusColor = Colors.orange;
            statusText = 'Menunggu Verifikasi';
            statusIcon = Icons.pending;
        }
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Status Tidak Diketahui';
        statusIcon = Icons.help;
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
                      if (substatus != 'initial' && substatus != status)
                        Text(
                          '($substatus)',
                          style: TextStyle(
                            color: statusColor.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jenis: ${_vehicle!['vehicle_type']} • Warna: ${_vehicle!['color']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
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
            _buildInfoRow(Icons.phone, 'Telepon', _vehicle!['owner_phone']),
            _buildInfoRow(Icons.location_on, 'Alamat', _vehicle!['owner_address']),
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
            _buildInfoRow(Icons.scale, 'Kapasitas Berat', '${_vehicle!['capacity_weight']} kg'),
            _buildInfoRow(Icons.straighten, 'Kapasitas Volume', '${_vehicle!['capacity_volume']} m³'),
            _buildInfoRow(Icons.verified_user, 'Status Kepemilikan', _vehicle!['ownership_status']),
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
    final typeNames = {
      'stnk': 'STNK',
      'bpkb': 'BPKB',
      'ktp': 'KTP Pemilik',
      'selfie': 'Foto Selfie + KTP',
      'vehicle_photo': 'Foto Kendaraan',
      'foto_depan': 'Foto Depan Kendaraan',
      'foto_belakang': 'Foto Belakang Kendaraan',
      'foto_samping': 'Foto Samping Kendaraan',
      'insurance': 'Asuransi',
      'tax': 'Pajak Kendaraan',
    };

    final typeName = typeNames[doc['attachment_type']] ?? doc['attachment_type'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Thumbnail gambar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<Widget>(
                future: _loadImageThumbnail(doc),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  }
                  return Container(
                    child: Icon(
                      Icons.image,
                      color: Colors.grey[600],
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeName,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  doc['file_name'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${(doc['file_size'] / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
    final substatus = _vehicle!['verification_substatus'] ?? 'initial';
    final autoValidationResult = _vehicle!['auto_validation_result'];
    
    if (status != 'pending') {
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
              if (_vehicle!['verification_notes'] != null) ...[
                SizedBox(height: 8),
                Text('Catatan:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(_vehicle!['verification_notes']),
              ],
            ],
          ),
        ),
      );
    }

    // Show auto validation results if available
    if (autoValidationResult != null && substatus == 'needs_correction') {
      return Column(
        children: [
          _buildAutoValidationCard(autoValidationResult),
          SizedBox(height: 16),
          _buildManualVerificationCard(),
        ],
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
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Setujui'),
                    value: 'approved',
                    groupValue: _selectedStatus,
                    onChanged: (value) => setState(() => _selectedStatus = value!),
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Tolak'),
                    value: 'rejected',
                    groupValue: _selectedStatus,
                    onChanged: (value) => setState(() => _selectedStatus = value!),
                    activeColor: Colors.red,
                  ),
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
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc['file_name'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tampilkan preview gambar
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<Widget>(
                            future: _loadImagePreview(doc),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return snapshot.data!;
                              }
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Loading image...'),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Preview Dokumen',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'File: ${doc['file_name']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        'Size: ${(doc['file_size'] / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadDocument(doc),
                      icon: Icon(Icons.download),
                      label: Text('Download'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openDocument(doc),
                      icon: Icon(Icons.open_in_new),
                      label: Text('Buka'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadDocument(Map<String, dynamic> doc) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mengunduh ${doc['file_name']}...')),
    );
  }

  void _openDocument(Map<String, dynamic> doc) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Membuka ${doc['file_name']}...')),
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
        builder: (context) => Dialog(
          child: Container(
            width: 500,
            height: 600,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text(
                      'Riwayat Verifikasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat verifikasi',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final status = item['new_status'];
                            Color statusColor = status == 'approved' ? Colors.green : Colors.red;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status == 'approved' ? 'Disetujui' : 'Ditolak',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          item['verified_at'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item['admin_name'] != null) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        'Admin: ${item['admin_name']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                    if (item['admin_notes'] != null && item['admin_notes'].toString().isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        'Catatan: ${item['admin_notes']}',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
      
      // Reload data
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

  Widget _buildAutoValidationCard(String autoValidationJson) {
    try {
      final result = json.decode(autoValidationJson);
      final checks = result['checks'] as List;
      final confidence = result['confidence_score'] ?? 0.0;
      
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Text(
                    'Hasil Validasi Otomatis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(confidence).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Confidence: ${(confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: _getConfidenceColor(confidence),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ...checks.map((check) => _buildValidationCheckItem(check)).toList(),
            ],
          ),
        ),
      );
    } catch (e) {
      return Container();
    }
  }

  Widget _buildValidationCheckItem(Map<String, dynamic> check) {
    final status = check['status'];
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;
    
    switch (status) {
      case 'passed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: statusColor.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCheckTypeDisplay(check['type']),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  check['message'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (check['confidence'] != null)
            Text(
              '${(check['confidence'] * 100).toInt()}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualVerificationCard() {
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
                  'Verifikasi Manual',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Text('Keputusan Verifikasi:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Setujui'),
                    value: 'approved',
                    groupValue: _selectedStatus,
                    onChanged: (value) => setState(() => _selectedStatus = value!),
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Tolak'),
                    value: 'rejected',
                    groupValue: _selectedStatus,
                    onChanged: (value) => setState(() => _selectedStatus = value!),
                    activeColor: Colors.red,
                  ),
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getCheckTypeDisplay(String type) {
    switch (type) {
      case 'document_completeness': return 'Kelengkapan Dokumen';
      case 'plate_format': return 'Format Nomor Plat';
      case 'vin_format': return 'Format Nomor Rangka';
      case 'duplicate_check': return 'Pengecekan Duplikasi';
      case 'document_expiry': return 'Masa Berlaku Dokumen';
      default: return type;
    }
  }

  String _getDocumentTypeDisplay(String type) {
    switch (type) {
      case 'bpkb': return 'BPKB';
      case 'stnk': return 'STNK';
      case 'foto_depan': return 'Foto Depan';
      case 'foto_belakang': return 'Foto Belakang';
      case 'foto_samping': return 'Foto Samping';
      default: return type.toUpperCase();
    }
  }

  Future<Widget> _loadImageThumbnail(Map<String, dynamic> doc) async {
    try {
      final fileName = doc['file_name'];
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/files/$fileName'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['type'] == 'base64' && data['data'] != null) {
          return Image.memory(
            base64Decode(data['data'].split(',')[1]),
            fit: BoxFit.cover,
            width: 60,
            height: 60,
          );
        }
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
    }
    
    return Container(
      child: Icon(
        Icons.image,
        color: Colors.grey[600],
        size: 30,
      ),
    );
  }

  Future<Widget> _loadImagePreview(Map<String, dynamic> doc) async {
    try {
      final fileName = doc['file_name'];
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/files/$fileName'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['type'] == 'base64' && data['data'] != null) {
          return Image.memory(
            base64Decode(data['data'].split(',')[1]),
            fit: BoxFit.contain,
            width: 300,
            height: 300,
          );
        }
      }
    } catch (e) {
      print('Error loading preview: $e');
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 64, color: Colors.blue[400]),
        SizedBox(height: 8),
        Text(
          _getDocumentTypeDisplay(doc['attachment_type']),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}