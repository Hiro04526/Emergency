import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import 'database_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Database service
  final DatabaseService _databaseService = DatabaseService();

  // Cache for emergency services
  final Map<ServiceType, List<EmergencyService>> _servicesCache = {};

  // Get emergency services by type
  Future<List<EmergencyService>> getServicesByType(ServiceType type) async {
    // Check if data is already in cache
    if (_servicesCache.containsKey(type)) {
      return _servicesCache[type]!;
    }

    try {
      // Try to get data from the database first
      final services = await _databaseService.getServicesByType(type);
      
      // If we got data from the database, cache and return it
      if (services.isNotEmpty) {
        _servicesCache[type] = services;
        return services;
      }
      
      // If no data from database, fall back to mock data
      debugPrint('No data found in database for ${type.name}, using mock data');
      final mockServices = _getMockServices(type);
      
      // Cache the results
      _servicesCache[type] = mockServices;
      
      return mockServices;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      
      // Fall back to mock data on error
      final mockServices = _getMockServices(type);
      _servicesCache[type] = mockServices;
      return mockServices;
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
      // Try to search in the database first
      final services = await _databaseService.searchServices(
        query: query,
        type: type,
        region: region,
        category: category,
        classification: classification,
      );
      
      // If we got data from the database, return it
      if (services.isNotEmpty) {
        return services;
      }
      
      // If no data from database, fall back to mock data
      debugPrint('No search results found in database, using mock data');
      
      // Get all services
      List<EmergencyService> allServices = [];
      for (var serviceType in ServiceType.values) {
        final services = await getServicesByType(serviceType);
        allServices.addAll(services);
      }
      
      // Filter by query if provided
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        allServices = allServices.where((service) {
          return service.name.toLowerCase().contains(lowerQuery) ||
              (service.description?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
      
      // Filter by type if provided
      if (type != null) {
        allServices = allServices.where((service) => service.type == type).toList();
      }
      
      return allServices;
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }

  // Get service by ID
  Future<EmergencyService?> getServiceById(String id) async {
    try {
      // Try to get all services from cache first
      List<EmergencyService> allServices = [];
      for (var services in _servicesCache.values) {
        allServices.addAll(services);
      }
      
      // Look for the service in the cache
      final cachedService = allServices.where((service) => service.id == id).firstOrNull;
      if (cachedService != null) {
        return cachedService;
      }
      
      // If not in cache, try to get all services
      for (var type in ServiceType.values) {
        final services = await getServicesByType(type);
        final service = services.where((service) => service.id == id).firstOrNull;
        if (service != null) {
          return service;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting service by ID: $e');
      return null;
    }
  }

  // Mock data for emergency services
  List<EmergencyService> _getMockServices(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return [
          EmergencyService(
            id: 'police-1',
            name: 'Marikina City Police Station',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Marikina City Police Station is the main police station serving Marikina City. The station is responsible for maintaining law and order, preventing and investigating crimes, and ensuring public safety within the city limits. The station has a team of well-trained police officers ready to respond to emergencies and assist citizens 24/7.',
            distanceKm: 1.2,
            phoneNumber: '(02) 8646 2577',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'police-2',
            name: 'Quezon City Police Station',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Quezon City Police Station is the main police station serving Quezon City. The station is responsible for maintaining law and order, preventing and investigating crimes, and ensuring public safety within the city limits. The station has a team of well-trained police officers ready to respond to emergencies and assist citizens 24/7.',
            distanceKm: 3.5,
            phoneNumber: '(02) 8925 8326',
            latitude: 14.6760,
            longitude: 121.0437,
          ),
          EmergencyService(
            id: 'police-3',
            name: 'Manila Police District',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Manila Police District is the main police district serving the City of Manila. The district is responsible for maintaining law and order, preventing and investigating crimes, and ensuring public safety within the city limits. The district has a team of well-trained police officers ready to respond to emergencies and assist citizens 24/7.',
            distanceKm: 7.8,
            phoneNumber: '(02) 8523 3396',
            latitude: 14.5995,
            longitude: 120.9842,
          ),
          EmergencyService(
            id: 'police-4',
            name: 'National Bureau of Investigation',
            type: ServiceType.police,
            level: 'National Level',
            description: 'The National Bureau of Investigation (NBI) is the primary investigative agency of the Philippine government. The bureau is responsible for handling complex criminal cases, conducting forensic examinations, and providing technical assistance to other law enforcement agencies. The NBI has a team of highly trained agents and specialists ready to handle various types of investigations.',
            distanceKm: 8.2,
            phoneNumber: '(02) 8523 8231',
            latitude: 14.5869,
            longitude: 120.9830,
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
            name: 'St. Luke\'s Medical Center',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'St. Luke\'s Medical Center in Quezon City is a world-class hospital known for its excellent medical care and advanced facilities. The emergency department is equipped with the latest medical technology and staffed by highly trained emergency medicine specialists. The hospital offers ground and air ambulance services with medical teams capable of providing critical care during transport.',
            distanceKm: 6.2,
            phoneNumber: '(02) 8723 0101',
            latitude: 14.6262,
            longitude: 121.0247,
          ),
          EmergencyService(
            id: 'ambulance-5',
            name: 'Philippine Red Cross - Marikina Chapter',
            type: ServiceType.medical,
            level: 'Non-Governmental Organization',
            description: 'The Philippine Red Cross Marikina Chapter provides emergency response services including ambulance dispatch, first aid, and disaster relief. Their ambulance services are available 24/7 for medical emergencies and transport of patients. The chapter also conducts regular training for emergency responders and community members in basic life support and first aid.',
            distanceKm: 1.5,
            phoneNumber: '143',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'ambulance-6',
            name: 'East Avenue Medical Center',
            type: ServiceType.medical,
            level: 'Hospital',
            description: 'East Avenue Medical Center is a government hospital providing comprehensive healthcare services to the public. The emergency department operates 24/7 and handles all types of emergencies including trauma, cardiac, and pediatric cases. The hospital has a dedicated ambulance service for patient transport and emergency response within Metro Manila.',
            distanceKm: 7.8,
            phoneNumber: '(02) 8928 0611',
            latitude: 14.6431,
            longitude: 121.0429,
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
            name: 'Bureau of Fire Protection - National Headquarters',
            type: ServiceType.fireStation,
            level: 'National Level',
            description: 'The Bureau of Fire Protection (BFP) National Headquarters oversees all fire protection and prevention services in the Philippines. The bureau is responsible for enforcing fire safety regulations, conducting fire safety inspections, and coordinating firefighting operations nationwide. The headquarters has a team of experienced fire officers and administrators managing fire protection services across the country.',
            distanceKm: 7.8,
            phoneNumber: '(02) 8426 0219',
            latitude: 14.6431,
            longitude: 121.0429,
          ),
          EmergencyService(
            id: 'fire-5',
            name: 'Manila Fire Station',
            type: ServiceType.fireStation,
            level: 'City/Local Level',
            description: 'Manila Fire Station is the main fire station serving the City of Manila. The station is equipped with modern firefighting equipment and vehicles, including fire trucks, water tankers, and rescue vehicles. The station has a team of well-trained firefighters ready to respond to fire emergencies, rescue operations, and other related incidents 24/7.',
            distanceKm: 8.5,
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
            description: 'Marikina City Hall is the seat of the local government of Marikina City. The city hall houses various government offices and departments responsible for providing public services to the residents of Marikina. The city hall also serves as a coordination center during emergencies and disasters affecting the city.',
            distanceKm: 2.2,
            phoneNumber: '(02) 8646 2360',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'gov-2',
            name: 'Office of Civil Defense - National Disaster Risk Reduction and Management Council',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The Office of Civil Defense (OCD) serves as the implementing arm of the National Disaster Risk Reduction and Management Council (NDRRMC). The office is responsible for coordinating disaster preparedness, prevention, mitigation, response, and rehabilitation efforts at the national level. The OCD operates the National Disaster Risk Reduction and Management Operations Center, which monitors and responds to disasters and emergencies nationwide.',
            distanceKm: 6.5,
            phoneNumber: '(02) 8911 1406',
            latitude: 14.6431,
            longitude: 121.0429,
          ),
          EmergencyService(
            id: 'gov-3',
            name: 'Department of Social Welfare and Development - National Resource Operations Center',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The Department of Social Welfare and Development (DSWD) National Resource Operations Center is responsible for managing and distributing relief goods and providing social services during disasters and emergencies. The center coordinates with local government units and other agencies to ensure timely and efficient delivery of assistance to affected communities.',
            distanceKm: 7.2,
            phoneNumber: '(02) 8931 8101',
            latitude: 14.6431,
            longitude: 121.0429,
          ),
          EmergencyService(
            id: 'gov-4',
            name: 'Philippine Atmospheric, Geophysical and Astronomical Services Administration',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAGASA) is the national meteorological and hydrological service provider of the Philippines. PAGASA is responsible for providing weather forecasts, warnings, and advisories for public safety and disaster preparedness. The agency operates weather stations and monitoring systems across the country to track weather patterns and natural hazards.',
            distanceKm: 8.0,
            phoneNumber: '(02) 8926 4258',
            latitude: 14.6431,
            longitude: 121.0429,
          ),
          EmergencyService(
            id: 'gov-5',
            name: 'Philippine Institute of Volcanology and Seismology',
            type: ServiceType.government,
            level: 'National Level',
            description: 'The Philippine Institute of Volcanology and Seismology (PHIVOLCS) is the government agency responsible for monitoring and studying volcanic activities and earthquakes in the Philippines. PHIVOLCS provides warnings and advisories on volcanic eruptions, earthquakes, and tsunamis to help protect communities from these natural hazards. The institute operates a network of monitoring stations across the country to detect and analyze seismic and volcanic activities.',
            distanceKm: 8.1,
            phoneNumber: '(02) 8426 1468',
            latitude: 14.6431,
            longitude: 121.0429,
          ),
        ];
    }
  }
}
