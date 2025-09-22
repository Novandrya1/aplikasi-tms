import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService Tests', () {
    test('validates email format correctly', () {
      expect(isValidEmail('test@example.com'), true);
      expect(isValidEmail('user.name@domain.co.id'), true);
      expect(isValidEmail('invalid-email'), false);
      expect(isValidEmail(''), false);
      expect(isValidEmail('test@'), false);
    });

    test('validates password strength', () {
      expect(isValidPassword('password123'), true);
      expect(isValidPassword('12345'), false);
      expect(isValidPassword(''), false);
    });

    test('formats currency correctly', () {
      expect(formatCurrency(1000000), 'Rp 1.000.000');
      expect(formatCurrency(500000), 'Rp 500.000');
      expect(formatCurrency(0), 'Rp 0');
    });
  });
}

bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

String formatCurrency(double amount) {
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}