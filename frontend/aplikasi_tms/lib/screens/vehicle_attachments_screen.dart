import 'package:flutter/material.dart';

class VehicleAttachmentsScreen extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const VehicleAttachmentsScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<VehicleAttachmentsScreen> createState() => _VehicleAttachmentsScreenState();
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
      setState(() {
        _attachments = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumen Kendaraan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttachments,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _showUploadDialog,
                    icon: _isUploading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload Dokumen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
          const SizedBox(height: 16),
          Text(
            'Belum Ada Dokumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload dokumen kendaraan untuk melengkapi data',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Dokumen'),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dokumen Kendaraan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDocumentItem('STNK', null),
                _buildDocumentItem('BPKB', null),
                _buildDocumentItem('Uji KIR', null),
                _buildDocumentItem('Asuransi', null),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String label, Map<String, dynamic>? attachment) {
    final hasAttachment = attachment != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasAttachment ? Colors.green[800] : Colors.grey[700],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.upload, color: Colors.blue[600]),
            onPressed: _showUploadDialog,
            tooltip: 'Upload',
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Dokumen'),
        content: const Text('Fitur upload akan diimplementasikan dengan backend.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}