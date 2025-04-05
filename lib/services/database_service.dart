import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/emergency_service.dart';
import '../models/emergency_alert.dart';
import 'location_service.dart';
import 'cache_manager_service.dart';

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

      // Get the list of service IDs
      final serviceIds = response.map<String>((data) => data['id'].toString()).toList();
      
      // Map to store contacts for each service
      final Map<String, List<String>> serviceContacts = {};
      
      try {
        // Fetch contact numbers for these services
        final contactsResponse = await _client
            .from('contact')
            .select()
            .inFilter('service_id', serviceIds);
            
        debugPrint('Found ${contactsResponse.length} contacts for ${serviceIds.length} services');
        
        // Create a map of service ID to list of phone numbers
        for (var contact in contactsResponse) {
          final serviceId = contact['service_id'].toString();
          final phoneNumber = contact['phone_number']?.toString();
          
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            if (!serviceContacts.containsKey(serviceId)) {
              serviceContacts[serviceId] = [];
            }
            serviceContacts[serviceId]!.add(phoneNumber);
          }
        }
      } catch (e) {
        debugPrint('Error fetching contacts, will use contact from service table: $e');
        // If the contact table doesn't exist, we'll just use the contact from the service table
      }
      
      // Create emergency services with contact numbers
      return response.map((data) {
        final serviceId = data['id'].toString();
        // Add the contact numbers to the service data before creating the object
        if (serviceContacts.containsKey(serviceId)) {
          data['contacts'] = serviceContacts[serviceId];
        } else if (data['contact'] != null && data['contact'].toString().isNotEmpty) {
          // If we don't have contacts from the contact table, use the contact from the service table
          data['contacts'] = [data['contact'].toString()];
        }
        return EmergencyService.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching services: $e');
      return [];
    }
  }

  // Get all emergency services
  Future<List<EmergencyService>> getAllServices() async {
    try {
      debugPrint('Fetching all services from database');
      final response = await _client
          .from('service')
          .select()
          .order('name');

      debugPrint('All services response: ${response.toString()}');

      if (response.isEmpty) {
        debugPrint('No services found in database');
        return [];
      }

      // Get the list of service IDs
      final serviceIds = response.map<String>((data) => data['id'].toString()).toList();
      
      // Map to store contacts for each service
      final Map<String, List<String>> serviceContacts = {};
      
      try {
        // Fetch contact numbers for these services
        final contactsResponse = await _client
            .from('contact')
            .select()
            .inFilter('service_id', serviceIds);
            
        debugPrint('Found ${contactsResponse.length} contacts for ${serviceIds.length} services');
        
        // Create a map of service ID to list of phone numbers
        for (var contact in contactsResponse) {
          final serviceId = contact['service_id'].toString();
          final phoneNumber = contact['phone_number']?.toString();
          
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            if (!serviceContacts.containsKey(serviceId)) {
              serviceContacts[serviceId] = [];
            }
            serviceContacts[serviceId]!.add(phoneNumber);
          }
        }
      } catch (e) {
        debugPrint('Error fetching contacts, will use contact from service table: $e');
        // If the contact table doesn't exist, we'll just use the contact from the service table
      }
      
      // Create emergency services with contact numbers
      final services = response.map((data) {
        final serviceId = data['id'].toString();
        // Add the contact numbers to the service data before creating the object
        if (serviceContacts.containsKey(serviceId)) {
          data['contacts'] = serviceContacts[serviceId];
        } else if (data['contact'] != null && data['contact'].toString().isNotEmpty) {
          // If we don't have contacts from the contact table, use the contact from the service table
          data['contacts'] = [data['contact'].toString()];
        }
        return EmergencyService.fromJson(data);
      }).toList();
      
      debugPrint('Found ${services.length} total services');
      return services;
    } catch (e) {
      debugPrint('Error fetching all services: $e');
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
    String? contact,
  }) async {
    try {
      debugPrint('Searching services with type: ${type?.name}');
      final cacheParams = {
        'query': query,
        'type': type?.name,
        'region': region,
        'category': category,
        'classification': classification,
        'contact': contact,
      };

      // 🗂 Try loading from cache
      final cached = await ServiceCacheManager.getCachedResult(cacheParams);
      if (cached != null) {
        debugPrint('Returning cached result for: $cacheParams');
        return cached;
      }
      var request = _client.from('service').select();

      if (type != null) {
        final typeString = _getTypeString(type);
        debugPrint('Converted type to string: $typeString');
        // Use ilike for more flexible matching instead of exact equality
        request = request.ilike('type', '%$typeString%');
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

      if (contact != null && contact.isNotEmpty) {
        request = request.eq('contact', contact);
      }

      final response = await request.order('name');
      debugPrint('Search response: ${response.toString()}');

      if (response.isEmpty) {
        debugPrint('No results found in search');
        // Let's try a fallback search without type filtering if we get no results
        if (type != null) {
          debugPrint('Attempting fallback search without type filter');
          final allServices = await getAllServices();
          
          if (allServices.isNotEmpty) {
            debugPrint('Filtering ${allServices.length} services by type: ${type.name}');
            // Filter results on the client side based on type
            final filteredResults = allServices.where((service) => 
                service.type == type || 
                service.name.toLowerCase().contains(_getTypeString(type).toLowerCase()) ||
                (service.description?.toLowerCase() ?? '').contains(_getTypeString(type).toLowerCase())
            ).toList();
            
            if (filteredResults.isNotEmpty) {
              debugPrint('Filtered results: ${filteredResults.length}');
              final finalResults = _calculateDistances(filteredResults);
              await ServiceCacheManager.cacheResult(cacheParams, await finalResults);
              return finalResults;
            }
          }
        }
        return [];
      }

      // Get the list of service IDs
      final serviceIds = response.map<String>((data) => data['id'].toString()).toList();
      
      // Map to store contacts for each service
      final Map<String, List<String>> serviceContacts = {};
      
      try {
        // Fetch contact numbers for these services
        final contactsResponse = await _client
            .from('contact')
            .select()
            .inFilter('service_id', serviceIds);
            
        debugPrint('Found ${contactsResponse.length} contacts for ${serviceIds.length} services in search results');
        
        // Create a map of service ID to list of phone numbers
        for (var contact in contactsResponse) {
          final serviceId = contact['service_id'].toString();
          final phoneNumber = contact['phone_number']?.toString();
          
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            if (!serviceContacts.containsKey(serviceId)) {
              serviceContacts[serviceId] = [];
            }
            serviceContacts[serviceId]!.add(phoneNumber);
          }
        }
      } catch (e) {
        debugPrint('Error fetching contacts, will use contact from service table: $e');
        // If the contact table doesn't exist, we'll just use the contact from the service table
      }
      
      // Create emergency services with contact numbers
      final services = response.map((data) {
        final serviceId = data['id'].toString();
        // Add the contact numbers to the service data before creating the object
        if (serviceContacts.containsKey(serviceId)) {
          data['contacts'] = serviceContacts[serviceId];
        } else if (data['contact'] != null && data['contact'].toString().isNotEmpty) {
          // If we don't have contacts from the contact table, use the contact from the service table
          data['contacts'] = [data['contact'].toString()];
        }
       return EmergencyService.fromJson(data);
      }).toList();
      
      debugPrint('Found ${services.length} services in search');
      final finalResults = _calculateDistances(services);
      await ServiceCacheManager.cacheResult(cacheParams, await finalResults);
      return finalResults;
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }
  
  // Helper method to calculate distances for services
  Future<List<EmergencyService>> _calculateDistances(List<EmergencyService> services) async {
    try {
      // Get the current location
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      
      if (position != null) {
        debugPrint('Calculating distances from current location: ${position.latitude}, ${position.longitude}');
        
        // Calculate distance for each service
        return services.map((service) {
          if (service.latitude != null && service.longitude != null) {
            final distance = locationService.calculateDistance(
              position.latitude,
              position.longitude,
              service.latitude!,
              service.longitude!
            );
            
            // Return a new service with the calculated distance
            return service.copyWith(distanceKm: distance);
          }
          return service;
        }).toList();
      } else {
        debugPrint('Current location not available, using default distances');
        return services;
      }
    } catch (e) {
      debugPrint('Error calculating distances: $e');
      return services;
    }
  }

  // Get all alerts
  Future<List<EmergencyAlert>> getAlerts() async {
    try {
      final response = await _client
          .rpc('fetch_alerts')
          .select();

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => _parseAlert(data)).toList();
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
        'type': alert.type.name.toLowerCase(),
        'source': alert.source,
        'location': alert.location,
        'latitude': alert.latitude,
        'longitude': alert.longitude,
        'is_active': alert.isActive,
        'created_at': DateTime.now().toIso8601String(),
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

  // Get service by ID
  Future<EmergencyService?> getServiceById(String id) async {
    try {
      debugPrint('DatabaseService: Getting service with ID: $id');
      
      // Try to get the service from the database
      final response = await _client
          .from('service')
          .select()
          .eq('id', id)
          .single();
      
      // Get contacts for this service
      List<String> contacts = [];
      try {
        final contactsResponse = await _client
            .from('contact')
            .select()
            .eq('service_id', id);
            
        if (contactsResponse.isNotEmpty) {
          contacts = contactsResponse
              .map<String>((data) => data['phone_number']?.toString() ?? '')
              .where((number) => number.isNotEmpty)
              .toList();
        }
      } catch (e) {
        debugPrint('Error fetching contacts for service $id: $e');
        // If contact table doesn't exist, use the contact from service table
        if (response['contact'] != null && response['contact'].toString().isNotEmpty) {
          contacts = [response['contact'].toString()];
        }
      }
      
      // Add contacts to the service data
      if (contacts.isNotEmpty) {
        response['contacts'] = contacts;
      }
      
      // Create and return the emergency service
      final service = EmergencyService.fromJson(response);
      
      // Calculate distance if location is available
      final locationService = LocationService();
      final currentLocation = await locationService.getCurrentPosition();
      
      if (currentLocation != null && service.latitude != null && service.longitude != null) {
        final distance = locationService.calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          service.latitude!,
          service.longitude!,
        );
        return service.copyWith(distanceKm: distance);
      }
      
      return service;
    } catch (e) {
      debugPrint('Error fetching service by ID: $e');
      return null;
    }
  }

  // Add to history
  Future<bool> addToHistory(String serviceId, String action) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      final userId = user.id;

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
    }
  }

  // Get unique usernames for verification info
  Future<List<String>> getUniqueUsernames() async {
    try {
      final response = await _client
          .from('user')
          .select('username')
          .not('username', 'is', null);

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<String>((data) => data['username']?.toString() ?? '')
          .where((username) => username.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching unique usernames: $e');
      return [];
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
    } else if (typeString.contains('natural') ||
        typeString.contains('disaster')) {
      alertType = AlertType.naturalDisaster;
    } else {
      alertType = AlertType.emergency;
    }

    return EmergencyAlert(
      id: data['id']?.toString() ?? 'unknown',
      title: data['title']?.toString() ?? 'Alert',
      description: data['description']?.toString() ?? 'No description available',
      type: alertType,
      timestamp: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now(),
      source: data['source']?.toString(),
      location: data['location']?.toString(),
      latitude: data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null,
      longitude: data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null,
      isActive: data['is_active'] == true,
    );
  }
}
