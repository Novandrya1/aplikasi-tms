import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_verification_dashboard_screen.dart';
import 'screens/gps_registration_screen.dart';
import 'screens/admin_gps_approval_screen.dart';
import 'screens/transport_management_screen.dart';
import 'screens/trip_management_screen.dart';
import 'screens/vehicle_management_screen.dart';

import 'screens/revenue_analytics_screen.dart';
import 'screens/shipment_management_screen.dart';

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
        '/register': (context) => const RegisterScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/user-dashboard': (context) => const DashboardScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/admin-verification': (context) => const AdminVerificationDashboardScreen(),
        '/gps-registration': (context) => const GPSRegistrationScreen(),
        '/admin-gps-approval': (context) => const AdminGPSApprovalScreen(),
        '/transport-management': (context) => const TransportManagementScreen(),
        '/trip-management': (context) => const TripManagementScreen(),
        '/vehicle-management': (context) => const VehicleManagementScreen(),

        '/revenue-analytics': (context) => RevenueAnalyticsScreen(),
        '/shipment-management': (context) => ShipmentManagementScreen(),

        '/warehouse-management': (context) => const DashboardScreen(), // Temporary redirect
        '/driver-management': (context) => const DashboardScreen(), // Temporary redirect
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
