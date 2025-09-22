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
      // Show options dialog
      final source = await _showSourceDialog(context, allowCamera);
      if (source == null) return null;

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
          fileBytes = await image.readAsBytes();
          fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
          fileBytes = await image.readAsBytes();
          fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
            fileBytes = await File(result.files.single.path!).readAsBytes();
            fileName = result.files.single.name;
          }
        }
      }

      if (fileBytes == null || fileName == null) return null;

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
      
      // Convert image to base64 for JSON upload
      final base64Image = 'data:image/jpeg;base64,${base64Encode(fileBytes)}';
      
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/$vehicleId/attachments'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'attachment_type': documentType,
          'file_name': fileName,
          'file_size': fileBytes.length,
          'mime_type': 'image/jpeg',
          'data': base64Image,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['attachment'];
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