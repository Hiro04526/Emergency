import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final StreamController<List<EmergencyAlert>> _alertsController =
      StreamController<List<EmergencyAlert>>.broadcast();
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
      debugPrint('Error initializing AlertService: $e');
      await _loadMockAlerts();
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
        title: 'Flash Flood Warning',
        description:
            'Flash flooding reported in Marikina River. Water level rising rapidly. Residents in low-lying areas advised to evacuate immediately.',
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
        title: 'Traffic Accident',
        description:
            'Multiple vehicle collision on EDSA-Kamuning. Heavy traffic expected. Please take alternative routes.',
        type: AlertType.traffic,
        timestamp: now.subtract(const Duration(hours: 1)),
        source: 'MMDA',
        location: 'EDSA-Kamuning, Quezon City',
        latitude: 14.5995,
        longitude: 120.9842,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-3',
        title: 'Warning: Dru',
        description: 'Dru WiFi doodoo',
        type: AlertType.community,
        timestamp: now.subtract(const Duration(hours: 4)),
        source: 'Dru',
        location: 'Metro Manila',
        latitude: 14.5995,
        longitude: 120.9842,
        isActive: true,
        imageUrl:
            'https://aofppzgxmwazyhmzwpgr.supabase.co/storage/v1/object/public/alerts//Screenshot%202025-03-19%20004240.png',
      ),
      EmergencyAlert(
        id: 'alert-4',
        title: 'Fire Outbreak',
        description:
            'Commercial building fire reported at Makati CBD. Fire department responding. Avoid the area.',
        type: AlertType.emergency,
        timestamp: now.subtract(const Duration(hours: 5)),
        source: 'Bureau of Fire Protection',
        location: 'Makati CBD',
        latitude: 14.5548,
        longitude: 121.0244,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-5',
        title: 'Medical Emergency',
        description:
            'Mass casualty incident reported at SM Mall of Asia. Medical teams dispatched. Blood donors needed urgently.',
        type: AlertType.emergency,
        timestamp: now.subtract(const Duration(hours: 6)),
        source: 'Philippine Red Cross',
        location: 'SM Mall of Asia, Pasay City',
        latitude: 14.5347,
        longitude: 120.9829,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-6',
        title: 'Earthquake Alert',
        description:
            'Magnitude 5.4 earthquake detected. Epicenter located 20km east of Batangas. Expect aftershocks.',
        type: AlertType.naturalDisaster,
        timestamp: now.subtract(const Duration(hours: 8)),
        source: 'PHIVOLCS',
        location: 'Batangas Province',
        latitude: 13.7565,
        longitude: 121.0583,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-7',
        title: 'Power Outage',
        description:
            'Widespread power outage affecting multiple areas in Quezon City due to damaged transmission lines.',
        type: AlertType.community,
        timestamp: now.subtract(const Duration(hours: 10)),
        source: 'Meralco',
        location: 'Quezon City',
        latitude: 14.6760,
        longitude: 121.0437,
        isActive: true,
      ),
      EmergencyAlert(
        id: 'alert-8',
        title: 'Security Threat',
        description:
            'Suspicious package reported at Ninoy Aquino International Airport Terminal 3. Security personnel investigating.',
        type: AlertType.emergency,
        timestamp: now.subtract(const Duration(hours: 12)),
        source: 'Airport Police',
        location: 'NAIA Terminal 3, Pasay City',
        latitude: 14.5123,
        longitude: 121.0197,
        isActive: true,
      ),
    ];

    _alerts.addAll(mockAlerts);
    _alertsController.add(_alerts);
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
      debugPrint('Error in _loadAlerts: $e');
      // If there's an error or no alerts, load mock data as fallback
      if (_alerts.isEmpty) {
        await _loadMockAlerts();
      }
    }
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

  // Add a new alert
  Future<bool> addAlert(EmergencyAlert alert) async {
    // Send to database
    final success = await _databaseService.addAlert(alert);

    if (success) {
      // Add to local cache
      _alerts.add(alert);
      _alertsController.add(_alerts);

      // Show notification
      _showNotification(alert);
    }

    return success;
  }

  // Report a new alert (from user submissions)
  Future<bool> reportAlert(EmergencyAlert alert) async {
    // Use the same database method as addAlert
    return await addAlert(alert);
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
