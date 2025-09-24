import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleAttachmentsScreen extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const VehicleAttachmentsScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  _VehicleAttachmentsScreenState createState() => _VehicleAttachmentsScreenState();
}

class _VehicleAttachmentsScreenState extends State<VehicleAttachmentsScreen> {
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() => _isLoading = true);
    try {
      // Mock data for demo
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _attachments = [
          {'id': 1, 'attachment_type': 'stnk', 'file_name': 'stnk.jpg'},
          {'id': 2, 'attachment_type': 'bpkb', 'file_name': 'bpkb.jpg'},
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dokumen Kendaraan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttachments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Vehicle Info Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicleName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  'ID: ${widget.vehicleId}',
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ],
            ),
          ),
          
          // Upload Section
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _showUploadDialog,
                    icon: _isUploading 
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.upload_file),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload Dokumen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Attachments List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _attachments.isEmpty
                    ? _buildEmptyState()
                    : _buildAttachmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_file_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Belum Ada Dokumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload dokumen kendaraan untuk melengkapi data',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showUploadDialog,
            icon: Icon(Icons.upload_file),
            label: Text('Upload Dokumen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList() {
    // Group attachments by type
    final groupedAttachments = <String, List<Map<String, dynamic>>>{};
    for (final attachment in _attachments) {
      final type = attachment['attachment_type'];
      if (!groupedAttachments.containsKey(type)) {
        groupedAttachments[type] = [];
      }
      groupedAttachments[type]!.add(attachment);
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Required Documents Section
        _buildDocumentSection('Dokumen Wajib', [
          'stnk',
          'bpkb',
          'uji_kir',
          'asuransi',
        ], groupedAttachments),
        
        SizedBox(height: 16),
        
        // Photos Section
        _buildDocumentSection('Foto Kendaraan', [
          'foto_depan',
          'foto_belakang',
          'foto_samping',
        ], groupedAttachments),
      ],
    );
  }

  Widget _buildDocumentSection(
    String title,
    List<String> types,
    Map<String, List<Map<String, dynamic>>> groupedAttachments,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            ...types.map((type) => _buildDocumentItem(type, groupedAttachments[type])),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String type, List<Map<String, dynamic>>? attachments) {
    final hasAttachment = attachments != null && attachments.isNotEmpty;
    final attachment = hasAttachment ? attachments!.first : null;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasAttachment ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasAttachment ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasAttachment ? Icons.check_circle : Icons.radio_button_unchecked,
            color: hasAttachment ? Colors.green[600] : Colors.grey[400],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAttachmentTypeLabel(type),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: hasAttachment ? Colors.green[800] : Colors.grey[700],
                  ),
                ),
                if (hasAttachment) ...[
                  SizedBox(height: 4),
                  Text(
                    attachment!['file_name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasAttachment) ...[
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue[600]),
              onPressed: () => _viewAttachment(attachment!),
              tooltip: 'Lihat',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[600]),
              onPressed: () => _deleteAttachment(attachment!),
              tooltip: 'Hapus',
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.upload, color: Colors.blue[600]),
              onPressed: () => _showUploadDialog(preselectedType: type),
              tooltip: 'Upload',
            ),
          ],
        ],
      ),
    );
  }

  void _showUploadDialog({String? preselectedType}) {
    String selectedType = preselectedType ?? _getAttachmentTypes().first;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Dokumen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Jenis Dokumen',
                border: OutlineInputBorder(),
              ),
              items: _getAttachmentTypes().map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getAttachmentTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) => selectedType = value!,
            ),
            SizedBox(height: 16),
            Text(
              'Format yang didukung: JPEG, PNG, PDF\nUkuran maksimal: 10MB',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
              Navigator.pop(context);
              _pickAndUploadFile(selectedType);
            },
            child: Text('Pilih File'),
          ),
        ],
      ),
    );
  }

  void _pickAndUploadFile(String attachmentType) async {
    setState(() => _isUploading = true);
    try {
      // Mock upload
      await Future.delayed(Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dokumen berhasil diupload!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAttachments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }



  void _viewAttachment(Map<String, dynamic> attachment) async {
    try {
      // Get file data from backend
      final fileName = attachment['file_name'];
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/files/$fileName'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['type'] == 'base64') {
          // Show image dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Container(
                constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      title: Text('Dokumen'),
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              attachment['file_name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Image.memory(
                              base64Decode(data['data'].split(',')[1]),
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to simple dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Dokumen'),
          content: Text('File: ${attachment['file_name']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteAttachment(Map<String, dynamic> attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Dokumen'),
        content: Text('Apakah Anda yakin ingin menghapus dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mock delete
        await Future.delayed(Duration(seconds: 1));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadAttachments(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getAttachmentTypes() {
    return ['stnk', 'bpkb', 'uji_kir', 'asuransi', 'foto_depan', 'foto_belakang', 'foto_samping'];
  }

  String _getAttachmentTypeLabel(String type) {
    switch (type) {
      case 'stnk': return 'STNK';
      case 'bpkb': return 'BPKB';
      case 'uji_kir': return 'Uji KIR';
      case 'asuransi': return 'Asuransi';
      case 'foto_depan': return 'Foto Depan';
      case 'foto_belakang': return 'Foto Belakang';
      case 'foto_samping': return 'Foto Samping';
      default: return type;
    }
  }
}