import 'package:flutter/material.dart';

enum ServiceType { police, medical, fireStation, government }

extension ServiceTypeExtension on ServiceType {
  String get name {
    switch (this) {
      case ServiceType.police:
        return 'Police';
      case ServiceType.medical:
        return 'Medical';
      case ServiceType.fireStation:
        return 'Fire Station';
      case ServiceType.government:
        return 'Government';
    }
  }

  String get iconPath {
    switch (this) {
      case ServiceType.police:
        return 'assets/icons/police_icon.png';
      case ServiceType.medical:
        return 'assets/icons/ambulance_icon.png';
      case ServiceType.fireStation:
        return 'assets/icons/firetruck_icon.png';
      case ServiceType.government:
        return 'assets/icons/government_icon.png';
    }
  }

  Color get color {
    switch (this) {
      case ServiceType.police:
        return const Color(0xFF2D7FF9);
      case ServiceType.medical:
        return const Color(0xFFE53935);
      case ServiceType.fireStation:
        return const Color(0xFFFF8C00);
      case ServiceType.government:
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575); // Default gray color
    }
  }
}

class EmergencyService {
  final String id;
  final String name;
  final ServiceType type;
  final String level;
  final String? description;
  final double distanceKm;
  final String? phoneNumber;
  final List<String> phoneNumbers;
  final double? latitude;
  final double? longitude;

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    this.description,
    required this.distanceKm,
    this.phoneNumber,
    List<String>? phoneNumbers,
    this.latitude,
    this.longitude,
  }) : phoneNumbers = phoneNumbers ?? (phoneNumber != null ? [phoneNumber] : []);

  factory EmergencyService.fromJson(Map<String, dynamic> json) {
    List<String>? phoneNumbersList;
    
    if (json['phone_numbers'] != null) {
      phoneNumbersList = List<String>.from(json['phone_numbers']);
    }
    
    // Determine the service type by comparing lowercase strings
    ServiceType serviceType;
    final typeString = json['type']?.toString().toLowerCase() ?? '';
    
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
      id: json['id'],
      name: json['name'],
      type: serviceType,
      level: json['level'],
      description: json['description'],
      distanceKm: json['distance_km'],
      phoneNumber: json['phone_number'],
      phoneNumbers: phoneNumbersList ?? (json['phone_number'] != null ? [json['phone_number']] : []),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
