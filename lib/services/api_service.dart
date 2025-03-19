import 'package:flutter/material.dart';
import '../models/emergency_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cache for emergency services
  final Map<ServiceType, List<EmergencyService>> _servicesCache = {};

  // Get emergency services by type
  Future<List<EmergencyService>> getServicesByType(ServiceType type) async {
    // Check if data is already in cache
    if (_servicesCache.containsKey(type)) {
      return _servicesCache[type]!;
    }

    // In a real app, you would make an actual API call here
    // For now, we'll return mock data
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      final services = _getMockServices(type);
      
      // Cache the results
      _servicesCache[type] = services;
      
      return services;
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
    // In a real app, you would make an API call with these parameters
    // For now, we'll filter our mock data
    try {
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
    // In a real app, you would make an API call to get details for a specific service
    // For now, we'll search our mock data
    try {
      for (var type in ServiceType.values) {
        final services = await getServicesByType(type);
        final service = services.firstWhere(
          (service) => service.id == id,
          orElse: () => throw Exception('Service not found'),
        );
        return service;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching service details: $e');
      return null;
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
            name: 'Marikina City Police Station PCP-8',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Police Community Precinct in Marikina City',
            distanceKm: 3.2,
            phoneNumber: '(02) 8942 6101',
            latitude: 14.6392,
            longitude: 121.1052,
          ),
          EmergencyService(
            id: 'police-4',
            name: 'Quezon City Police District Station 4',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Police station serving Novaliches area',
            distanceKm: 4.5,
            phoneNumber: '(02) 8961 8534',
            latitude: 14.7021,
            longitude: 121.0432,
          ),
          EmergencyService(
            id: 'police-5',
            name: 'Manila Police District Station 3',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Police station serving Sta. Cruz area',
            distanceKm: 5.8,
            phoneNumber: '(02) 8523 4567',
            latitude: 14.6012,
            longitude: 120.9823,
          ),
          EmergencyService(
            id: 'police-6',
            name: 'Pasig City Police Station',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Main police station in Pasig City',
            distanceKm: 6.3,
            phoneNumber: '(02) 8642 1234',
            latitude: 14.5762,
            longitude: 121.0851,
          ),
          EmergencyService(
            id: 'police-7',
            name: 'Taguig City Police Station',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Main police station in Taguig City',
            distanceKm: 8.7,
            phoneNumber: '(02) 8837 5678',
            latitude: 14.5271,
            longitude: 121.0518,
          ),
          EmergencyService(
            id: 'police-8',
            name: 'Makati City Police Station',
            type: ServiceType.police,
            level: 'City/Local Level',
            description: 'Main police station in Makati City',
            distanceKm: 9.2,
            phoneNumber: '(02) 8899 9123',
            latitude: 14.5548,
            longitude: 121.0244,
          ),
        ];
      case ServiceType.ambulance:
        return [
          EmergencyService(
            id: 'ambulance-1',
            name: 'Marikina Valley Medical Center',
            type: ServiceType.ambulance,
            level: 'Hospital',
            description: 'Emergency medical services and ambulance',
            distanceKm: 1.8,
            phoneNumber: '(02) 8941 5555',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'ambulance-2',
            name: 'Amang Rodriguez Memorial Medical Center',
            type: ServiceType.ambulance,
            level: 'Hospital',
            description: 'Government hospital with emergency services',
            distanceKm: 2.3,
            phoneNumber: '(02) 8941 2009',
            latitude: 14.6198,
            longitude: 121.0998,
          ),
          EmergencyService(
            id: 'ambulance-3',
            name: 'The Medical City',
            type: ServiceType.ambulance,
            level: 'Hospital',
            description: 'Private hospital with 24/7 emergency services',
            distanceKm: 4.7,
            phoneNumber: '(02) 8988 1000',
            latitude: 14.5883,
            longitude: 121.0614,
          ),
          EmergencyService(
            id: 'ambulance-4',
            name: 'St. Luke\'s Medical Center - QC',
            type: ServiceType.ambulance,
            level: 'Hospital',
            description: 'Premier hospital with advanced emergency care',
            distanceKm: 5.2,
            phoneNumber: '(02) 8723 0101',
            latitude: 14.6167,
            longitude: 121.0333,
          ),
          EmergencyService(
            id: 'ambulance-5',
            name: 'Philippine Red Cross - Marikina Chapter',
            type: ServiceType.ambulance,
            level: 'NGO',
            description: 'Emergency response and ambulance services',
            distanceKm: 2.1,
            phoneNumber: '143',
            latitude: 14.6290,
            longitude: 121.0950,
          ),
          EmergencyService(
            id: 'ambulance-6',
            name: 'East Avenue Medical Center',
            type: ServiceType.ambulance,
            level: 'Hospital',
            description: 'Government hospital with emergency services',
            distanceKm: 6.8,
            phoneNumber: '(02) 8928 0611',
            latitude: 14.6431,
            longitude: 121.0517,
          ),
          EmergencyService(
            id: 'ambulance-7',
            name: 'Makati Medical Center',
            type: ServiceType.ambulance,
            level: 'Hospital',
            description: 'Private hospital with 24/7 emergency services',
            distanceKm: 9.5,
            phoneNumber: '(02) 8888 8999',
            latitude: 14.5650,
            longitude: 121.0142,
          ),
        ];
      case ServiceType.firetruck:
        return [
          EmergencyService(
            id: 'fire-1',
            name: 'Marikina City Fire Station',
            type: ServiceType.firetruck,
            level: 'City/Local Level',
            description: 'Main fire station serving Marikina City',
            distanceKm: 2.0,
            phoneNumber: '(02) 8646 2298',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'fire-2',
            name: 'Quezon City Fire Station',
            type: ServiceType.firetruck,
            level: 'City/Local Level',
            description: 'Main fire station serving Quezon City',
            distanceKm: 4.3,
            phoneNumber: '(02) 8924 1922',
            latitude: 14.6760,
            longitude: 121.0437,
          ),
          EmergencyService(
            id: 'fire-3',
            name: 'Pasig City Fire Station',
            type: ServiceType.firetruck,
            level: 'City/Local Level',
            description: 'Main fire station serving Pasig City',
            distanceKm: 5.1,
            phoneNumber: '(02) 8631 0099',
            latitude: 14.5762,
            longitude: 121.0851,
          ),
          EmergencyService(
            id: 'fire-4',
            name: 'San Juan City Fire Station',
            type: ServiceType.firetruck,
            level: 'City/Local Level',
            description: 'Main fire station serving San Juan City',
            distanceKm: 6.2,
            phoneNumber: '(02) 8725 2079',
            latitude: 14.6000,
            longitude: 121.0333,
          ),
          EmergencyService(
            id: 'fire-5',
            name: 'Mandaluyong City Fire Station',
            type: ServiceType.firetruck,
            level: 'City/Local Level',
            description: 'Main fire station serving Mandaluyong City',
            distanceKm: 7.4,
            phoneNumber: '(02) 8534 2222',
            latitude: 14.5833,
            longitude: 121.0333,
          ),
          EmergencyService(
            id: 'fire-6',
            name: 'Makati City Fire Station',
            type: ServiceType.firetruck,
            level: 'City/Local Level',
            description: 'Main fire station serving Makati City',
            distanceKm: 9.3,
            phoneNumber: '(02) 8818 5150',
            latitude: 14.5548,
            longitude: 121.0244,
          ),
        ];
      case ServiceType.government:
        return [
          EmergencyService(
            id: 'gov-1',
            name: 'Marikina City Hall',
            type: ServiceType.government,
            level: 'City Government',
            description: 'Local government office of Marikina City',
            distanceKm: 2.0,
            phoneNumber: '(02) 8646 2360',
            latitude: 14.6292,
            longitude: 121.0952,
          ),
          EmergencyService(
            id: 'gov-2',
            name: 'MMDA Emergency Response Unit',
            type: ServiceType.government,
            level: 'Metropolitan',
            description: 'Metro Manila Development Authority emergency services',
            distanceKm: 4.5,
            phoneNumber: '136',
            latitude: 14.5869,
            longitude: 121.0644,
          ),
          EmergencyService(
            id: 'gov-3',
            name: 'NDRRMC Operations Center',
            type: ServiceType.government,
            level: 'National',
            description: 'National Disaster Risk Reduction and Management Council',
            distanceKm: 8.7,
            phoneNumber: '(02) 8911 1406',
            latitude: 14.6542,
            longitude: 121.0614,
          ),
        ];
    }
  }
}
