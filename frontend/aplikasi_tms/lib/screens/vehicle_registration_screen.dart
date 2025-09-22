import 'package:flutter/material.dart';
import '../models/fleet_models.dart';
import '../services/fleet_service.dart';
import '../services/file_service.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  @override
  _VehicleRegistrationScreenState createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _basicFormKey = GlobalKey<FormState>();
  final _technicalFormKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _regNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _colorController = TextEditingController();
  final _capacityWeightController = TextEditingController();
  final _capacityVolumeController = TextEditingController();
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();

  String _selectedVehicleType = 'Truk';
  String _selectedOwnershipStatus = 'Milik Sendiri';
  
  // Uploaded files
  Map<String, dynamic>? _bpkbFile;
  Map<String, dynamic>? _stnkFile;
  List<Map<String, dynamic>> _vehiclePhotos = [];

  final List<String> _vehicleTypes = [
    'Truk', 'Bus', 'Mobil Box', 'Pick Up', 'Motor', 'Trailer'
  ];

  final List<String> _ownershipStatuses = [
    'Milik Sendiri', 'Sewa', 'Leasing'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Kendaraan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tambahkan kendaraan ke armada Anda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Indicator
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    _buildProgressStep(0, 'Info Dasar'),
                    Expanded(child: Container(height: 2, color: _currentStep > 0 ? Colors.white : Colors.white30)),
                    _buildProgressStep(1, 'Info Teknis'),
                    Expanded(child: Container(height: 2, color: _currentStep > 1 ? Colors.white : Colors.white30)),
                    _buildProgressStep(2, 'Dokumen'),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: _buildCurrentStep(),
                        ),
                      ),
                      _buildBottomButtons(),
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

  Widget _buildProgressStep(int step, String title) {
    bool isActive = _currentStep >= step;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white30,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${step + 1}',
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildTechnicalInfoStep();
      case 2:
        return _buildDocumentStep();
      default:
        return _buildBasicInfoStep();
    }
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _basicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Dasar Kendaraan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          
          _buildTextField(
            controller: _regNumberController,
            label: 'Nomor Registrasi (Plat)',
            icon: Icons.confirmation_number,
            required: true,
          ),
          SizedBox(height: 16),
          
          _buildDropdown(
            value: _selectedVehicleType,
            label: 'Jenis Kendaraan',
            icon: Icons.directions_car,
            items: _vehicleTypes,
            onChanged: (value) => setState(() => _selectedVehicleType = value!),
          ),
          SizedBox(height: 16),
          
          _buildTextField(
            controller: _brandController,
            label: 'Merek/Pabrikan',
            icon: Icons.business,
            required: true,
          ),
          SizedBox(height: 16),
          
          _buildTextField(
            controller: _modelController,
            label: 'Model/Tipe',
            icon: Icons.category,
            required: true,
          ),
          SizedBox(height: 16),
          
          _buildTextField(
            controller: _yearController,
            label: 'Tahun Pembuatan',
            icon: Icons.calendar_today,
            required: true,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Wajib diisi';
              final year = int.tryParse(value!);
              if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                return 'Tahun tidak valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfoStep() {
    return Form(
      key: _technicalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Teknis Kendaraan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          
          _buildTextField(
            controller: _chassisController,
            label: 'Nomor Rangka/Chassis',
            icon: Icons.settings,
            required: true,
          ),
          SizedBox(height: 16),
          
          _buildTextField(
            controller: _engineController,
            label: 'Nomor Mesin',
            icon: Icons.build,
            required: true,
          ),
          SizedBox(height: 16),
          
          _buildTextField(
            controller: _colorController,
            label: 'Warna Kendaraan',
            icon: Icons.palette,
            required: true,
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _capacityWeightController,
                  label: 'Kapasitas Berat (Ton)',
                  icon: Icons.fitness_center,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _capacityVolumeController,
                  label: 'Kapasitas Volume (m³)',
                  icon: Icons.all_inbox,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildDropdown(
            value: _selectedOwnershipStatus,
            label: 'Status Kepemilikan',
            icon: Icons.account_balance,
            items: _ownershipStatuses,
            onChanged: (value) => setState(() => _selectedOwnershipStatus = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Dokumen Kendaraan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 20),
        
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildUploadCard(
                'Foto BPKB',
                'Upload foto BPKB yang jelas dan terbaca',
                Icons.description,
                () => _uploadFile('BPKB'),
                _bpkbFile,
              ),
              SizedBox(height: 12),
              
              _buildUploadCard(
                'Foto STNK',
                'Upload foto STNK bagian depan dan belakang',
                Icons.credit_card,
                () => _uploadFile('STNK'),
                _stnkFile,
              ),
              SizedBox(height: 12),
              
              _buildUploadCard(
                'Foto Kendaraan',
                'Upload foto kendaraan dari berbagai sudut (${_vehiclePhotos.length} foto)',
                Icons.camera_alt,
                () => _uploadFile('Foto Kendaraan'),
                _vehiclePhotos.isNotEmpty ? _vehiclePhotos.first : null,
                showMultiple: _vehiclePhotos.length > 1,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Asuransi (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              
              _buildTextField(
                controller: _insuranceCompanyController,
                label: 'Perusahaan Asuransi',
                icon: Icons.business,
              ),
              SizedBox(height: 16),
              
              _buildTextField(
                controller: _insurancePolicyController,
                label: 'Nomor Polis',
                icon: Icons.policy,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      // Remove validator to avoid form validation conflicts
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildUploadCard(String title, String subtitle, IconData icon, VoidCallback onTap, Map<String, dynamic>? uploadedFile, {bool showMultiple = false}) {
    bool hasFile = uploadedFile != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: hasFile ? Colors.green[300]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: hasFile ? Colors.green[50] : Colors.grey[50],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFile ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasFile ? Icons.check_circle : icon, 
                color: hasFile ? Colors.green : Colors.blue, 
                size: 20
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    hasFile 
                        ? '${uploadedFile['name']} (${FileService.formatFileSize(uploadedFile['size'])})${showMultiple ? ' +${_vehiclePhotos.length - 1} lainnya' : ''}'
                        : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.edit : Icons.cloud_upload, 
              color: hasFile ? Colors.green[400] : Colors.grey[400]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Kembali'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_currentStep < 2 ? _nextStep : _registerVehicle),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < 2 ? Colors.blue : Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mendaftar...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _currentStep < 2 ? 'Lanjut' : 'Daftar Kendaraan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    // Skip form validation, just move to next step
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _uploadFile(String documentType) async {
    final choice = await _showUploadChoiceDialog(documentType);
    if (choice == null) return;
    
    try {
      Map<String, dynamic>? file;
      
      // Mock file upload for compatibility
      file = {
        'name': 'mock_file_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'size': 1024,
        'type': 'image/jpeg',
      };
      
      if (file != null) {
        setState(() {
          switch (documentType) {
            case 'BPKB':
              _bpkbFile = file;
              break;
            case 'STNK':
              _stnkFile = file;
              break;
            case 'Foto Kendaraan':
              if (file != null) _vehiclePhotos.add(file);
              break;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${choice == 'camera' ? 'Foto' : 'File'} ${file['name']} berhasil diupload'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<String?> _showUploadChoiceDialog(String documentType) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload $documentType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih sumber untuk upload $documentType:'),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    'Kamera',
                    Icons.camera_alt,
                    Colors.blue,
                    () => Navigator.pop(context, 'camera'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceButton(
                    'File/Galeri',
                    Icons.folder,
                    Colors.green,
                    () => Navigator.pop(context, 'file'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChoiceButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerVehicle() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Memvalidasi data...'),
          ],
        ),
      ),
    );
    
    // Small delay to show the dialog
    await Future.delayed(Duration(milliseconds: 500));
    
    // Check required fields manually
    List<String> missingFields = [];
    
    if (_regNumberController.text.trim().isEmpty) missingFields.add('Nomor Registrasi');
    if (_brandController.text.trim().isEmpty) missingFields.add('Merek');
    if (_modelController.text.trim().isEmpty) missingFields.add('Model');
    if (_yearController.text.trim().isEmpty) missingFields.add('Tahun');
    if (_chassisController.text.trim().isEmpty) missingFields.add('Nomor Rangka');
    if (_engineController.text.trim().isEmpty) missingFields.add('Nomor Mesin');
    if (_colorController.text.trim().isEmpty) missingFields.add('Warna');
    
    // Close loading dialog
    Navigator.pop(context);
    
    if (missingFields.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Validasi Gagal'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Field berikut wajib diisi:'),
              SizedBox(height: 8),
              ...missingFields.map((field) => Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• $field', style: TextStyle(color: Colors.red)),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Validate year
    final year = int.tryParse(_yearController.text.trim());
    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Tahun Tidak Valid'),
            ],
          ),
          content: Text('Tahun harus berupa angka antara 1900 dan ${DateTime.now().year + 1}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vehicle = VehicleRegistration(
        registrationNumber: _regNumberController.text,
        vehicleType: _selectedVehicleType,
        brand: _brandController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        chassisNumber: _chassisController.text,
        engineNumber: _engineController.text,
        color: _colorController.text,
        capacityWeight: _capacityWeightController.text.isNotEmpty
            ? double.tryParse(_capacityWeightController.text)
            : null,
        capacityVolume: _capacityVolumeController.text.isNotEmpty
            ? double.tryParse(_capacityVolumeController.text)
            : null,
        ownershipStatus: _selectedOwnershipStatus,
        insuranceCompany: _insuranceCompanyController.text.isNotEmpty
            ? _insuranceCompanyController.text
            : null,
        insurancePolicyNumber: _insurancePolicyController.text.isNotEmpty
            ? _insurancePolicyController.text
            : null,
        insuranceExpiryDate: null,
        maintenanceNotes: null,
      );

      await FleetService.registerVehicle(vehicle);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange),
              SizedBox(width: 8),
              Text('Sedang Diverifikasi'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kendaraan berhasil didaftarkan!'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status: Sedang Diverifikasi',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Mohon tunggu 24 jam',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tim verifikasi kami akan meninjau dokumen dan data kendaraan Anda. Proses verifikasi membutuhkan waktu maksimal 24 jam.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text('Mengerti'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Registrasi Gagal'),
            ],
          ),
          content: Text('Error: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _colorController.dispose();
    _capacityWeightController.dispose();
    _capacityVolumeController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    super.dispose();
  }
}