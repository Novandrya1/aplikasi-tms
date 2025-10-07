import 'dart:convert';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<Map<String, dynamic>> _notifications = [];
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  void addNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    _notifications.insert(0, notification);
    _updateUnreadCount();
    
    if (kDebugMode) {
      print('New notification: $title');
    }
  }

  List<Map<String, dynamic>> getNotifications() => List.from(_notifications);

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    unreadCount.value = _notifications.where((n) => !n['isRead']).length;
  }

  void notifyVehicleRegistration(Map<String, dynamic> vehicleData) {
    addNotification(
      title: 'Registrasi Kendaraan Baru',
      message: 'Kendaraan ${vehicleData['plateNumber']} memerlukan verifikasi',
      type: 'vehicle_registration',
      data: vehicleData,
    );
  }
}