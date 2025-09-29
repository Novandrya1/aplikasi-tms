import 'package:flutter/material.dart';
import '../models/gps_registration.dart';
import '../services/gps_service.dart';
import '../services/auth_service.dart';

class AdminGPSApprovalScreen extends StatefulWidget {
  const AdminGPSApprovalScreen({super.key});

  @override
  State<AdminGPSApprovalScreen> createState() => _AdminGPSApprovalScreenState();
}

class _AdminGPSApprovalScreenState extends State<AdminGPSApprovalScreen> {
  List<GPSRegistration> _pendingRegistrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRegistrations();
  }

  Future<void> _loadPendingRegistrations() async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final registrations = await GPSService.getPendingRegistrations(token);
        setState(() {
          _pendingRegistrations = registrations;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Registrasi GPS'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingRegistrations.isEmpty
                ? _buildEmptyState()
                : _buildRegistrationsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada registrasi GPS yang menunggu persetujuan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsList() {
    return RefreshIndicator(
      onRefresh: _loadPendingRegistrations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRegistrations.length,
        itemBuilder: (context, index) {
          final registration = _pendingRegistrations[index];
          return _buildRegistrationCard(registration);
        },
      ),
    );
  }

  Widget _buildRegistrationCard(GPSRegistration registration) {
    return Card(
      elevation: 4,
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    color: Colors.orange[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.registrationNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getVehicleTypeLabel(registration.vehicleType),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Kapasitas',
                    '${registration.capacityTons} Ton',
                    Icons.scale,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tanggal',
                    _formatDate(registration.createdAt),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            if (registration.operatorNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Operator:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registration.operatorNotes,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(registration, 'approved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(registration, 'rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showApprovalDialog(GPSRegistration registration, String action) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            action == 'approved' ? 'Setujui Registrasi GPS' : 'Tolak Registrasi GPS',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nomor Registrasi: ${registration.registrationNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Admin',
                  hintText: 'Masukkan catatan untuk keputusan ini...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => _processApproval(registration, action, notesController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(action == 'approved' ? 'Setujui' : 'Tolak'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processApproval(GPSRegistration registration, String action, String notes) async {
    Navigator.of(context).pop();
    
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        await GPSService.approveRegistration(registration.id, action, notes, token);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'approved' 
                    ? 'Registrasi GPS berhasil disetujui'
                    : 'Registrasi GPS berhasil ditolak',
              ),
              backgroundColor: action == 'approved' ? Colors.green : Colors.orange,
            ),
          );
          
          _loadPendingRegistrations();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getVehicleTypeLabel(String type) {
    switch (type) {
      case 'truck':
        return 'Truk';
      case 'trailer':
        return 'Trailer';
      case 'container':
        return 'Container';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}