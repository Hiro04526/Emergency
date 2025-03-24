import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import 'database_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cache for emergency services
  final Map<ServiceType, List<EmergencyService>> _servicesCache = {};
  
  // Reference to database service (will be initialized later)
  DatabaseService? _databaseService;
  
  // Set database service
  void setDatabaseService(DatabaseService databaseService) {
    _databaseService = databaseService;
  }

  // Get emergency services by type
  Future<List<EmergencyService>> getServicesByType(ServiceType type) async {
    // Check if data is already in cache
    if (_servicesCache.containsKey(type)) {
      return _servicesCache[type]!;
    }

    try {
      List<EmergencyService> services;
      
      // Try to fetch from database if available
      if (_databaseService != null) {
        services = await _databaseService!.getServicesByType(type);
        
        // If no services found in database, fall back to mock data
        if (services.isEmpty) {
          services = _getMockServices(type);
        }
      } else {
        // Fall back to mock data if database service is not available
        services = _getMockServices(type);
      }
      
      // Cache the results
      _servicesCache[type] = services;
      
      return services;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      // Fall back to mock data on error
      final services = _getMockServices(type);
      _servicesCache[type] = services;
      return services;
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
      // Try to search using database service if available
      if (_databaseService != null) {
        return await _databaseService!.searchServices(
          query: query,
          type: type,
          region: region,
          city: category, // Using city as category for now
        );
      }
      
      // Fall back to mock data search if database service is not available
      // Get all services
      List<EmergencyService> allServices = [];
      for (var serviceType in ServiceType.values) {
        allServices.addAll(await getServicesByType(serviceType));
      }

      // Filter by query
      if (query != null && query.isNotEmpty) {
        allServices = allServices.where((service) => 
          service.name.toLowerCase().contains(query.toLowerCase()) ||
          (service.description != null && 
           service.description!.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }

      // Filter by type
      if (type != null) {
        allServices = allServices.where((service) => service.type == type).toList();
      }

      // Filter by region (simplified for mock data)
      if (region != null && region.isNotEmpty) {
        allServices = allServices.where((service) => 
          service.name.toLowerCase().contains(region.toLowerCase())
        ).toList();
      }

      return allServices;
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }

  // Get service details by ID
  Future<EmergencyService?> getServiceById(String id) async {
    try {
      // Try to fetch from database if available
      if (_databaseService != null) {
        // Get all services and find the one with matching ID
        final allServices = await _databaseService!.getAllServices();
        try {
          return allServices.firstWhere((service) => service.id == id);
        } catch (e) {
          // Service not found in database
        }
      }
      
      // Fall back to mock data if database service is not available or service not found
      // First, check if we need to load any service types
      if (_servicesCache.isEmpty) {
        // Pre-load all service types
        for (var type in ServiceType.values) {
          await getServicesByType(type);
        }
      }
      
      // Now search through all cached services
      for (var services in _servicesCache.values) {
        try {
          final service = services.firstWhere(
            (service) => service.id == id,
          );
          return service;
        } catch (e) {
          // Service not found in this type, continue to next type
          continue;
        }
      }
      
      // If we got here, we didn't find the service in any cached data
      // Let's try to load all service types again in case the cache was incomplete
      for (var type in ServiceType.values) {
        final services = _getMockServices(type);
        for (var service in services) {
          if (service.id == id) {
            return service;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching service details: $e');
      return null;
    }
  }

  // Add a new service
  Future<String?> addService({
    required String name,
    required ServiceType type,
    required String category,
    required String address,
    required String region,
    required String province,
    required String city,
    required String barangay,
    String? street,
    List<String>? phoneNumbers,
    double? latitude,
    double? longitude,
    String? userId,
  }) async {
    try {
      if (_databaseService != null) {
        return await _databaseService!.addService(
          name: name,
          type: type,
          category: category,
          address: address,
          region: region,
          province: province,
          city: city,
          barangay: barangay,
          street: street,
          phoneNumbers: phoneNumbers,
          latitude: latitude,
          longitude: longitude,
          userId: userId,
        );
      }
      
      // If database service is not available, return null
      return null;
    } catch (e) {
      debugPrint('Error adding service: $e');
      return null;
    }
  }

  // Report a service
  Future<bool> reportService(String serviceId, String userId) async {
    try {
      if (_databaseService != null) {
        return await _databaseService!.reportService(serviceId);
      }
      
      // If database service is not available, return false
      return false;
    } catch (e) {
      debugPrint('Error reporting service: $e');
      return false;
    }
  }

  // Mock data generator
  List<EmergencyService> _getMockServices(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return [
          EmergencyService(
            id: 'police-1',
            name: 'Police Station 15 (Fortune)',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Local police station serving the Fortune area',
            distanceKm: 1.1,
            phoneNumber: '(02) 8942 3478',
            latitude: 14.5547,
            longitude: 121.0244,
          ),
          EmergencyService(
            id: 'police-2',
            name: 'Marikina Police Station 9',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Local police station serving Marikina area',
            distanceKm: 2.6,
            phoneNumber: '(02) 8942 0572',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'police-3',
            name: 'Quezon City Police Station 4',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Local police station serving Quezon City area',
            distanceKm: 3.8,
            phoneNumber: '(02) 8925 8146',
            latitude: 14.6760,
            longitude: 121.0437,
          ),
          EmergencyService(
            id: 'police-4',
            name: 'PNP National Headquarters',
            type: ServiceType.police,
            level: 'National Level',
            description: 'Philippine National Police headquarters',
            distanceKm: 7.2,
            phoneNumber: '(02) 8723 0401',
            latitude: 14.6089,
            longitude: 121.0193,
          ),
          EmergencyService(
            id: 'police-5',
            name: 'Pasig City Police Station',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Local police station serving Pasig City area',
            distanceKm: 5.5,
            phoneNumber: '(02) 8643 2105',
            latitude: 14.5762,
            longitude: 121.0851,
          ),
        ];
      case ServiceType.medical:
        return [
          EmergencyService(
            id: 'ambulance-1',
            name: 'Marikina Valley Medical Center',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'Marikina Valley Medical Center is a tertiary hospital providing comprehensive healthcare services including 24/7 emergency care, trauma services, and ambulance dispatch. The emergency department is equipped with modern facilities and staffed by experienced physicians and nurses specialized in emergency medicine.',
            distanceKm: 1.8,
            phoneNumber: '(02) 8941 5555',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'ambulance-2',
            name: 'Amang Rodriguez Memorial Medical Center',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'Amang Rodriguez Memorial Medical Center is a government hospital under the Department of Health providing affordable healthcare services to the public. The emergency department operates 24/7 with ambulance services available for critical cases. The hospital specializes in trauma care, maternal and child health, and infectious diseases.',
            distanceKm: 2.3,
            phoneNumber: '(02) 8941 2009',
            latitude: 14.6198,
            longitude: 121.0998,
          ),
          EmergencyService(
            id: 'ambulance-3',
            name: 'The Medical City',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'The Medical City is a premier healthcare institution with state-of-the-art facilities and advanced medical technology. The emergency department provides immediate care for all types of emergencies with dedicated trauma bays, isolation rooms, and a team of board-certified emergency physicians available 24/7. The hospital also offers air ambulance services for critical cases.',
            distanceKm: 4.7,
            phoneNumber: '(02) 8988 1000',
            latitude: 14.5883,
            longitude: 121.0614,
          ),
          EmergencyService(
            id: 'ambulance-4',
            name: 'St. Luke\'s Medical Center - QC',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'St. Luke\'s Medical Center in Quezon City is a world-class hospital known for its excellent medical care and advanced facilities. The emergency department is equipped with the latest medical technology and staffed by highly trained emergency medicine specialists. The hospital offers ground and air ambulance services with medical teams capable of providing critical care during transport.',
            distanceKm: 5.2,
            phoneNumber: '(02) 8723 0101',
            latitude: 14.6167,
            longitude: 121.0333,
          ),
          EmergencyService(
            id: 'ambulance-5',
            name: 'Philippine Red Cross - Marikina Chapter',
            type: ServiceType.medical,
            level: 'NGO',
            description: 'The Philippine Red Cross Marikina Chapter provides emergency response services including ambulance dispatch, first aid, and disaster relief. Their ambulance services are available 24/7 for medical emergencies and transport of patients. The chapter also conducts regular training for emergency responders and community members in basic life support and first aid.',
            distanceKm: 2.1,
            phoneNumber: '143',
            latitude: 14.6290,
            longitude: 121.0950,
          ),
          EmergencyService(
            id: 'ambulance-6',
            name: 'East Avenue Medical Center',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'East Avenue Medical Center is a government hospital providing comprehensive healthcare services to the public. The emergency department operates 24/7 and handles all types of emergencies including trauma, cardiac, and pediatric cases. The hospital has a dedicated ambulance service for patient transport and emergency response within Metro Manila.',
            distanceKm: 6.8,
            phoneNumber: '(02) 8928 0611',
            latitude: 14.6431,
            longitude: 121.0517,
          ),
          EmergencyService(
            id: 'ambulance-7',
            name: 'Makati Medical Center',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'Makati Medical Center is a premier hospital known for its excellence in healthcare services. The emergency department is staffed by board-certified emergency physicians and specially trained nurses available 24/7. The hospital offers advanced ambulance services equipped with life-saving equipment and staffed by paramedics trained in advanced cardiac life support.',
            distanceKm: 9.5,
            phoneNumber: '(02) 8888 8999',
            latitude: 14.5650,
            longitude: 121.0142,
          ),
        ];
      case ServiceType.fireStation:
        return [
          EmergencyService(
            id: 'fire-1',
            name: 'Marikina City Fire Station',
            type: ServiceType.fireStation,
            level: 'City/Local Level',
            description: 'Marikina City Fire Station is the main fire station serving Marikina City. The station is equipped with modern firefighting equipment and vehicles, including fire trucks, water tankers, and rescue vehicles. The station has a team of well-trained firefighters ready to respond to fire emergencies, rescue operations, and other related incidents 24/7.',
            distanceKm: 2.0,
            phoneNumber: '(02) 8646 2298',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'fire-2',
            name: 'Quezon City Fire Station',
            type: ServiceType.fireStation,
            level: 'City/Local Level',
            description: 'Quezon City Fire Station is the main fire station serving Quezon City. The station is equipped with modern firefighting equipment and vehicles, including fire trucks, water tankers, and rescue vehicles. The station has a team of well-trained firefighters ready to respond to fire emergencies, rescue operations, and other related incidents 24/7.',
            distanceKm: 4.3,
            phoneNumber: '(02) 8924 1922',
            latitude: 14.6760,
            longitude: 121.0437,
          ),
          EmergencyService(
            id: 'fire-3',
            name: 'Pasig City Fire Station',
            type: ServiceType.fireStation,
            level: 'City/Local Level',
            description: 'Pasig City Fire Station is the main fire station serving Pasig City. The station is equipped with modern firefighting equipment and vehicles, including fire trucks, water tankers, and rescue vehicles. The station has a team of well-trained firefighters ready to respond to fire emergencies, rescue operations, and other related incidents 24/7.',
            distanceKm: 5.1,
            phoneNumber: '(02) 8631 0099',
            latitude: 14.5762,
            longitude: 121.0851,
          ),
          EmergencyService(
            id: 'fire-4',
            name: 'Makati City Fire Station',
            type: ServiceType.fireStation,
            level: 'City/Local Level',
            description: 'Makati City Fire Station is the main fire station serving Makati City. The station is equipped with modern firefighting equipment and vehicles, including fire trucks, water tankers, and rescue vehicles. The station has a team of well-trained firefighters ready to respond to fire emergencies, rescue operations, and other related incidents 24/7.',
            distanceKm: 8.9,
            phoneNumber: '(02) 8818 5150',
            latitude: 14.5548,
            longitude: 121.0244,
          ),
          EmergencyService(
            id: 'fire-5',
            name: 'Manila City Fire Station',
            type: ServiceType.fireStation,
            level: 'City/Local Level',
            description: 'Manila City Fire Station is the main fire station serving Manila City. The station is equipped with modern firefighting equipment and vehicles, including fire trucks, water tankers, and rescue vehicles. The station has a team of well-trained firefighters ready to respond to fire emergencies, rescue operations, and other related incidents 24/7.',
            distanceKm: 9.7,
            phoneNumber: '(02) 8527 3653',
            latitude: 14.5995,
            longitude: 120.9842,
          ),
        ];
      case ServiceType.government:
        return [
          EmergencyService(
            id: 'gov-1',
            name: 'Marikina City Hall',
            type: ServiceType.government,
            level: 'City/Local Level',
            description: 'Marikina City Hall is the seat of the local government of Marikina City. It houses various government offices and services including the Office of the Mayor, City Council, City Health Office, and the Disaster Risk Reduction and Management Office. The City Hall coordinates emergency response efforts during disasters and emergencies in the city.',
            distanceKm: 2.2,
            phoneNumber: '(02) 8646 2360',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'gov-2',
            name: 'NDRRMC Operations Center',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The National Disaster Risk Reduction and Management Council (NDRRMC) Operations Center is the central command center for disaster response and management in the Philippines. The center coordinates the national government\'s response to disasters and emergencies, including the deployment of resources and personnel. The center operates 24/7 and is equipped with advanced communication and monitoring systems.',
            distanceKm: 7.5,
            phoneNumber: '(02) 8911 1406',
            latitude: 14.6352,
            longitude: 121.0724,
          ),
          EmergencyService(
            id: 'gov-3',
            name: 'MMDA Metrobase',
            type: ServiceType.government,
            level: 'Metropolitan Level',
            description: 'The Metropolitan Manila Development Authority (MMDA) Metrobase is the command center for traffic management and emergency response in Metro Manila. The center coordinates the MMDA\'s response to traffic incidents, floods, and other emergencies in the metropolis. The center operates 24/7 and is equipped with CCTV cameras and communication systems for monitoring and coordination.',
            distanceKm: 6.3,
            phoneNumber: '136',
            latitude: 14.5889,
            longitude: 121.0514,
          ),
          EmergencyService(
            id: 'gov-4',
            name: 'DSWD Central Office',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The Department of Social Welfare and Development (DSWD) Central Office coordinates social welfare and relief operations during disasters and emergencies. The department provides food, shelter, and other basic necessities to affected populations. The DSWD also operates the Quick Response Team for immediate response to emergencies.',
            distanceKm: 8.1,
            phoneNumber: '(02) 8931 8101',
            latitude: 14.6417,
            longitude: 121.0500,
          ),
          EmergencyService(
            id: 'gov-5',
            name: 'DOH Central Office',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The Department of Health (DOH) Central Office coordinates health emergency response and management in the Philippines. The department provides medical assistance, supplies, and personnel during health emergencies and disasters. The DOH also operates the Health Emergency Management Bureau for immediate response to health emergencies.',
            distanceKm: 7.8,
            phoneNumber: '(02) 8651 7800',
            latitude: 14.6417,
            longitude: 121.0500,
          ),
        ];
    }
  }
}
