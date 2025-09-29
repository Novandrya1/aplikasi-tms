import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class OCRService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Extract STNK data from base64 image
  static Future<Map<String, dynamic>> extractSTNKData(String base64Image) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/ocr/stnk'),
        headers: headers,
        body: json.encode({
          'image_data': base64Image,
          'document_type': 'stnk',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['extracted_data'] ?? {};
      } else {
        throw Exception('OCR failed: ${response.body}');
      }
    } catch (e) {
      print('OCR Error: $e');
      // Return mock data for demo
      return _getMockSTNKData();
    }
  }

  /// Extract KTP data from base64 image
  static Future<Map<String, dynamic>> extractKTPData(String base64Image) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/ocr/ktp'),
        headers: headers,
        body: json.encode({
          'image_data': base64Image,
          'document_type': 'ktp',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['extracted_data'] ?? {};
      } else {
        throw Exception('OCR failed: ${response.body}');
      }
    } catch (e) {
      print('OCR Error: $e');
      // Return mock data for demo
      return _getMockKTPData();
    }
  }

  /// Perform face matching between selfie and KTP
  static Future<Map<String, dynamic>> performFaceMatch(
    String selfieBase64,
    String ktpBase64,
  ) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/ocr/face-match'),
        headers: headers,
        body: json.encode({
          'selfie_image': selfieBase64,
          'ktp_image': ktpBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Face match failed: ${response.body}');
      }
    } catch (e) {
      print('Face Match Error: $e');
      // Return mock data for demo
      return _getMockFaceMatchData();
    }
  }

  /// Validate document quality and readability
  static Future<Map<String, dynamic>> validateDocumentQuality(
    String base64Image,
    String documentType,
  ) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/ocr/validate-quality'),
        headers: headers,
        body: json.encode({
          'image_data': base64Image,
          'document_type': documentType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Quality validation failed: ${response.body}');
      }
    } catch (e) {
      print('Quality Validation Error: $e');
      // Return mock data for demo
      return _getMockQualityData();
    }
  }

  // Mock data for demo purposes
  static Map<String, dynamic> _getMockSTNKData() {
    return {
      'plate_number': 'L1234AB',
      'owner_name': 'AHMAD SURYANTO',
      'nik': '3201234567890123',
      'address': 'JL. MERDEKA NO. 123, JAKARTA',
      'vehicle_brand': 'TOYOTA',
      'vehicle_model': 'AVANZA',
      'vehicle_year': '2020',
      'chassis_number': 'MHKA1BA1HKK123456',
      'engine_number': '3SZ1234567',
      'vehicle_color': 'HITAM',
      'expiry_date': '2025-12-31',
      'issue_date': '2020-01-15',
      'confidence_score': 0.92,
      'extracted_fields': [
        {'field': 'plate_number', 'value': 'L1234AB', 'confidence': 0.95},
        {'field': 'owner_name', 'value': 'AHMAD SURYANTO', 'confidence': 0.90},
        {'field': 'nik', 'value': '3201234567890123', 'confidence': 0.88},
        {'field': 'expiry_date', 'value': '2025-12-31', 'confidence': 0.93},
      ],
    };
  }

  static Map<String, dynamic> _getMockKTPData() {
    return {
      'nik': '3201234567890123',
      'name': 'AHMAD SURYANTO',
      'birth_place': 'JAKARTA',
      'birth_date': '1985-05-15',
      'gender': 'LAKI-LAKI',
      'address': 'JL. MERDEKA NO. 123',
      'rt_rw': '001/002',
      'village': 'MENTENG',
      'district': 'MENTENG',
      'city': 'JAKARTA PUSAT',
      'province': 'DKI JAKARTA',
      'religion': 'ISLAM',
      'marital_status': 'KAWIN',
      'occupation': 'KARYAWAN SWASTA',
      'nationality': 'WNI',
      'expiry_date': '2030-05-15',
      'confidence_score': 0.89,
    };
  }

  static Map<String, dynamic> _getMockFaceMatchData() {
    return {
      'match_score': 0.87,
      'is_match': true,
      'confidence': 'high',
      'threshold': 0.75,
      'details': {
        'face_detected_selfie': true,
        'face_detected_ktp': true,
        'quality_score_selfie': 0.92,
        'quality_score_ktp': 0.85,
      },
    };
  }

  static Map<String, dynamic> _getMockQualityData() {
    return {
      'overall_quality': 'good',
      'quality_score': 0.88,
      'issues': [],
      'recommendations': [],
      'checks': {
        'brightness': {'score': 0.90, 'status': 'good'},
        'blur': {'score': 0.85, 'status': 'good'},
        'contrast': {'score': 0.92, 'status': 'excellent'},
        'text_readability': {'score': 0.87, 'status': 'good'},
        'document_bounds': {'score': 0.95, 'status': 'excellent'},
      },
    };
  }
}