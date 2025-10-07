import 'package:flutter/material.dart';
import '../services/vehicle_verification_service.dart';

class InspectionOperatorScreen extends StatefulWidget {
  const InspectionOperatorScreen({super.key});

  @override
  State<InspectionOperatorScreen> createState() => _InspectionOperatorScreenState();
}

class _InspectionOperatorScreenState extends State<InspectionOperatorScreen> {
  List<Map<String, dynamic>> _scheduledInspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledInspections();
  }

  void _loadScheduledInspections() {
    setState(() {
      _scheduledInspections = VehicleVerificationService().getVerificationsByStatus('inspection_scheduled');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspeksi Kendaraan'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadScheduledInspections(),
              child: _scheduledInspections.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Tidak ada inspeksi terjadwal'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _scheduledInspections.length,
                      itemBuilder: (context, index) {
                        final inspection = _scheduledInspections[index];
                        final vehicleData = inspection['vehicleData'] as Map<String, dynamic>;
                        return _buildInspectionCard(inspection, vehicleData);
                      },
                    ),
            ),
    );
  }

  Widget _buildInspectionCard(Map<String, dynamic> inspection, Map<String, dynamic> vehicleData) {
    final inspectionDate = inspection['inspectionDate'] != null 
        ? DateTime.parse(inspection['inspectionDate']) 
        : null;
    
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.blue),
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
              ],
            ),
            const SizedBox(height: 16),
            
            if (inspectionDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Jadwal: ${_formatDate(inspectionDate)}'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            Text('Pemilik: ${vehicleData['owner_name']}'),
            Text('Catatan: ${inspection['notes'] ?? 'Tidak ada catatan'}'),
            
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showVehicleDetails(inspection, vehicleData),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _startInspection(inspection['id'], vehicleData),
                  icon: const Icon(Icons.assignment, size: 16),
                  label: const Text('Mulai Inspeksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  void _showVehicleDetails(Map<String, dynamic> inspection, Map<String, dynamic> vehicleData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Kendaraan - ${vehicleData['registration_number']}'),
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

  void _startInspection(String verificationId, Map<String, dynamic> vehicleData) {
    showDialog(
      context: context,
      builder: (context) => _InspectionFormDialog(
        verificationId: verificationId,
        vehicleData: vehicleData,
        onCompleted: () {
          _loadScheduledInspections();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inspeksi berhasil diselesaikan'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String _engineCondition = 'Baik';
  String _bodyCondition = 'Baik';
  String _tireCondition = 'Baik';
  String _documentCompleteness = 'Lengkap';
  String _recommendation = 'Disetujui';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text('Inspeksi - ${widget.vehicleData['registration_number']}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Form Inspeksi Kendaraan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField('Kondisi Mesin', _engineCondition, (value) {
                        setState(() => _engineCondition = value!);
                      }),
                      
                      _buildDropdownField('Kondisi Body', _bodyCondition, (value) {
                        setState(() => _bodyCondition = value!);
                      }),
                      
                      _buildDropdownField('Kondisi Ban', _tireCondition, (value) {
                        setState(() => _tireCondition = value!);
                      }),
                      
                      _buildDropdownField('Kelengkapan Dokumen', _documentCompleteness, (value) {
                        setState(() => _documentCompleteness = value!);
                      }, ['Lengkap', 'Tidak Lengkap']),
                      
                      _buildDropdownField('Rekomendasi', _recommendation, (value) {
                        setState(() => _recommendation = value!);
                      }, ['Disetujui', 'Perlu Perbaikan', 'Ditolak']),
                      
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Inspeksi',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Catatan inspeksi wajib diisi';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitInspection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Selesaikan Inspeksi'),
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
    );
  }

  Widget _buildDropdownField(String label, String value, ValueChanged<String?> onChanged, [List<String>? options]) {
    final items = options ?? ['Baik', 'Cukup', 'Buruk'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _submitInspection() {
    if (_formKey.currentState!.validate()) {
      final inspectionReport = {
        'inspector': 'Operator Inspeksi',
        'date': DateTime.now().toIso8601String(),
        'engine_condition': _engineCondition,
        'body_condition': _bodyCondition,
        'tire_condition': _tireCondition,
        'document_completeness': _documentCompleteness,
        'recommendation': _recommendation,
        'notes': _notesController.text.trim(),
      };

      VehicleVerificationService().completeInspection(
        widget.verificationId,
        inspectionReport,
        'Operator Inspeksi',
      );

      Navigator.pop(context);
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}