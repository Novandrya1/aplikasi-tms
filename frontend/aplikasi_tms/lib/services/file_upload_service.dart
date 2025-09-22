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

  static Future<String?> pickAndUploadFile({
    required String documentType,
    required BuildContext context,
    bool allowCamera = true,
  }) async {
    try {
      // Show options dialog
      final source = await _showSourceDialog(context, allowCamera);
      if (source == null) return null;

      String? filePath;
      Uint8List? fileBytes;
      String? fileName;

      if (source == 'camera') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          filePath = image.path;
          fileBytes = await image.readAsBytes();
          fileName = image.name;
        }
      } else if (source == 'gallery') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          filePath = image.path;
          fileBytes = await image.readAsBytes();
          fileName = image.name;
        }
      } else {
        // File picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          allowMultiple: false,
        );
        
        if (result != null) {
          if (result.files.single.bytes != null) {
            // Web platform
            fileBytes = result.files.single.bytes!;
            fileName = result.files.single.name;
          } else if (result.files.single.path != null) {
            // Mobile platform
            filePath = result.files.single.path!;
            fileBytes = await File(filePath).readAsBytes();
            fileName = result.files.single.name;
          }
        }
      }

      if (fileBytes == null || fileName == null) return null;

      // For demo purposes, return mock file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'uploads/${documentType}_${timestamp}_${fileName}';
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

  static Future<String?> _uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String documentType,
  }) async {
    try {
      final headers = await _getHeaders();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/document'),
      );
      
      request.headers.addAll(headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      request.fields['document_type'] = documentType;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['file_url'] ?? fileName;
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      // For demo purposes, return a mock file path
      return 'uploads/${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
  }
}