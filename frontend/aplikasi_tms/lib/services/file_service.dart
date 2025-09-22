// File service functionality moved to file_upload_service.dart
// This file is kept for compatibility but functionality is deprecated

class FileService {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static bool isValidFileType(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  // Mock methods for compatibility
  static Future<List<Map<String, dynamic>>> getVehicleAttachments(int vehicleId) async {
    return [];
  }

  static List<String> getAttachmentTypes() {
    return ['stnk', 'bpkb', 'uji_kir', 'asuransi', 'foto_depan', 'foto_belakang', 'foto_samping'];
  }

  static String getAttachmentTypeLabel(String type) {
    switch (type) {
      case 'stnk': return 'STNK';
      case 'bpkb': return 'BPKB';
      case 'uji_kir': return 'Uji KIR';
      case 'asuransi': return 'Asuransi';
      case 'foto_depan': return 'Foto Depan';
      case 'foto_belakang': return 'Foto Belakang';
      case 'foto_samping': return 'Foto Samping';
      default: return type;
    }
  }

  static Future<void> deleteVehicleAttachment(int vehicleId, int attachmentId) async {
    // Mock implementation
  }
}