import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/vehicle_data_service.dart';
import '../services/vehicle_verification_service.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _vehicleId;
  DateTime? _selectedYear;
  String _ownershipType = 'personal';
  
  // Controllers
  final _regNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  
  final Map<String, String?> _uploadedDocs = {
    'stnk': null,
    'bpkb': null,
    'ktp': null,
    'vehicle_photo': null,
  };
  
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi Kendaraan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildOwnershipStep();
      case 1:
        return _buildVehicleInfoStep();
      case 2:
        return _buildDocumentStep();
      case 3:
        return _buildConfirmationStep();
      case 4:
        return _buildWaitingStep();
      default:
        return _buildOwnershipStep();
    }
  }

  Widget _buildOwnershipStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jenis Kepemilikan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: RadioListTile<String>(
              value: 'personal',
              groupValue: _ownershipType,
              onChanged: (value) => setState(() => _ownershipType = value!),
              title: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Milik Pribadi'),
                ],
              ),
              subtitle: Text('Kendaraan atas nama pribadi'),
            ),
          ),
          Card(
            child: RadioListTile<String>(
              value: 'company',
              groupValue: _ownershipType,
              onChanged: (value) => setState(() => _ownershipType = value!),
              title: Row(
                children: [
                  Icon(Icons.business, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Milik Perusahaan'),
                ],
              ),
              subtitle: Text('Kendaraan atas nama perusahaan'),
            ),
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: Text('Lanjut ke Data Kendaraan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Kendaraan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildTextField(_regNumberController, 'Nomor Polisi *', Icons.confirmation_number),
          _buildTextField(_brandController, 'Merek Kendaraan *', Icons.directions_car),
          _buildTextField(_modelController, 'Model/Tipe *', Icons.category),
          _buildYearPicker(),
          _buildTextField(_colorController, 'Warna', Icons.palette),
          _buildTextField(_chassisController, 'Nomor Rangka', Icons.confirmation_number),
          _buildTextField(_engineController, 'Nomor Mesin', Icons.build),
          
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 16),
          
          Text(
            _ownershipType == 'personal' ? 'Data Pemilik' : 'Data Perusahaan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          if (_ownershipType == 'personal') ...[
            _buildTextField(_ownerNameController, 'Nama Lengkap *', Icons.person),
            _buildTextField(_ownerEmailController, 'Email *', Icons.email),
            _buildTextField(_ownerPhoneController, 'Nomor Telepon', Icons.phone),
          ] else ...[
            _buildTextField(_companyNameController, 'Nama Perusahaan *', Icons.business),
            _buildTextField(_companyAddressController, 'Alamat Perusahaan', Icons.location_on),
            _buildTextField(_ownerNameController, 'Nama PIC *', Icons.person),
            _buildTextField(_ownerEmailController, 'Email PIC *', Icons.email),
            _buildTextField(_ownerPhoneController, 'Nomor Telepon PIC', Icons.phone),
          ],
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: Text('Kembali'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateAndNext,
                  child: Text('Lanjut ke Dokumen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Dokumen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload dokumen yang diperlukan untuk verifikasi kendaraan',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          
          _buildDocumentUpload('STNK', 'stnk', Icons.description, true),
          _buildDocumentUpload('BPKB', 'bpkb', Icons.book, true),
          _buildDocumentUpload('KTP Pemilik', 'ktp', Icons.credit_card, true),
          _buildDocumentUpload('Foto Kendaraan', 'vehicle_photo', Icons.camera_alt, true),
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: Text('Kembali'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateDocuments,
                  child: Text('Lanjut ke Konfirmasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfirmasi Data',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 32),
                SizedBox(height: 12),
                Text(
                  'Proses Verifikasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Setelah mengirim registrasi, tim kami akan melakukan:\n\n• Verifikasi dokumen (1-2 hari kerja)\n• Inspeksi kendaraan (jika diperlukan)\n• Konfirmasi persetujuan\n\nAnda akan mendapat notifikasi melalui email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: Text('Kembali'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitRegistration,
                  child: Text('Kirim Registrasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 80, color: Colors.green[600]),
          ),
          SizedBox(height: 30),
          Text(
            'Registrasi Berhasil Dikirim!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'ID Registrasi: $_vehicleId',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.schedule, color: Colors.blue[600], size: 32),
                SizedBox(height: 12),
                Text(
                  'Proses Selanjutnya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '• Verifikasi dokumen: 1-2 hari kerja\n• Inspeksi kendaraan: 2-3 hari kerja\n• Konfirmasi hasil: 1 hari kerja\n\nTotal estimasi: 3-5 hari kerja',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Kembali ke Dashboard'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _registerAnother,
                  child: Text('Daftar Kendaraan Lain'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildYearPicker() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _selectYear,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedYear != null ? 'Tahun: ${_selectedYear!.year}' : 'Pilih Tahun Kendaraan',
                ),
              ),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String title, String key, IconData icon, bool required) {
    final isUploaded = _uploadedDocs[key] != null;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUploaded ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isUploaded ? Icons.check_circle : icon,
                color: isUploaded ? Colors.green[600] : Colors.grey[600],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title + (required ? ' *' : ''),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isUploaded)
                    Text(
                      'Dokumen berhasil diupload',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showImageSourceDialog(key),
              icon: Icon(isUploaded ? Icons.edit : Icons.camera_alt, size: 16),
              label: Text(isUploaded ? 'Ganti' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUploaded ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndNext() {
    if (_regNumberController.text.trim().isEmpty ||
        _brandController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty ||
        _selectedYear == null) {
      _showError('Mohon lengkapi semua field kendaraan yang wajib');
      return;
    }
    
    if (_ownerNameController.text.trim().isEmpty ||
        _ownerEmailController.text.trim().isEmpty) {
      _showError('Mohon lengkapi data pemilik yang wajib');
      return;
    }
    
    if (_ownershipType == 'company' && _companyNameController.text.trim().isEmpty) {
      _showError('Mohon lengkapi nama perusahaan');
      return;
    }
    
    setState(() => _currentStep = 2);
  }

  void _validateDocuments() {
    final requiredDocs = ['stnk', 'bpkb', 'ktp', 'vehicle_photo'];
    final missingDocs = requiredDocs.where((doc) => _uploadedDocs[doc] == null).toList();
    
    if (missingDocs.isNotEmpty) {
      _showError('Mohon upload semua dokumen yang diperlukan');
      return;
    }
    
    setState(() => _currentStep = 3);
  }

  void _selectYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _selectedYear = picked);
    }
  }

  void _showImageSourceDialog(String docKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(docKey, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(docKey, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String docKey, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _uploadedDocs[docKey] = image.path;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getDocumentTitle(docKey)} berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Gagal mengupload gambar: $e');
    }
  }

  String _getDocumentTitle(String key) {
    switch (key) {
      case 'stnk': return 'STNK';
      case 'bpkb': return 'BPKB';
      case 'ktp': return 'KTP Pemilik';
      case 'vehicle_photo': return 'Foto Kendaraan';
      default: return key;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _submitRegistration() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(Duration(seconds: 2));
      
      final vehicleData = {
        'id': 'VH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'registration_number': _regNumberController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': _selectedYear?.year.toString() ?? '',
        'color': _colorController.text.trim(),
        'chassis_number': _chassisController.text.trim(),
        'engine_number': _engineController.text.trim(),
        'ownership_type': _ownershipType,
        'owner_name': _ownerNameController.text.trim(),
        'owner_email': _ownerEmailController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
        'company_name': _ownershipType == 'company' ? _companyNameController.text.trim() : null,
        'company_address': _ownershipType == 'company' ? _companyAddressController.text.trim() : null,
        'documents': _uploadedDocs,
        'verification_status': 'pending',
        'verification_substatus': 'document_review',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      VehicleDataService.saveVehicle(vehicleData);
      
      // Add to verification queue
      VehicleVerificationService().addVerificationRequest(vehicleData);
      
      setState(() {
        _vehicleId = vehicleData['id'] as String?;
        _currentStep = 4;
        _isLoading = false;
      });
      
      html.window.dispatchEvent(html.CustomEvent('vehicle_registered'));
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim data: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _registerAnother() {
    setState(() {
      _currentStep = 0;
      _vehicleId = null;
      _selectedYear = null;
      _ownershipType = 'personal';
      
      _regNumberController.clear();
      _brandController.clear();
      _modelController.clear();
      _colorController.clear();
      _chassisController.clear();
      _engineController.clear();
      _ownerNameController.clear();
      _ownerEmailController.clear();
      _ownerPhoneController.clear();
      _companyNameController.clear();
      _companyAddressController.clear();
      
      _uploadedDocs.clear();
      _uploadedDocs.addAll({
        'stnk': null,
        'bpkb': null,
        'ktp': null,
        'vehicle_photo': null,
      });
    });
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }
}