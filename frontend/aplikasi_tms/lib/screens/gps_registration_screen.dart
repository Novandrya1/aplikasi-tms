import 'package:flutter/material.dart';
import '../models/gps_registration.dart';
import '../services/gps_service.dart';

class GPSRegistrationScreen extends StatefulWidget {
  const GPSRegistrationScreen({super.key});

  @override
  State<GPSRegistrationScreen> createState() => _GPSRegistrationScreenState();
}

class _GPSRegistrationScreenState extends State<GPSRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedVehicleType = 'truk_kecil';
  int _selectedCapacity = 2;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'truk_kecil', 'label': 'Truk Kecil'},
    {'value': 'truk_besar', 'label': 'Truk Besar'},
    {'value': 'trailer', 'label': 'Trailer'},
  ];

  final List<int> _capacityOptions = [2, 5, 10, 15, 20, 25, 30];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi GPS Armada'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 48,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Formulir Registrasi GPS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lengkapi informasi armada untuk registrasi GPS',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Form Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Registration Number
                        TextFormField(
                          controller: _registrationController,
                          decoration: InputDecoration(
                            labelText: 'Nomor Registrasi Kendaraan',
                            hintText: 'Contoh: B 1234 ABC',
                            prefixIcon: const Icon(Icons.directions_car),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor registrasi harus diisi';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Vehicle Type
                        DropdownButtonFormField<String>(
                          value: _selectedVehicleType,
                          decoration: InputDecoration(
                            labelText: 'Jenis Armada',
                            prefixIcon: const Icon(Icons.local_shipping),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _vehicleTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type['value'],
                              child: Text(type['label']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicleType = value!;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Capacity
                        DropdownButtonFormField<int>(
                          value: _selectedCapacity,
                          decoration: InputDecoration(
                            labelText: 'Kapasitas Muatan (Ton)',
                            prefixIcon: const Icon(Icons.scale),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _capacityOptions.map((capacity) {
                            return DropdownMenuItem<int>(
                              value: capacity,
                              child: Text('$capacity Ton'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCapacity = value!;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Catatan Operator (Opsional)',
                            hintText: 'Informasi tambahan tentang kendaraan...',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Ajukan Registrasi GPS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final request = GPSRegistrationRequest(
          registrationNumber: _registrationController.text,
          vehicleType: _selectedVehicleType,
          capacityTons: _selectedCapacity,
          operatorNotes: _notesController.text,
        );

        await GPSService.createRegistration(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi GPS berhasil diajukan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}