import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/emergency_alert.dart';

class AlertService {
  // Singleton pattern
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  // Notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Stream controllers for alerts
  final StreamController<List<EmergencyAlert>> _alertsController = StreamController<List<EmergencyAlert>>.broadcast();
  Stream<List<EmergencyAlert>> get alertsStream => _alertsController.stream;
  
  // Cache for alerts
  final List<EmergencyAlert> _alerts = [];
  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts);

  // Initialize the service
  Future<void> initialize() async {
    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Load initial alerts (mock data for now)
    await _loadMockAlerts();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse details) {
    // TODO: Navigate to alert details screen
    debugPrint('Notification tapped: ${details.payload}');
  }

  // Load mock alerts
  Future<void> _loadMockAlerts() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    
    final mockAlerts = [
      EmergencyAlert(
        id: 'alert-1',
        title: 'Flash Flood Warning',
        description: 'Flash flood warning issued for Marikina River. Water level rising rapidly. Evacuate low-lying areas immediately.',
        type: AlertType.weather,
        timestamp: now.subtract(const Duration(hours: 2)),
        source: 'PAGASA',
        location: 'Marikina City',
        latitude: 14.6507,
        longitude: 121.1029,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-2',
        title: 'Earthquake Advisory',
        description: 'Magnitude 5.4 earthquake detected in Batangas. Expect aftershocks. Check structures for damage.',
        type: AlertType.naturalDisaster,
        timestamp: now.subtract(const Duration(hours: 5)),
        source: 'PHIVOLCS',
        location: 'Batangas',
        latitude: 13.7565,
        longitude: 121.0583,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-3',
        title: 'Traffic Accident',
        description: 'Major traffic accident on EDSA-Kamuning. Multiple vehicles involved. Expect heavy traffic. Use alternative routes.',
        type: AlertType.traffic,
        timestamp: now.subtract(const Duration(hours: 1)),
        source: 'MMDA',
        location: 'EDSA-Kamuning',
        latitude: 14.6358,
        longitude: 121.0388,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-4',
        title: 'Typhoon Signal #2',
        description: 'Typhoon "Maria" intensifies. Signal #2 raised over Metro Manila. Prepare emergency supplies and secure properties.',
        type: AlertType.weather,
        timestamp: now.subtract(const Duration(days: 1)),
        source: 'PAGASA',
        location: 'Metro Manila',
        latitude: 14.5995,
        longitude: 120.9842,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-5',
        title: 'Community Safety Alert',
        description: 'Suspicious activity reported in Barangay San Roque. Increased police patrols in the area. Stay vigilant.',
        type: AlertType.community,
        timestamp: now.subtract(const Duration(hours: 12)),
        source: 'Barangay San Roque',
        location: 'San Roque, Marikina',
        latitude: 14.6292,
        longitude: 121.0952,
        isActive: true,
      ),
    ];
    
    _alerts.addAll(mockAlerts);
    _alertsController.add(_alerts);
  }

  // Get all alerts
  Future<List<EmergencyAlert>> getAlerts() async {
    // In a real app, you would fetch from an API
    return _alerts;
  }

  // Get alerts by type
  Future<List<EmergencyAlert>> getAlertsByType(AlertType type) async {
    return _alerts.where((alert) => alert.type == type).toList();
  }

  // Get active alerts
  Future<List<EmergencyAlert>> getActiveAlerts() async {
    return _alerts.where((alert) => alert.isActive).toList();
  }

  // Add a new alert (for community reports)
  Future<void> addAlert(EmergencyAlert alert) async {
    // In a real app, you would send to an API
    _alerts.add(alert);
    _alertsController.add(_alerts);
    
    // Show notification
    await _showNotification(alert);
  }

  // Show notification for an alert
  Future<void> _showNotification(EmergencyAlert alert) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_alerts_channel',
      'Emergency Alerts',
      channelDescription: 'Notifications for emergency alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      alert.id.hashCode,
      '${alert.type.name}: ${alert.title}',
      alert.description,
      notificationDetails,
      payload: alert.id,
    );
  }

  // Dispose resources
  void dispose() {
    _alertsController.close();
  }
}
