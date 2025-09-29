import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('Session expired')) return 'Sesi berakhir, silakan login kembali';
    if (errorStr.contains('Access denied')) return 'Akses ditolak';
    if (errorStr.contains('Network error')) return 'Koneksi bermasalah, periksa internet Anda';
    if (errorStr.contains('Server error')) return 'Server sedang bermasalah, coba lagi nanti';
    
    return 'Terjadi kesalahan, silakan coba lagi';
  }

  static void showError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

class RetryWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const RetryWidget({
    super.key,
    required this.onRetry,
    this.message = 'Terjadi kesalahan',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh),
            label: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}