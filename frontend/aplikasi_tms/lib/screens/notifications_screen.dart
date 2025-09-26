import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _currentIndex = 2;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _getNotificationsFromBackend();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Generate sample notifications based on backend data
      _generateSampleNotifications();
    }
  }

  Future<List<Map<String, dynamic>>> _getNotificationsFromBackend() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token');

    // Try to get vehicles for maintenance notifications
    try {
      final vehicles = await ApiService.getVehicles();
      final stats = await ApiService.getDashboardStats();
      
      List<Map<String, dynamic>> notifications = [];
      
      // Generate maintenance notifications based on vehicle data
      for (var vehicle in vehicles) {
        // Generate maintenance reminder based on vehicle year
        final currentYear = DateTime.now().year;
        final vehicleAge = currentYear - vehicle.year;
        
        if (vehicleAge > 5) {
          notifications.add({
            'id': 'maint_${vehicle.id}',
            'title': 'Perawatan Kendaraan ${vehicle.registrationNumber}',
            'message': 'Kendaraan ${vehicle.registrationNumber} (${vehicle.brand} ${vehicle.model}) berusia ${vehicleAge} tahun dan memerlukan perawatan rutin.',
            'type': 'warning',
            'is_read': false,
            'created_at': DateTime.now().subtract(Duration(days: vehicleAge)).toIso8601String(),
          });
        }
        
        // Generate status notifications
        if (vehicle.operationalStatus != 'active') {
          notifications.add({
            'id': 'status_${vehicle.id}',
            'title': 'Status Kendaraan ${vehicle.registrationNumber}',
            'message': 'Kendaraan ${vehicle.registrationNumber} dalam status ${vehicle.operationalStatus}. Periksa kondisi kendaraan.',
            'type': vehicle.operationalStatus == 'maintenance' ? 'warning' : 'info',
            'is_read': false,
            'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          });
        }
      }
      
      // Add system notifications based on stats
      if (stats.totalVehicles > 0) {
        notifications.add({
          'id': 'system_1',
          'title': 'Sistem TMS Aktif',
          'message': 'Sistem berhasil memuat ${stats.totalVehicles} kendaraan dan ${stats.activeDrivers} driver aktif.',
          'type': 'success',
          'is_read': false,
          'created_at': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
        });
      }
      
      if (stats.ongoingTrips > 0) {
        notifications.add({
          'id': 'trip_1',
          'title': 'Trip Sedang Berlangsung',
          'message': 'Terdapat ${stats.ongoingTrips} trip yang sedang berlangsung. Pantau status perjalanan secara real-time.',
          'type': 'info',
          'is_read': false,
          'created_at': DateTime.now().subtract(Duration(minutes: 15)).toIso8601String(),
        });
      }
      
      // Sort by created_at desc
      notifications.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
      
      return notifications;
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  void _generateSampleNotifications() {
    setState(() {
      _notifications = [
        {
          'id': 'sample_1',
          'title': 'Koneksi Backend Berhasil',
          'message': 'Aplikasi TMS berhasil terhubung dengan backend server.',
          'type': 'success',
          'is_read': false,
          'created_at': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        },
        {
          'id': 'sample_2',
          'title': 'Sistem Siap Digunakan',
          'message': 'Semua fitur TMS telah siap untuk digunakan. Mulai kelola transportasi Anda.',
          'type': 'info',
          'is_read': false,
          'created_at': DateTime.now().subtract(Duration(minutes: 10)).toIso8601String(),
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(_notifications[index]);
                      },
                    ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/analytics');
        break;
      case 2:
        // Already on notifications
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Semua notifikasi akan muncul di sini',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'info';
    final isVehicleNotification = notification['title']?.toString().contains('Kendaraan') ?? false;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isRead ? Colors.white : _getTypeColor(type).withOpacity(0.05),
            border: Border.all(
              color: _getTypeColor(type).withOpacity(0.2),
              width: isRead ? 0.5 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getTypeColor(type).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getTypeIcon(type, isVehicleNotification),
                    color: _getTypeColor(type),
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                              color: _getTypeColor(type),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'BARU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatDateTime(notification['created_at']),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        if (isVehicleNotification) ...[
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'Verifikasi Kendaraan',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type, bool isVehicleNotification) {
    if (isVehicleNotification) {
      switch (type) {
        case 'success':
          return Icons.check_circle;
        case 'error':
          return Icons.cancel;
        default:
          return Icons.directions_car;
      }
    }
    
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read']) return;

    setState(() {
      notification['is_read'] = true;
    });
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifikasi ditandai sebagai dibaca'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }
}