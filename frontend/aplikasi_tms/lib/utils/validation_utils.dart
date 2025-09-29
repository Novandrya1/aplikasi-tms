class ValidationUtils {
  // Vehicle registration validation
  static String? validateRegistrationNumber(String? value) {
    if (value?.isEmpty ?? true) return 'Nomor registrasi wajib diisi';
    
    if (value!.length < 5 || value.length > 10) {
      return 'Format nomor polisi tidak valid (contoh: B 1234 ABC)';
    }
    
    return null;
  }

  // Year validation
  static String? validateYear(String? value) {
    if (value?.isEmpty ?? true) return 'Tahun wajib diisi';
    
    final year = int.tryParse(value!);
    if (year == null) return 'Tahun harus berupa angka';
    
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'Tahun harus antara 1900 dan ${currentYear + 1}';
    }
    
    return null;
  }

  // Chassis number validation
  static String? validateChassisNumber(String? value) {
    if (value?.isEmpty ?? true) return 'Nomor rangka wajib diisi';
    
    if (value!.length != 17) {
      return 'Nomor rangka harus 17 karakter';
    }
    
    return null;
  }

  // Engine number validation
  static String? validateEngineNumber(String? value) {
    if (value?.isEmpty ?? true) return 'Nomor mesin wajib diisi';
    
    if (value!.length < 6 || value.length > 20) {
      return 'Nomor mesin harus 6-20 karakter';
    }
    
    return null;
  }

  // KTP number validation
  static String? validateKTPNumber(String? value) {
    if (value?.isEmpty ?? true) return 'Nomor KTP wajib diisi';
    
    if (value!.length != 16) {
      return 'Nomor KTP harus 16 digit';
    }
    
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Email wajib diisi';
    
    if (!value!.contains('@') || !value.contains('.')) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value?.isEmpty ?? true) return 'Nomor telepon wajib diisi';
    
    final cleanNumber = value!.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.length < 10 || cleanNumber.length > 15) {
      return 'Nomor telepon harus 10-15 digit';
    }
    
    return null;
  }

  // NPWP validation
  static String? validateNPWP(String? value) {
    if (value?.isEmpty ?? true) return null; // Optional field
    
    final cleanNPWP = value!.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNPWP.length != 15) {
      return 'NPWP harus 15 digit';
    }
    
    return null;
  }

  // Business license validation
  static String? validateBusinessLicense(String? value) {
    if (value?.isEmpty ?? true) return 'Nomor SIUP/NIB wajib diisi';
    
    if (value!.length < 10 || value.length > 20) {
      return 'Nomor SIUP/NIB harus 10-20 karakter';
    }
    
    return null;
  }

  // File validation
  static String? validateFileUpload(Map<String, dynamic>? file, {
    List<String> allowedTypes = const ['jpg', 'jpeg', 'png', 'pdf'],
    int maxSizeInMB = 10,
  }) {
    if (file == null) return 'File wajib diupload';
    
    final fileName = file['name'] as String?;
    final fileSize = file['size'] as int?;
    
    if (fileName == null || fileName.isEmpty) {
      return 'Nama file tidak valid';
    }
    
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedTypes.contains(extension)) {
      return 'Format file tidak didukung. Gunakan: ${allowedTypes.join(', ')}';
    }
    
    if (fileSize != null && fileSize > maxSizeInMB * 1024 * 1024) {
      return 'Ukuran file maksimal ${maxSizeInMB}MB';
    }
    
    return null;
  }

  // Document completeness validation
  static Map<String, dynamic> validateDocumentCompleteness(
    List<Map<String, dynamic>> documents,
    String ownerType,
  ) {
    final requiredDocs = _getRequiredDocuments(ownerType);
    final uploadedTypes = documents.map((doc) => doc['attachment_type']).toSet();
    
    final missingDocs = requiredDocs.where((doc) => !uploadedTypes.contains(doc)).toList();
    final isComplete = missingDocs.isEmpty;
    
    return {
      'is_complete': isComplete,
      'missing_documents': missingDocs,
      'uploaded_count': documents.length,
      'required_count': requiredDocs.length,
      'completion_percentage': (documents.length / requiredDocs.length * 100).clamp(0, 100),
    };
  }

  static List<String> _getRequiredDocuments(String ownerType) {
    final baseDocs = [
      'ktp',
      'selfie_ktp',
      'stnk',
      'bpkb',
      'vehicle_photo_front',
      'vehicle_photo_back',
    ];
    
    if (ownerType == 'company') {
      baseDocs.addAll(['business_license', 'npwp']);
    }
    
    return baseDocs;
  }

  // Batch validation for vehicle registration
  static Map<String, String> validateVehicleRegistration(Map<String, dynamic> data) {
    final errors = <String, String>{};
    
    // Basic info validation
    final regNumberError = validateRegistrationNumber(data['registration_number']);
    if (regNumberError != null) errors['registration_number'] = regNumberError;
    
    final yearError = validateYear(data['year']?.toString());
    if (yearError != null) errors['year'] = yearError;
    
    // Technical info validation
    final chassisError = validateChassisNumber(data['chassis_number']);
    if (chassisError != null) errors['chassis_number'] = chassisError;
    
    final engineError = validateEngineNumber(data['engine_number']);
    if (engineError != null) errors['engine_number'] = engineError;
    
    // Owner info validation
    final ktpError = validateKTPNumber(data['ktp_number']);
    if (ktpError != null) errors['ktp_number'] = ktpError;
    
    final emailError = validateEmail(data['owner_email']);
    if (emailError != null) errors['owner_email'] = emailError;
    
    final phoneError = validatePhoneNumber(data['owner_phone']);
    if (phoneError != null) errors['owner_phone'] = phoneError;
    
    // Company-specific validation
    if (data['owner_type'] == 'company') {
      final npwpError = validateNPWP(data['npwp_number']);
      if (npwpError != null) errors['npwp_number'] = npwpError;
      
      final businessLicenseError = validateBusinessLicense(data['business_license_number']);
      if (businessLicenseError != null) errors['business_license_number'] = businessLicenseError;
    }
    
    return errors;
  }

  // Sanitize input to prevent injection
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  // Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.startsWith('62')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('08')) {
      return cleaned;
    }
    
    return phoneNumber;
  }

  // Format registration number for display
  static String formatRegistrationNumber(String regNumber) {
    return regNumber.toUpperCase();
  }
}