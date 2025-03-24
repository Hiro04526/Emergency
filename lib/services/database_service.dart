import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/emergency_service.dart';
import '../models/emergency_alert.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Get Supabase client
  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  // Get emergency services by type
  Future<List<EmergencyService>> getServicesByType(ServiceType type) async {
    try {
      final typeString = _getTypeString(type);
      
      final response = await _client
          .from('service')
          .select()
          .eq('type', typeString)
          .order('name');
      
      if (response.isEmpty) {
        return [];
      }
      
      return response
          .map((data) => EmergencyService.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching services: $e');
      return [];
    }
  }

  // Search emergency services
  Future<List<EmergencyService>> searchServices({
    String? query,
    ServiceType? type,
    String? region,
    String? category,
    String? classification,
  }) async {
    try {
      var request = _client.from('service').select();
      
      if (type != null) {
        request = request.eq('type', _getTypeString(type));
      }
      
      if (query != null && query.isNotEmpty) {
        request = request.or('name.ilike.%$query%,description.ilike.%$query%');
      }
      
      if (region != null && region.isNotEmpty) {
        request = request.eq('region', region);
      }
      
      if (category != null && category.isNotEmpty) {
        request = request.eq('category', category);
      }
      
      if (classification != null && classification.isNotEmpty) {
        request = request.eq('classification', classification);
      }
      
      final response = await request.order('name');
      
      if (response.isEmpty) {
        return [];
      }
      
      return response
          .map((data) => EmergencyService.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }

  // Get all alerts
  Future<List<EmergencyAlert>> getAlerts() async {
    try {
      final response = await _client
          .from('alert')
          .select()
          .order('timestamp', ascending: false);
      
      if (response.isEmpty) {
        return [];
      }
      
      return response
          .map((data) => _parseAlert(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return [];
    }
  }

  // Add a new alert
  Future<bool> addAlert(EmergencyAlert alert) async {
    try {
      await _client.from('alert').insert({
        'title': alert.title,
        'description': alert.description,
        'type': alert.type.name,
        'source': alert.source,
        'location': alert.location,
        'latitude': alert.latitude,
        'longitude': alert.longitude,
        'is_active': alert.isActive,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error adding alert: $e');
      return false;
    }
  }

  // Report a service
  Future<bool> reportService(String serviceId, String reason) async {
    try {
      await _client.from('reported').insert({
        'service_id': serviceId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error reporting service: $e');
      return false;
    }
  }

  // Add to history
  Future<bool> addToHistory(String serviceId, String action) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      
      await _client.from('history').insert({
        'user_id': userId,
        'service_id': serviceId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error adding to history: $e');
      return false;
    }
  }

  // Helper method to convert ServiceType to string for database
  String _getTypeString(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return 'police';
      case ServiceType.medical:
        return 'medical';
      case ServiceType.fireStation:
        return 'fire';
      case ServiceType.government:
        return 'government';
      default:
        return 'police';
    }
  }

  // Helper method to parse alert from database
  EmergencyAlert _parseAlert(Map<String, dynamic> data) {
    AlertType alertType;
    final typeString = data['type']?.toString().toLowerCase() ?? '';
    
    if (typeString.contains('traffic')) {
      alertType = AlertType.traffic;
    } else if (typeString.contains('weather')) {
      alertType = AlertType.weather;
    } else if (typeString.contains('community')) {
      alertType = AlertType.community;
    } else if (typeString.contains('natural') || typeString.contains('disaster')) {
      alertType = AlertType.naturalDisaster;
    } else {
      alertType = AlertType.emergency;
    }
    
    return EmergencyAlert(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      type: alertType,
      timestamp: DateTime.parse(data['timestamp']),
      source: data['source'],
      location: data['location'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      isActive: data['is_active'] ?? true,
    );
  }
}
