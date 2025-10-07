import 'package:flutter/material.dart';
import 'warehouse_management_screen.dart';
import 'transport_management_screen.dart';
import 'order_management_screen.dart';
import 'admin_vehicles_screen.dart';
import 'admin_verification_dashboard_screen.dart';
import 'ocr_demo_screen.dart';
import 'admin_document_verification_screen.dart';
import 'vehicle_verification_screen.dart';
import 'inspection_operator_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/vehicle_verification_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _buildAppBarActions(context, isMobile)
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(context, isMobile),
              const SizedBox(height: 24),
              
              // Quick Stats
              _buildQuickStats(context, isMobile),
              const SizedBox(height: 24),
              
              // Core Management
              _buildSectionTitle('Manajemen Utama', isMobile),
              const SizedBox(height: 16),
              _buildCoreManagementGrid(context, isMobile, isTablet),
              
              const SizedBox(height: 32),
              
              // Admin Functions
              _buildSectionTitle('Fungsi Admin', isMobile),
              const SizedBox(height: 16),
              _buildAdminFunctionsGrid(context, isMobile, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, Admin!',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola sistem TMS dengan mudah dan efisien',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Kendaraan', '24', Icons.directions_car, Colors.blue, isMobile)),
        const SizedBox(width: 12),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: VehicleVerificationService().pendingCount,
            builder: (context, count, child) {
              return _buildStatCard('Pending Verifikasi', '$count', Icons.pending, Colors.orange, isMobile);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Driver Aktif', '15', Icons.person, Colors.green, isMobile)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isMobile ? 18 : 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCoreManagementGrid(BuildContext context, bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 3.5 : 1.2,
      children: [
        _buildManagementCard(
          context,
          'Warehouse Management',
          'Kelola gudang dan inventori',
          Icons.warehouse,
          Colors.brown,
          isMobile,
          () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const WarehouseManagementScreen(),
          )),
        ),
        _buildManagementCard(
          context,
          'Transport Management',
          'Kelola armada transportasi',
          Icons.local_shipping,
          Colors.blue,
          isMobile,
          () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const TransportManagementScreen(),
          )),
        ),
        _buildManagementCard(
          context,
          'Order Management',
          'Kelola pesanan dan pengiriman',
          Icons.shopping_cart,
          Colors.green,
          isMobile,
          () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const OrderManagementScreen(),
          )),
        ),
      ],
    );
  }

  Widget _buildAdminFunctionsGrid(BuildContext context, bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.0 : 1.1,
      children: [
        _buildAdminCard('Verifikasi\nKendaraan', Icons.verified, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const VehicleVerificationScreen(),
          ));
        }, isMobile),
        _buildAdminCard('Kelola\nKendaraan', Icons.directions_car, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const AdminVehiclesScreen(filter: 'all'),
          ));
        }, isMobile),
        _buildAdminCard('User\nManagement', Icons.people, Colors.purple, () {
          _showComingSoon(context, 'User Management');
        }, isMobile),
        _buildAdminCard('System\nSettings', Icons.settings, Colors.grey, () {
          _showComingSoon(context, 'System Settings');
        }, isMobile),
        _buildAdminCard('Revenue\nAnalytics', Icons.trending_up, Colors.teal, () {
          Navigator.pushNamed(context, '/revenue-analytics');
        }, isMobile),
        _buildAdminCard('Shipment\nManagement', Icons.local_shipping, Colors.indigo, () {
          Navigator.pushNamed(context, '/shipment-management');
        }, isMobile),
        _buildAdminCard('OCR\nDemo', Icons.document_scanner, Colors.cyan, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const OCRDemoScreen(),
          ));
        }, isMobile),
        _buildAdminCard('Verifikasi\nDokumen', Icons.description, Colors.red, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const AdminDocumentVerificationScreen(),
          ));
        }, isMobile),
        _buildAdminCard('Inspeksi\nOperator', Icons.assignment, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const InspectionOperatorScreen(),
          ));
        }, isMobile),
      ],
    );
  }

  Widget _buildManagementCard(BuildContext context, String title, String subtitle, IconData icon, Color color, bool isMobile, VoidCallback onTap) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isMobile ? Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ) : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(String title, IconData icon, Color color, VoidCallback onTap, bool isMobile) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: isMobile ? 24 : 28, color: color),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, bool isMobile) {
    List<Widget> actions = [];
    
    if (!isMobile) {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const AdminVehiclesScreen(filter: 'history'),
          )),
          tooltip: 'Riwayat Verifikasi',
        ),
        ValueListenableBuilder<int>(
          valueListenable: NotificationService().unreadCount,
          builder: (context, count, child) {
            return count > 0
                ? Badge(
                    label: Text('$count'),
                    child: IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () => _showNotifications(context),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => _showNotifications(context),
                  );
          },
        ),
      ]);
    }
    
    actions.add(
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => _logout(context),
      ),
    );
    
    return actions;
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon')),
    );
  }

  Widget _buildAdminCardWithBadge(String title, IconData icon, Color color, VoidCallback onTap, bool isMobile, ValueNotifier<int> badgeNotifier) {
    return ValueListenableBuilder<int>(
      valueListenable: badgeNotifier,
      builder: (context, count, child) {
        return Card(
          elevation: 6,
          shadowColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.white, color.withOpacity(0.03)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: isMobile ? 24 : 28, color: color),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    final notifications = NotificationService().getNotifications();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikasi'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: notifications.isEmpty
              ? const Center(child: Text('Tidak ada notifikasi'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification['type'] == 'vehicle_registration'
                            ? Icons.directions_car
                            : Icons.info,
                        color: notification['isRead'] ? Colors.grey : Colors.blue,
                      ),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: notification['isRead']
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification['message']),
                      onTap: () {
                        NotificationService().markAsRead(notification['id']);
                        Navigator.pop(context);
                        if (notification['type'] == 'vehicle_registration') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VehicleVerificationScreen(),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                NotificationService().markAllAsRead();
                Navigator.pop(context);
              },
              child: const Text('Tandai Semua Dibaca'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Transport Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.verified),
            title: Text('Verifikasi Armada'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-verification');
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_car),
            title: Text('Kelola Kendaraan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const AdminVehiclesScreen(filter: 'all'),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.storage),
            title: Text('Database Kendaraan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/vehicle-database');
            },
          ),
          ListTile(
            leading: Icon(Icons.trending_up),
            title: Text('Revenue Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/revenue-analytics');
            },
          ),
          ListTile(
            leading: Icon(Icons.local_shipping),
            title: Text('Shipment Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/shipment-management');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}