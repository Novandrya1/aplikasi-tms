import 'package:flutter/material.dart';

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

  final _regNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();

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
        return _buildFormStep();
      case 1:
        return _buildDocumentStep();
      case 2:
        return _buildWaitingStep();
      default:
        return _buildFormStep();
    }
  }

  Widget _buildFormStep() {
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
          _buildTextField(_regNumberController, 'Nomor Polisi', Icons.confirmation_number),
          _buildTextField(_brandController, 'Merek Kendaraan', Icons.directions_car),
          _buildTextField(_modelController, 'Model/Tipe', Icons.category),
          _buildYearPicker(),
          _buildTextField(_colorController, 'Warna', Icons.palette),
          _buildTextField(_chassisController, 'Nomor Rangka', Icons.confirmation_number),
          _buildTextField(_engineController, 'Nomor Mesin', Icons.build),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validateAndNext,
              child: Text('Lanjut ke Upload Dokumen'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Upload Dokumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          _buildDocumentItem('STNK'),
          _buildDocumentItem('BPKB'),
          _buildDocumentItem('Foto Kendaraan'),
          SizedBox(height: 20),
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
                  onPressed: _submitRegistration,
                  child: Text('Submit'),
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
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[600]),
          SizedBox(height: 30),
          Text('Registrasi Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Data kendaraan telah dikirim ke admin'),
          SizedBox(height: 40),
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
                  child: Text('Daftar Lagi'),
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

  Widget _buildDocumentItem(String title) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.upload_file),
        title: Text(title),
        trailing: Icon(Icons.add_circle_outline, color: Colors.green),
        onTap: () => _showUploadDialog(title),
      ),
    );
  }

  void _validateAndNext() {
    if (_regNumberController.text.trim().isEmpty ||
        _brandController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon lengkapi semua field yang wajib'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
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

  void _showUploadDialog(String docType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload $docType'),
        content: Text('Fitur upload dokumen akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitRegistration() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _vehicleId = 'VH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        _currentStep = 2;
        _isLoading = false;
      });
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
      _regNumberController.clear();
      _brandController.clear();
      _modelController.clear();
      _colorController.clear();
      _chassisController.clear();
      _engineController.clear();
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
    super.dispose();
  }
}