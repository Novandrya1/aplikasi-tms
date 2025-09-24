import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class FileUploadService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> pickAndUploadFile({
    required String documentType,
    required BuildContext context,
    required int vehicleId,
    bool allowCamera = true,
  }) async {
    try {
      // Show source selection dialog
      final source = await _showSourceDialog(context, allowCamera);
      if (source == null) return null;
      
      Uint8List? fileBytes;
      String? fileName;
      
      if (source == 'camera') {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image == null) return null;
        
        fileBytes = await image.readAsBytes();
        fileName = image.name;
      } else if (source == 'gallery') {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image == null) return null;
        
        fileBytes = await image.readAsBytes();
        fileName = image.name;
      } else {
        // File picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        
        if (result == null || result.files.isEmpty) return null;
        
        final file = result.files.first;
        if (file.bytes == null) throw Exception('No file data available');
        
        fileBytes = file.bytes!;
        fileName = file.name;
      }
      
      print('File selected: $fileName, size: ${fileBytes.length}');

      // Upload to backend
      return await _uploadFileToBackend(
        vehicleId: vehicleId,
        fileBytes: fileBytes,
        fileName: fileName,
        documentType: documentType,
      );
    } catch (e) {
      print('Error picking/uploading file: $e');
      return null;
    }
  }

  static Future<String?> _showSourceDialog(BuildContext context, bool allowCamera) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Sumber File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allowCamera) ...[
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text('Kamera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Galeri'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
            ListTile(
              leading: Icon(Icons.folder, color: Colors.blue),
              title: Text('File'),
              onTap: () => Navigator.pop(context, 'file'),
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

  static Future<Map<String, dynamic>?> _uploadFileToBackend({
    required int vehicleId,
    required Uint8List fileBytes,
    required String fileName,
    required String documentType,
  }) async {
    try {
      final headers = await _getHeaders();
      print('Upload headers: $headers');
      
      final url = '$baseUrl/api/v1/documents/upload';
      print('Upload URL: $url');
      
      // Convert image to base64 for JSON upload
      final base64Image = 'data:image/jpeg;base64,${base64Encode(fileBytes)}';
      
      final requestBody = {
        'document_type': documentType,
        'file_name': fileName,
        'file_size': fileBytes.length,
        'mime_type': 'image/jpeg',
        'data': base64Image,
      };
      
      print('Request body keys: ${requestBody.keys}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}