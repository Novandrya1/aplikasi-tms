import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/connection_test_screen.dart';
import 'screens/fleet_registration_screen.dart';
import 'screens/fleet_dashboard_screen.dart';
import 'screens/vehicle_registration_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_vehicles_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/driver_trips_screen.dart';
import 'screens/trip_tracking_screen.dart';
import 'screens/new_user_dashboard_screen.dart';
import 'screens/main_dashboard_screen.dart';
import 'screens/transport_management_screen.dart';
import 'screens/fleet_management_screen.dart';
import 'screens/trip_management_screen.dart';
import 'screens/vehicle_management_screen.dart';
import 'screens/admin_verification_dashboard_screen.dart';
import 'screens/vehicle_verification_detail_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/revenue_analytics_screen.dart';
import 'screens/shipment_management_screen.dart';
import 'screens/warehouse_management_screen.dart';
import 'screens/order_management_screen.dart';
import 'screens/driver_management_screen.dart' as driver_mgmt;
import 'services/auth_service.dart';

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
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const MainDashboardScreen(),
        '/transport-management': (context) => const TransportManagementScreen(),
        '/fleet-management': (context) => const FleetManagementScreen(),
        '/trip-management': (context) => const TripManagementScreen(),
        '/vehicle-register': (context) => VehicleRegistrationScreen(),
        '/vehicle-management': (context) => const VehicleManagementScreen(),
        '/test': (context) => ConnectionTestScreen(),
        '/fleet-register': (context) => FleetRegistrationScreen(),
        '/fleet-dashboard': (context) => FleetDashboardScreen(),
        '/admin-dashboard': (context) => AdminDashboardScreen(),
        '/admin-verification': (context) => const AdminVerificationDashboardScreen(),
        '/driver-dashboard': (context) => DriverDashboardScreen(),
        '/driver-trips': (context) => DriverTripsScreen(),
        '/driver-management': (context) => driver_mgmt.DriverManagementScreen(),
        '/new-user-dashboard': (context) => const NewUserDashboardScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/revenue-analytics': (context) => RevenueAnalyticsScreen(),
        '/shipment-management': (context) => ShipmentManagementScreen(),
        '/warehouse-management': (context) => const WarehouseManagementScreen(),
        '/order-management': (context) => const OrderManagementScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // For development, always show login screen first
    return const LoginScreen();
    
    // Uncomment below for production auth check
    /*
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data == true) {
          return DashboardScreen();
        } else {
          return LoginScreen();
        }
      },
    );
    */
  }
}