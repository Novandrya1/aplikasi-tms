import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class FileService {
  static String get baseUrl => ApiConfig.baseUrl;

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static Future<Map<String, dynamic>?> uploadDocument({
    required String documentType,
    required String fileName,
    required Uint8List fileData,
    String? mimeType,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Convert file data to base64
      final base64Data = base64Encode(fileData);
      final dataUrl = 'data:${mimeType ?? 'image/jpeg'};base64,$base64Data';

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/documents/upload'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'document_type': documentType,
          'file_name': fileName,
          'file_size': fileData.length,
          'mime_type': mimeType ?? 'image/jpeg',
          'data': dataUrl,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to upload document');
      }
    } catch (e) {
      print('File upload error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadVehicleAttachment({
    required int vehicleId,
    required String attachmentType,
    required String fileName,
    required Uint8List fileData,
    String? mimeType,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Convert file data to base64
      final base64Data = base64Encode(fileData);
      final dataUrl = 'data:${mimeType ?? 'image/jpeg'};base64,$base64Data';

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/vehicles/$vehicleId/attachments'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'attachment_type': attachmentType,
          'file_name': fileName,
          'file_size': fileData.length,
          'mime_type': mimeType ?? 'image/jpeg',
          'data': dataUrl,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to upload attachment');
      }
    } catch (e) {
      print('Vehicle attachment upload error: $e');
      return null;
    }
  }

  static Future<String?> getFileUrl(String fileName) async {
    try {
      return '$baseUrl/api/v1/files/$fileName';
    } catch (e) {
      print('Get file URL error: $e');
      return null;
    }
  }

  static bool isValidImageType(String? mimeType) {
    if (mimeType == null) return false;
    return ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'].contains(mimeType.toLowerCase());
  }

  static bool isValidDocumentType(String? mimeType) {
    if (mimeType == null) return false;
    return [
      'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ].contains(mimeType.toLowerCase());
  }

  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  static String getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}