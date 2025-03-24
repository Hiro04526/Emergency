import 'dart:async';
import '../models/emergency_alert.dart';
import 'notification_service.dart';

class AlertService {
  // Singleton pattern
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();
  
  // Reference to notification service
  late final NotificationService _notificationService;
  
  // Stream controllers for alerts
  final StreamController<List<EmergencyAlert>> _alertsController = StreamController<List<EmergencyAlert>>.broadcast();
  Stream<List<EmergencyAlert>> get alertsStream => _alertsController.stream;
  
  // Cache for alerts
  final List<EmergencyAlert> _alerts = [];
  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts);

  // Initialize the service
  Future<void> initialize(NotificationService notificationService) async {
    _notificationService = notificationService;
    // Load initial alerts (mock data for now)
    await _loadMockAlerts();
  }

  // Load mock alerts
  Future<void> _loadMockAlerts() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    
    final mockAlerts = [
      EmergencyAlert(
        id: 'alert-1',
        title: 'Road Blockage at Pasig blvd',
        description: 'Major road blockage due to construction work. Expect heavy traffic. Find alternative routes.',
        type: AlertType.traffic,
        timestamp: now.subtract(const Duration(hours: 2)),
        source: 'MMDA',
        location: 'Pasig City',
        latitude: 14.5764,
        longitude: 121.0851,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-2',
        title: 'Road Blockage at Pasig blvd',
        description: 'Major road blockage due to construction work. Expect heavy traffic. Find alternative routes.',
        type: AlertType.traffic,
        timestamp: now.subtract(const Duration(hours: 4)),
        source: 'MMDA',
        location: 'Pasig City',
        latitude: 14.5764,
        longitude: 121.0851,
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

  // Get recent alerts
  List<EmergencyAlert> getRecentAlerts({int limit = 5}) {
    final sortedAlerts = List<EmergencyAlert>.from(_alerts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedAlerts.take(limit).toList();
  }

  // Add a new alert (for community reports)
  Future<void> addAlert(EmergencyAlert alert) async {
    // In a real app, you would send to an API
    _alerts.add(alert);
    _alertsController.add(_alerts);
    
    // Show notification
    _showNotification(alert);
  }

  // Report a new alert
  Future<void> reportAlert(EmergencyAlert alert) async {
    // In a real app, this would send the alert to a server
    // For now, just add it to our local list
    _alerts.add(alert);
    _alertsController.add(_alerts);
    
    // Show a notification for the new alert
    _notificationService.showAlertNotification(alert);
    
    return;
  }

  // Show notification for an alert
  void _showNotification(EmergencyAlert alert) {
    _notificationService.showNotification(
      title: '${alert.type.name}: ${alert.title}',
      message: alert.description,
      backgroundColor: alert.type.color,
    );
  }

  // Dispose resources
  void dispose() {
    _alertsController.close();
  }
}
