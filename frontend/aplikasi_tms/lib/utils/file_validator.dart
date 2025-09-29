import 'dart:typed_data';

class FileValidator {
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocTypes = ['pdf', 'doc', 'docx'];
  static const int maxFileSizeMB = 10;
  
  static String? validateFile(Map<String, dynamic> file) {
    final name = file['name'] as String?;
    final size = file['size'] as int?;
    final data = file['data'] as String?;
    
    if (name == null || name.isEmpty) return 'Nama file tidak valid';
    if (size == null || size <= 0) return 'Ukuran file tidak valid';
    if (data == null || data.isEmpty) return 'Data file kosong';
    
    final extension = name.split('.').last.toLowerCase();
    final allAllowed = [...allowedImageTypes, ...allowedDocTypes];
    
    if (!allAllowed.contains(extension)) {
      return 'Format file tidak didukung: $extension';
    }
    
    if (size > maxFileSizeMB * 1024 * 1024) {
      return 'Ukuran file maksimal ${maxFileSizeMB}MB';
    }
    
    // Validate file signature for security
    if (!_isValidFileSignature(data, extension)) {
      return 'File tidak valid atau rusak';
    }
    
    return null;
  }
  
  static bool _isValidFileSignature(String base64Data, String extension) {
    try {
      // Simple signature check for common file types
      final signatures = {
        'jpg': [0xFF, 0xD8, 0xFF],
        'jpeg': [0xFF, 0xD8, 0xFF],
        'png': [0x89, 0x50, 0x4E, 0x47],
        'pdf': [0x25, 0x50, 0x44, 0x46],
      };
      
      if (!signatures.containsKey(extension)) return true;
      
      // Extract first few bytes from base64
      final cleanData = base64Data.split(',').last;
      final bytes = Uri.parse('data:;base64,$cleanData').data?.contentAsBytes();
      
      if (bytes == null || bytes.length < 4) return false;
      
      final signature = signatures[extension]!;
      for (int i = 0; i < signature.length && i < bytes.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}