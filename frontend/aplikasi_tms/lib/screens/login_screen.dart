import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TMS Login')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TMS Login Screen'),
            SizedBox(height: 20),
            Text('Backend API Ready at http://localhost:8080'),
          ],
        ),
      ),
    );
  }
}
