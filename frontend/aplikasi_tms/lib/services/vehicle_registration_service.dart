import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VehicleRegistrationService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  // Submit registrasi kendaraan ke backend
  static Future<Map<String, dynamic>> submitRegistration({
    required String regNumber,
    required String brand,
    required String model,
    required String year,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'registration_number': regNumber,
          'brand': brand,
          'model': model,
          'year': int.parse(year),
          'user_id': userId,
          'status': 'PENDING',
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'vehicle_id': jsonDecode(response.body)['vehicle_id'],
          'message': 'Registrasi berhasil dikirim'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengirim registrasi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}'
      };
    }
  }
  
  // Upload dokumen kendaraan
  static Future<Map<String, dynamic>> uploadDocument({
    required String vehicleId,
    required File file,
    required String documentType,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/vehicles/$vehicleId/documents'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
      request.fields['document_type'] = documentType;
      
      var response = await request.send();
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': '$documentType berhasil diupload'
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal upload $documentType'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error upload: ${e.toString()}'
      };
    }
  }
}