import 'package:flutter/material.dart';
import '../models/fleet_models.dart';
import '../services/fleet_service.dart';
import '../services/file_upload_service.dart';

class FleetRegistrationScreen extends StatefulWidget {
  @override
  _FleetRegistrationScreenState createState() => _FleetRegistrationScreenState();
}

class _FleetRegistrationScreenState extends State<FleetRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String _selectedType = '';
  bool _isLoading = false;
  
  // Form keys
  final _ownerFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
  
  // Owner data controllers
  final _nameController = TextEditingController();
  final _ktpController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _npwpController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  
  // Vehicle data controllers
  final _vehicleTypeController = TextEditingController();
  final _brandController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _colorController = TextEditingController();
  final _capacityController = TextEditingController();
  
  // Document files (placeholder)
  String? _ktpFile;
  String? _selfieFile;
  String? _stnkFile;
  String? _bpkbFile;
  String? _taxFile;
  String? _insuranceFile;
  String? _businessLicenseFile;
  String? _npwpFile;
  List<String> _vehiclePhotos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildProgressIndicator(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildTypeSelection(),
                            _buildOwnerDataForm(),
                            _buildVehicleDataForm(),
                            _buildDocumentUpload(),
                            _buildVerificationStep(),
                          ],
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
    );
  }

  Widget _buildHeader() {
    return Padding(
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
              onPressed: () => _confirmExit(),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrasi Armada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStepTitle(),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          bool isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Jenis Armada',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Pilih jenis registrasi armada sesuai dengan kepemilikan kendaraan Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          _buildTypeCard(
            'individual',
            '🚛 Armada Pribadi / Independen',
            'Pemilik individu ingin mendaftarkan kendaraan miliknya sendiri agar bisa digunakan dalam sistem',
            Icons.person,
          ),
          SizedBox(height: 16),
          _buildTypeCard(
            'company',
            '🏢 Armada Perusahaan / Mitra',
            'Perusahaan memiliki armada dan ingin mendaftarkan secara resmi untuk digunakan driver mereka',
            Icons.business,
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedType.isEmpty ? null : () => _nextStep(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Lanjutkan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, String title, String subtitle, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? Colors.blue : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerDataForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _ownerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedType == 'individual' ? 'Data Pemilik' : 'Data Perusahaan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  if (_selectedType == 'individual') ..._buildIndividualFields(),
                  if (_selectedType == 'company') ..._buildCompanyFields(),
                ],
              ),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _previousStep(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Kembali', style: TextStyle(color: Colors.blue)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_ownerFormKey.currentState!.validate()) {
                        _nextStep();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Lanjutkan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  List<Widget> _buildIndividualFields() {
    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Data Pribadi Pemilik Armada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Lengkapi data pribadi Anda sebagai pemilik kendaraan',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      _buildTextField(_nameController, 'Nama Lengkap', Icons.person, required: true),
      SizedBox(height: 16),
      _buildTextField(_ktpController, 'Nomor KTP/NIK', Icons.credit_card, required: true),
      SizedBox(height: 16),
      _buildTextField(_addressController, 'Alamat Domisili', Icons.location_on, maxLines: 3, required: true),
      SizedBox(height: 16),
      _buildTextField(_phoneController, 'Nomor Telepon', Icons.phone, keyboardType: TextInputType.phone, required: true),
      SizedBox(height: 16),
      _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress, required: true),
    ];
  }

  List<Widget> _buildCompanyFields() {
    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_outlined, color: Colors.green[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Data Perusahaan/Mitra',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Lengkapi data perusahaan dan penanggung jawab',
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      _buildTextField(_companyNameController, 'Nama Perusahaan', Icons.business, required: true),
      SizedBox(height: 16),
      _buildTextField(_npwpController, 'NPWP Perusahaan', Icons.receipt, required: true),
      SizedBox(height: 16),
      _buildTextField(_addressController, 'Alamat Kantor', Icons.location_on, maxLines: 3, required: true),
      SizedBox(height: 16),
      _buildTextField(_phoneController, 'Telepon Perusahaan', Icons.phone, keyboardType: TextInputType.phone, required: true),
      SizedBox(height: 16),
      _buildTextField(_emailController, 'Email Perusahaan', Icons.email, keyboardType: TextInputType.emailAddress, required: true),
      SizedBox(height: 16),
      _buildTextField(_nameController, 'Nama Penanggung Jawab', Icons.person, required: true),
      SizedBox(height: 16),
      _buildTextField(_businessLicenseController, 'Nomor SIUP/NIB (Izin Usaha)', Icons.assignment, required: true),
    ];
  }

  Widget _buildVehicleDataForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _vehicleFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Armada/Kendaraan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Masukkan detail lengkap kendaraan yang akan didaftarkan',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.orange[600], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Informasi Kendaraan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(_vehicleTypeController, 'Jenis Kendaraan (truk, pickup, van, dll)', Icons.local_shipping, required: true),
                  SizedBox(height: 16),
                  _buildTextField(_brandController, 'Merk & Tipe Kendaraan', Icons.directions_car, required: true),
                  SizedBox(height: 16),
                  _buildTextField(_yearController, 'Tahun Pembuatan', Icons.calendar_today, keyboardType: TextInputType.number, required: true),
                  SizedBox(height: 16),
                  _buildTextField(_plateController, 'Nomor Polisi (Plat)', Icons.confirmation_number, required: true),
                  SizedBox(height: 16),
                  _buildTextField(_chassisController, 'Nomor Rangka', Icons.settings, required: true),
                  SizedBox(height: 16),
                  _buildTextField(_engineController, 'Nomor Mesin', Icons.build, required: true),
                  SizedBox(height: 16),
                  _buildTextField(_colorController, 'Warna Kendaraan', Icons.palette, required: true),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_capacityController, 'Kapasitas Angkut (kg)', Icons.scale, keyboardType: TextInputType.number, required: true),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(TextEditingController(), 'Volume (m³)', Icons.straighten, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _previousStep(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Kembali', style: TextStyle(color: Colors.blue)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_vehicleFormKey.currentState!.validate()) {
                        _nextStep();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Lanjutkan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildDocumentUpload() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Dokumen',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                if (_selectedType == 'individual') ..._buildIndividualDocuments(),
                if (_selectedType == 'company') ..._buildCompanyDocuments(),
                SizedBox(height: 20),
                Text(
                  'Dokumen Kendaraan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ..._buildVehicleDocuments(),
              ],
            ),
          ),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _previousStep(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Kembali', style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceedToVerification() ? () => _nextStep() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIndividualDocuments() {
    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Dokumen Pemilik Pribadi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Upload dokumen identitas pemilik kendaraan',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      _buildDocumentUploadCard('Scan/Foto KTP', _ktpFile, (file) => setState(() => _ktpFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('Foto Selfie dengan KTP', _selfieFile, (file) => setState(() => _selfieFile = file), required: true),
      SizedBox(height: 20),
    ];
  }

  List<Widget> _buildCompanyDocuments() {
    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_outlined, color: Colors.green[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Dokumen Perusahaan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Upload dokumen legalitas perusahaan dan penanggung jawab',
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      _buildDocumentUploadCard('SIUP/NIB (Izin Usaha)', _businessLicenseFile, (file) => setState(() => _businessLicenseFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('NPWP Perusahaan', _npwpFile, (file) => setState(() => _npwpFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('KTP Penanggung Jawab', _ktpFile, (file) => setState(() => _ktpFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('Surat Kuasa (jika penanggung jawab bukan pemilik legal)', TextEditingController().text, (file) => {}, required: false),
      SizedBox(height: 20),
    ];
  }

  List<Widget> _buildVehicleDocuments() {
    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: Colors.orange[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Dokumen Kendaraan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Upload dokumen kepemilikan dan kelengkapan kendaraan',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      _buildDocumentUploadCard('Foto/Scan STNK', _stnkFile, (file) => setState(() => _stnkFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('Foto/Scan BPKB', _bpkbFile, (file) => setState(() => _bpkbFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('Bukti Pajak Kendaraan Terakhir', _taxFile, (file) => setState(() => _taxFile = file), required: true),
      SizedBox(height: 12),
      _buildDocumentUploadCard('Bukti Asuransi Kendaraan (Opsional)', _insuranceFile, (file) => setState(() => _insuranceFile = file)),
      SizedBox(height: 16),
      _buildVehiclePhotosUpload(),
    ];
  }

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verifikasi & Persetujuan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tahap akhir sebelum armada Anda aktif dalam sistem',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 48, color: Colors.green),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Siap Diverifikasi',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Semua data dan dokumen telah lengkap',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timeline, color: Colors.blue[600], size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Proses Verifikasi Dokumen:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildVerificationStepItem('1', 'Tim admin memeriksa keaslian dokumen'),
                      _buildVerificationStepItem('2', 'Sistem mengecek nomor rangka/plat tidak dobel'),
                      _buildVerificationStepItem('3', 'Verifikasi legalitas ${_selectedType == 'company' ? 'perusahaan' : 'pemilik'}'),
                      _buildVerificationStepItem('4', 'Notifikasi hasil verifikasi (1-3 hari kerja)'),
                      _buildVerificationStepItem('5', 'Aktivasi armada jika disetujui'),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green[600], size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Setelah Disetujui:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('✅ Armada masuk database armada aktif', style: TextStyle(fontSize: 13)),
                      Text('✅ Mendapat ID Armada unik dalam sistem', style: TextStyle(fontSize: 13)),
                      Text('✅ Dapat mengaktifkan/menonaktifkan armada', style: TextStyle(fontSize: 13)),
                      Text('✅ Siap menerima order transportasi', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _previousStep(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Kembali', style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Kirim Registrasi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStepItem(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (value) {
              if (value?.isEmpty ?? true) {
                return '$label wajib diisi';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDocumentUploadCard(
    String title,
    String? file,
    Function(String?) onFileSelected, {
    bool required = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: file != null ? Colors.green : Colors.grey[300]!,
          width: file != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: file != null ? Colors.green[50] : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  required ? '$title *' : title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: file != null ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                if (file != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'File berhasil dipilih',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ],
                  ),
                ] else if (required) ...[
                  SizedBox(height: 4),
                  Text(
                    'Dokumen wajib diupload',
                    style: TextStyle(fontSize: 12, color: Colors.red[600]),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _pickDocument(onFileSelected, title),
            icon: Icon(
              file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? Colors.green : Colors.blue,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotosUpload() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.purple[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.purple[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Foto Kendaraan (Depan, Samping, Belakang) *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _vehiclePhotos.length >= 3 ? Colors.green[700] : Colors.purple[800],
                  ),
                ),
              ),
              IconButton(
                onPressed: _pickVehiclePhoto,
                icon: Icon(
                  _vehiclePhotos.length >= 3 ? Icons.check_circle : Icons.add_a_photo,
                  color: _vehiclePhotos.length >= 3 ? Colors.green : Colors.purple[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Upload minimal 3 foto: tampak depan, samping, dan belakang kendaraan',
            style: TextStyle(fontSize: 12, color: Colors.purple[700]),
          ),
          if (_vehiclePhotos.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _vehiclePhotos.map((photo) {
                return Chip(
                  label: Text(photo, style: TextStyle(fontSize: 12)),
                  deleteIcon: Icon(Icons.close, size: 16),
                  backgroundColor: Colors.green[100],
                  onDeleted: () {
                    setState(() {
                      _vehiclePhotos.remove(photo);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Pilih jenis armada yang akan didaftarkan';
      case 1:
        return 'Lengkapi data ${_selectedType == 'individual' ? 'pemilik' : 'perusahaan'}';
      case 2:
        return 'Input data kendaraan yang dimiliki';
      case 3:
        return 'Upload dokumen yang diperlukan';
      case 4:
        return 'Verifikasi dan kirim registrasi';
      default:
        return 'Registrasi armada';
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Jika di step pertama, keluar dari registrasi
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDocument(Function(String?) onFileSelected, String title) async {
    try {
      final result = await FileUploadService.pickAndUploadFile(
        documentType: title.toLowerCase().replaceAll(' ', '_'),
        context: context,
        allowCamera: true,
      );
      if (result != null) {
        onFileSelected(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen berhasil diupload: $title'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showUploadDialog(String title) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih sumber file:'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                _buildUploadOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                _buildUploadOption(
                  icon: Icons.folder,
                  label: 'File',
                  onTap: () => Navigator.pop(context, 'file'),
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
    ).then((source) async {
      if (source != null) {
        return await _handleFileUpload(source, title);
      }
      return null;
    });
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<String?> _handleFileUpload(String source, String title) async {
    try {
      // For web compatibility, simulate file upload
      await Future.delayed(Duration(milliseconds: 500));
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final documentType = title.toLowerCase().replaceAll(' ', '_');
      
      return 'uploads/${documentType}_${timestamp}.jpg';
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> _pickVehiclePhoto() async {
    try {
      final result = await FileUploadService.pickAndUploadFile(
        documentType: 'vehicle_photo',
        context: context,
        allowCamera: true,
      );
      if (result != null) {
        setState(() {
          _vehiclePhotos.add(result);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto kendaraan berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _canProceedToVerification() {
    if (_selectedType == 'individual') {
      return _ktpFile != null && _selfieFile != null && _stnkFile != null && _bpkbFile != null && _taxFile != null && _vehiclePhotos.length >= 3;
    } else {
      return _businessLicenseFile != null && _npwpFile != null && _ktpFile != null && _stnkFile != null && _bpkbFile != null && _taxFile != null && _vehiclePhotos.length >= 3;
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      // Validate required fields
      if (_selectedType.isEmpty) {
        throw Exception('Pilih jenis armada terlebih dahulu');
      }
      
      if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
        throw Exception('Data pemilik belum lengkap');
      }
      
      if (_plateController.text.isEmpty || _brandController.text.isEmpty) {
        throw Exception('Data kendaraan belum lengkap');
      }

      // Register fleet owner first
      final fleetRequest = FleetOwnerRequest(
        companyName: _selectedType == 'company' ? _companyNameController.text : _nameController.text,
        businessLicense: _selectedType == 'company' ? _businessLicenseController.text : 'Individual',
        address: _addressController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
      );

      print('Sending fleet registration: ${fleetRequest.toJson()}');
      final fleetResult = await FleetService.registerFleetOwner(fleetRequest);
      print('Fleet registration successful: $fleetResult');

      // Register vehicle for verification
      final vehicleRequest = {
        'registration_number': _plateController.text,
        'vehicle_type': _vehicleTypeController.text,
        'brand': _brandController.text,
        'model': _brandController.text,
        'year': int.tryParse(_yearController.text) ?? 2020,
        'chassis_number': _chassisController.text,
        'engine_number': _engineController.text,
        'color': _colorController.text,
        'capacity_weight': double.tryParse(_capacityController.text) ?? 0.0,
        'capacity_volume': 0.0,
        'ownership_status': 'owned',
        'operational_status': 'pending_verification',
      };

      print('Sending vehicle registration: $vehicleRequest');
      await FleetService.registerVehicle(vehicleRequest);
      print('Vehicle registration successful');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi berhasil dikirim! Menunggu verifikasi admin.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmExit() async {
    if (_currentStep > 0) {
      // Jika sudah mengisi data, tanyakan konfirmasi
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Keluar dari Registrasi?'),
          content: Text('Data yang sudah diisi akan hilang. Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (shouldExit == true) {
        Navigator.of(context).pop();
      }
    } else {
      // Jika masih di step pertama, langsung keluar
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ktpController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _npwpController.dispose();
    _businessLicenseController.dispose();
    _vehicleTypeController.dispose();
    _brandController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _colorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}