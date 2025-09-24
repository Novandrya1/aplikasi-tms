import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class AdminDocumentVerificationScreen extends StatefulWidget {
  const AdminDocumentVerificationScreen({super.key});
  
  @override
  _AdminDocumentVerificationScreenState createState() => _AdminDocumentVerificationScreenState();
}

class _AdminDocumentVerificationScreenState extends State<AdminDocumentVerificationScreen> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final token = await AuthService.getToken();
      print('Loading documents with token: ${token?.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/documents'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Documents response status: ${response.statusCode}');
      print('Documents response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _documents = List<Map<String, dynamic>>.from(data['documents'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load documents: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyDocument(int docId, String status) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/documents/$docId/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'notes': status == 'approved' ? 'Dokumen valid' : 'Perlu perbaikan',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen berhasil di${status == 'approved' ? 'setujui' : 'tolak'}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _loadDocuments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Dokumen'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDocuments,
                        child: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Tidak ada dokumen pending'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDocuments,
                            child: Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${doc['username']} (${doc['email']})',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.description, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('${doc['document_type']}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.file_present, color: Colors.green),
                                SizedBox(width: 8),
                                Text('${doc['file_name']}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('${doc['created_at']}'),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verifyDocument(doc['id'], 'approved'),
                                    icon: Icon(Icons.check),
                                    label: Text('Setujui'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verifyDocument(doc['id'], 'rejected'),
                                    icon: Icon(Icons.close),
                                    label: Text('Tolak'),
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
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDocuments,
        child: Icon(Icons.refresh),
        backgroundColor: Color(0xFF1976D2),
      ),
    );
  }
}