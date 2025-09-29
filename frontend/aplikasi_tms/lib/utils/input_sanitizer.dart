class InputSanitizer {
  static String sanitize(String input) {
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\\', '')
        .replaceAll('/', '')
        .replaceAll('script', '')
        .replaceAll('javascript:', '')
        .trim();
  }
  
  static String sanitizeSQL(String input) {
    return input
        .replaceAll("'", "''")
        .replaceAll(';', '')
        .replaceAll('--', '')
        .replaceAll('/*', '')
        .replaceAll('*/', '')
        .trim();
  }
  
  static bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }
  
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }
  
  static bool isValidPlateNumber(String plate) {
    return plate.length >= 5 && plate.length <= 10;
  }
}