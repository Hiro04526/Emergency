import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';
import '../models/emergency_service.dart';
import '../models/emergency_alert.dart';
import '../models/emergency_contact.dart';
import '../models/user_profile.dart';

/// Service for interacting with the Supabase database
class DatabaseService {
  // Get Supabase client instance
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // SERVICES METHODS

  /// Fetch all emergency services
  Future<List<EmergencyService>> getAllServices() async {
    try {
      final response = await _supabase
          .from('emergency_services')
          .select('*, contacts(*)')
          .order('name');

      return response.map<EmergencyService>((data) {
        // Extract contact numbers from the joined contacts table
        List<String> phoneNumbers = [];
        if (data['contacts'] != null) {
          if (data['contacts'] is List) {
            phoneNumbers = (data['contacts'] as List)
                .map((contact) => contact['phone_number'] as String)
                .toList();
          } else if (data['contacts'] is Map) {
            // Single contact
            phoneNumbers = [data['contacts']['phone_number']];
          }
        }

        // Convert type string to ServiceType enum
        ServiceType serviceType;
        final typeString = data['type']?.toString().toLowerCase() ?? '';
        
        if (typeString.contains('police')) {
          serviceType = ServiceType.police;
        } else if (typeString.contains('medical') || typeString.contains('ambulance')) {
          serviceType = ServiceType.medical;
        } else if (typeString.contains('fire')) {
          serviceType = ServiceType.fireStation;
        } else if (typeString.contains('government')) {
          serviceType = ServiceType.government;
        } else {
          // Default to police if no match
          serviceType = ServiceType.police;
        }

        return EmergencyService(
          id: data['id'],
          name: data['name'],
          type: serviceType,
          level: data['category'] ?? 'Unknown',
          description: data['description'] ?? '',
          distanceKm: 0, // This would be calculated based on user location
          phoneNumbers: phoneNumbers,
          // Add location data if available
          latitude: double.tryParse(data['latitude']?.toString() ?? ''),
          longitude: double.tryParse(data['longitude']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching services: $e');
      return [];
    }
  }

  /// Fetch services by type
  Future<List<EmergencyService>> getServicesByType(ServiceType type) async {
    try {
      // Convert ServiceType enum to string
      String typeString;
      switch (type) {
        case ServiceType.police:
          typeString = 'police';
          break;
        case ServiceType.medical:
          typeString = 'medical';
          break;
        case ServiceType.fireStation:
          typeString = 'fire';
          break;
        case ServiceType.government:
          typeString = 'government';
          break;
      }

      final response = await _supabase
          .from('emergency_services')
          .select('*, contacts(*)')
          .eq('type', typeString)
          .order('name');

      return response.map<EmergencyService>((data) {
        // Extract contact numbers
        List<String> phoneNumbers = [];
        if (data['contacts'] != null) {
          if (data['contacts'] is List) {
            phoneNumbers = (data['contacts'] as List)
                .map((contact) => contact['phone_number'] as String)
                .toList();
          } else if (data['contacts'] is Map) {
            // Single contact
            phoneNumbers = [data['contacts']['phone_number']];
          }
        }

        return EmergencyService(
          id: data['id'],
          name: data['name'],
          type: type,
          level: data['category'] ?? 'Unknown',
          description: data['description'] ?? '',
          distanceKm: 0, // This would be calculated based on user location
          phoneNumbers: phoneNumbers,
          // Add location data if available
          latitude: double.tryParse(data['latitude']?.toString() ?? ''),
          longitude: double.tryParse(data['longitude']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching services by type: $e');
      return [];
    }
  }

  /// Search for services
  Future<List<EmergencyService>> searchServices({
    String? query,
    ServiceType? type,
    String? region,
    String? city,
  }) async {
    try {
      dynamic queryBuilder = _supabase
          .from('emergency_services')
          .select('*, contacts(*)');

      // Apply filters
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('name', '%$query%');
      }

      if (type != null) {
        String typeString;
        switch (type) {
          case ServiceType.police:
            typeString = 'police';
            break;
          case ServiceType.medical:
            typeString = 'medical';
            break;
          case ServiceType.fireStation:
            typeString = 'fire';
            break;
          case ServiceType.government:
            typeString = 'government';
            break;
        }
        queryBuilder = queryBuilder.eq('type', typeString);
      }

      if (region != null && region.isNotEmpty) {
        queryBuilder = queryBuilder.eq('region', region);
      }

      if (city != null && city.isNotEmpty) {
        queryBuilder = queryBuilder.eq('city', city);
      }
      
      // Order the results
      queryBuilder = queryBuilder.order('name');

      final response = await queryBuilder;

      return response.map<EmergencyService>((data) {
        // Extract contact numbers
        List<String> phoneNumbers = [];
        if (data['contacts'] != null) {
          if (data['contacts'] is List) {
            phoneNumbers = (data['contacts'] as List)
                .map((contact) => contact['phone_number'] as String)
                .toList();
          } else if (data['contacts'] is Map) {
            // Single contact
            phoneNumbers = [data['contacts']['phone_number']];
          }
        }

        // Convert type string to ServiceType enum
        ServiceType serviceType;
        final typeString = data['type']?.toString().toLowerCase() ?? '';
        
        if (typeString.contains('police')) {
          serviceType = ServiceType.police;
        } else if (typeString.contains('medical') || typeString.contains('ambulance')) {
          serviceType = ServiceType.medical;
        } else if (typeString.contains('fire')) {
          serviceType = ServiceType.fireStation;
        } else if (typeString.contains('government')) {
          serviceType = ServiceType.government;
        } else {
          // Default to police if no match
          serviceType = ServiceType.police;
        }

        return EmergencyService(
          id: data['id'],
          name: data['name'],
          type: serviceType,
          level: data['category'] ?? 'Unknown',
          description: data['description'] ?? '',
          distanceKm: 0, // This would be calculated based on user location
          phoneNumbers: phoneNumbers,
          // Add location data if available
          latitude: double.tryParse(data['latitude']?.toString() ?? ''),
          longitude: double.tryParse(data['longitude']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }

  /// Add a new service
  Future<String?> addService({
    required String name,
    required ServiceType type,
    required String category,
    required String address,
    String? region,
    String? province,
    String? city,
    String? barangay,
    String? street,
    List<String>? phoneNumbers,
    double? latitude,
    double? longitude,
    String? userId,
  }) async {
    try {
      // Generate UUID for the service
      final serviceId = _uuid.v4();
      
      // Convert ServiceType enum to string
      String typeString;
      switch (type) {
        case ServiceType.police:
          typeString = 'police';
          break;
        case ServiceType.medical:
          typeString = 'medical';
          break;
        case ServiceType.fireStation:
          typeString = 'fire';
          break;
        case ServiceType.government:
          typeString = 'government';
          break;
      }

      // Insert service record
      await _supabase.from('emergency_services').insert({
        'id': serviceId,
        'name': name,
        'type': typeString,
        'category': category,
        'address': address,
        'region': region,
        'province': province,
        'city': city,
        'barangay': barangay,
        'street': street,
        'is_verified': false,
        'latitude': latitude,
        'longitude': longitude,
        'added_by': userId,
      });

      // Add contact numbers if provided
      if (phoneNumbers != null && phoneNumbers.isNotEmpty) {
        for (var phoneNumber in phoneNumbers) {
          await _supabase.from('contacts').insert({
            'id': _uuid.v4(),
            'phone_number': phoneNumber,
            'service_id': serviceId,
          });
        }
      }

      // Record the action in history if userId is provided
      if (userId != null) {
        await _supabase.from('history').insert({
          'id': _uuid.v4(),
          'user_id': userId,
          'service_id': serviceId,
          'action': 'add',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return serviceId;
    } catch (e) {
      debugPrint('Error adding service: $e');
      return null;
    }
  }

  /// Report a service
  Future<bool> reportService(String serviceId) async {
    try {
      // Add to reported services table
      await _supabase.from('reported_services').insert({
        'service_id': serviceId,
        'reported_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error reporting service: $e');
      return false;
    }
  }

  // USER METHODS

  /// Register a new user
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    String? homeLocation,
  }) async {
    try {
      // Register with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return null;
      }

      final userId = response.user!.id;

      // Then insert user details into our profiles table
      await _supabase.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'home_location': homeLocation,
      });

      return userId;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return null;
    }
  }

  /// Login user
  Future<UserProfile?> loginUser(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return null;
      }

      // Get user details from profiles table
      final userData = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserProfile(
        name: userData['name'],
        phoneNumber: userData['phone_number'],
        homeAddress: userData['home_location'],
      );
    } catch (e) {
      debugPrint('Error logging in: $e');
      return null;
    }
  }

  // ALERT METHODS

  /// Create a new alert
  Future<String?> createAlert({
    required String title,
    required String description,
    required AlertType type,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final alertId = _uuid.v4();
      
      String typeString;
      switch (type) {
        case AlertType.emergency:
          typeString = 'emergency';
          break;
        case AlertType.weather:
          typeString = 'weather';
          break;
        case AlertType.naturalDisaster:
          typeString = 'natural_disaster';
          break;
        case AlertType.traffic:
          typeString = 'traffic';
          break;
        case AlertType.community:
          typeString = 'community';
          break;
      }
      
      await _supabase.from('alerts').insert({
        'id': alertId,
        'title': title,
        'description': description,
        'type': typeString,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      return alertId;
    } catch (e) {
      debugPrint('Error creating alert: $e');
      return null;
    }
  }

  /// Get all active alerts
  Future<List<EmergencyAlert>> getActiveAlerts() async {
    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map<EmergencyAlert>((data) {
        // Determine alert type
        AlertType alertType;
        final typeString = data['type']?.toString().toLowerCase() ?? '';
        
        if (typeString.contains('emergency')) {
          alertType = AlertType.emergency;
        } else if (typeString.contains('weather')) {
          alertType = AlertType.weather;
        } else if (typeString.contains('disaster')) {
          alertType = AlertType.naturalDisaster;
        } else if (typeString.contains('traffic')) {
          alertType = AlertType.traffic;
        } else {
          alertType = AlertType.community;
        }

        return EmergencyAlert(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          type: alertType,
          timestamp: DateTime.parse(data['created_at']),
          location: data['location'],
          latitude: data['latitude'],
          longitude: data['longitude'],
          isActive: data['is_active'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return [];
    }
  }

  // FAVORITE METHODS

  /// Add a favorite location
  Future<String?> addFavoriteLocation({
    required String userId,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final favoriteId = _uuid.v4();
      
      await _supabase.from('favorites').insert({
        'id': favoriteId,
        'user_id': userId,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
      });

      return favoriteId;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return null;
    }
  }

  /// Get favorite locations for a user
  Future<List<Map<String, dynamic>>> getFavoriteLocations(String userId) async {
    try {
      final response = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', userId);

      return response.map<Map<String, dynamic>>((data) => {
        'id': data['id'],
        'location': data['location'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
      }).toList();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      return [];
    }
  }
}
