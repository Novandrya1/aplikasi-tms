import 'package:flutter/material.dart';

class AdminDocumentVerificationScreen extends StatefulWidget {
  const AdminDocumentVerificationScreen({super.key});
  
  @override
  State<AdminDocumentVerificationScreen> createState() => _AdminDocumentVerificationScreenState();
}

class _AdminDocumentVerificationScreenState extends State<AdminDocumentVerificationScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Dokumen'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Tidak ada dokumen pending'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refresh dokumen')),
                );
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}