import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/ocr_service.dart';
import '../services/file_upload_service.dart';

class OCRDemoScreen extends StatefulWidget {
  @override
  _OCRDemoScreenState createState() => _OCRDemoScreenState();
}

class _OCRDemoScreenState extends State<OCRDemoScreen> {
  Map<String, dynamic>? _stnkData;
  Map<String, dynamic>? _ktpData;
  Map<String, dynamic>? _faceMatchResult;
  Map<String, dynamic>? _qualityResult;
  bool _isLoading = false;
  String? _selectedImageType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildUploadSection(),
            SizedBox(height: 24),
            if (_stnkData != null) _buildSTNKResults(),
            if (_ktpData != null) _buildKTPResults(),
            if (_faceMatchResult != null) _buildFaceMatchResults(),
            if (_qualityResult != null) _buildQualityResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OCR Integration Demo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Test ekstraksi data otomatis dari dokumen',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Dokumen untuk OCR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildUploadButton(
                  'STNK',
                  Icons.description,
                  Colors.orange,
                  () => _uploadAndExtract('stnk'),
                ),
                _buildUploadButton(
                  'KTP',
                  Icons.credit_card,
                  Colors.green,
                  () => _uploadAndExtract('ktp'),
                ),
                _buildUploadButton(
                  'Face Match',
                  Icons.face,
                  Colors.purple,
                  () => _performFaceMatch(),
                ),
                _buildUploadButton(
                  'Quality Check',
                  Icons.high_quality,
                  Colors.indigo,
                  () => _checkQuality(),
                ),
              ],
            ),
            if (_isLoading) ...[
              SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Memproses OCR...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 20),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildSTNKResults() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Hasil Ekstraksi STNK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDataRow('Nomor Polisi', _stnkData!['plate_number']),
            _buildDataRow('Nama Pemilik', _stnkData!['owner_name']),
            _buildDataRow('NIK', _stnkData!['nik']),
            _buildDataRow('Merk Kendaraan', _stnkData!['vehicle_brand']),
            _buildDataRow('Model', _stnkData!['vehicle_model']),
            _buildDataRow('Tahun', _stnkData!['vehicle_year']),
            _buildDataRow('Masa Berlaku', _stnkData!['expiry_date']),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confidence Score: ${(_stnkData!['confidence_score'] * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
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

  Widget _buildKTPResults() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Hasil Ekstraksi KTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDataRow('NIK', _ktpData!['nik']),
            _buildDataRow('Nama', _ktpData!['name']),
            _buildDataRow('Tempat Lahir', _ktpData!['birth_place']),
            _buildDataRow('Tanggal Lahir', _ktpData!['birth_date']),
            _buildDataRow('Alamat', _ktpData!['address']),
            _buildDataRow('Kota', _ktpData!['city']),
            _buildDataRow('Provinsi', _ktpData!['province']),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confidence Score: ${(_ktpData!['confidence_score'] * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
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

  Widget _buildFaceMatchResults() {
    final isMatch = _faceMatchResult!['is_match'] ?? false;
    final matchScore = _faceMatchResult!['match_score'] ?? 0.0;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.face, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Hasil Face Matching',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMatch ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMatch ? Colors.green[200]! : Colors.red[200]!,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isMatch ? Icons.check_circle : Icons.cancel,
                        color: isMatch ? Colors.green[600] : Colors.red[600],
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMatch ? 'Wajah Cocok' : 'Wajah Tidak Cocok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isMatch ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                            Text(
                              'Match Score: ${(matchScore * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isMatch ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityResults() {
    final qualityScore = _qualityResult!['quality_score'] ?? 0.0;
    final overallQuality = _qualityResult!['overall_quality'] ?? 'unknown';
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.high_quality, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Hasil Quality Check',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment, color: Colors.indigo[600]),
                      SizedBox(width: 8),
                      Text(
                        'Overall Quality: ${overallQuality.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: qualityScore,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quality Score: ${(qualityScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.indigo[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAndExtract(String documentType) async {
    setState(() {
      _isLoading = true;
      _selectedImageType = documentType;
    });

    try {
      // Simulate file upload and get base64 data
      final result = await FileUploadService.pickAndUploadFile(
        documentType: documentType,
        context: context,
        vehicleId: 1, // Demo vehicle ID
        allowCamera: true,
      );

      if (result != null) {
        // Get base64 data from uploaded file
        final base64Data = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wA==';

        if (documentType == 'stnk') {
          final extractedData = await OCRService.extractSTNKData(base64Data);
          setState(() {
            _stnkData = extractedData;
          });
        } else if (documentType == 'ktp') {
          final extractedData = await OCRService.extractKTPData(base64Data);
          setState(() {
            _ktpData = extractedData;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR berhasil! Data ${documentType.toUpperCase()} telah diekstrak.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _selectedImageType = null;
      });
    }
  }

  Future<void> _performFaceMatch() async {
    setState(() => _isLoading = true);

    try {
      // Mock base64 images for demo
      final selfieBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wA==';
      final ktpBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wA==';

      final result = await OCRService.performFaceMatch(selfieBase64, ktpBase64);
      setState(() {
        _faceMatchResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face matching selesai!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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

  Future<void> _checkQuality() async {
    setState(() => _isLoading = true);

    try {
      // Mock base64 image for demo
      final base64Data = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wA==';

      final result = await OCRService.validateDocumentQuality(base64Data, 'stnk');
      setState(() {
        _qualityResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quality check selesai!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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
}