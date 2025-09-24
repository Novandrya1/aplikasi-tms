import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_verification_dashboard_screen.dart';

void main() {
  runApp(const TMSApp());
}

class TMSApp extends StatelessWidget {
  const TMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TMS - Transport Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-verification': (context) => const AdminVerificationDashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
