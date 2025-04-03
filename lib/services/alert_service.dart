import 'dart:async';
import '../models/emergency_alert.dart';
import 'notification_service.dart';
import 'database_service.dart';

class AlertService {
  // Singleton pattern
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();
  
  // Reference to notification service
  late final NotificationService _notificationService;
  final DatabaseService _databaseService = DatabaseService();
  
  // Stream controllers for alerts
  final StreamController<List<EmergencyAlert>> _alertsController = StreamController<List<EmergencyAlert>>.broadcast();
  Stream<List<EmergencyAlert>> get alertsStream => _alertsController.stream;
  
  // Cache for alerts
  final List<EmergencyAlert> _alerts = [];
  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts);

  // Initialize the service
  Future<void> initialize(NotificationService notificationService) async {
    _notificationService = notificationService;
    try {
      // Load alerts from database
      await _loadAlerts();
    } catch (e) {
      // If we have an error loading from database, try mock data
      print('Error initializing AlertService: $e');
      await _loadMockAlerts();
    }
  }

  // Load alerts from database
  Future<void> _loadAlerts() async {
    try {
      final fetchedAlerts = await _databaseService.getAlerts();
      _alerts.clear();
      if (fetchedAlerts.isNotEmpty) {
        _alerts.addAll(fetchedAlerts);
        _alertsController.add(_alerts);
      } else {
        // If no alerts found in database, load mock data
        await _loadMockAlerts();
      }
    } catch (e) {
      print('Error in _loadAlerts: $e');
      // If there's an error or no alerts, load mock data as fallback
      if (_alerts.isEmpty) {
        await _loadMockAlerts();
      }
    }
  }

  // Load mock alerts as fallback
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
        title: 'Heavy Rain Warning',
        description: 'Heavy rainfall expected in the next 24 hours. Potential for flooding in low-lying areas.',
        type: AlertType.weather,
        timestamp: now.subtract(const Duration(hours: 4)),
        source: 'PAGASA',
        location: 'Metro Manila',
        latitude: 14.5995,
        longitude: 120.9842,
        isActive: true,
      ),
    ];
    
    _alerts.addAll(mockAlerts);
    _alertsController.add(_alerts);
  }

  // Get all alerts
  Future<List<EmergencyAlert>> getAlerts() async {
    if (_alerts.isEmpty) {
      await _loadAlerts();
    }
    return _alerts;
  }
  
  // Refresh alerts from database
  Future<List<EmergencyAlert>> refreshAlerts() async {
    // Clear the cache
    _alerts.clear();
    // Notify listeners of empty list while fetching
    _alertsController.add(_alerts);
    // Load fresh data
    await _loadAlerts();
    return _alerts;
  }

  // Get alerts by type
  Future<List<EmergencyAlert>> getAlertsByType(AlertType type) async {
    if (_alerts.isEmpty) {
      await _loadAlerts();
    }
    return _alerts.where((alert) => alert.type == type).toList();
  }

  // Get active alerts
  Future<List<EmergencyAlert>> getActiveAlerts() async {
    if (_alerts.isEmpty) {
      await _loadAlerts();
    }
    return _alerts.where((alert) => alert.isActive).toList();
  }

  // Get recent alerts for home screen
  List<EmergencyAlert> getRecentAlerts({int limit = 2}) {
    final sortedAlerts = List<EmergencyAlert>.from(_alerts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedAlerts.take(limit).toList();
  }

  // Add a new alert (for community reports)
  Future<void> addAlert(EmergencyAlert alert) async {
    // Send to database
    final success = await _databaseService.addAlert(alert);
    
    if (success) {
      _alerts.add(alert);
      _alertsController.add(_alerts);
      
      // Show notification
      _showNotification(alert);
    }
  }

  // Report a new alert
  Future<void> reportAlert(EmergencyAlert alert) async {
    // Send to database
    final success = await _databaseService.addAlert(alert);
    
    if (success) {
      _alerts.add(alert);
      _alertsController.add(_alerts);
      
      // Show a notification for the new alert
      _notificationService.showAlertNotification(alert);
    }
    
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
