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
  final String? contact;
  final List<String> contacts;
  final double? latitude;
  final double? longitude;
  final String? addedBy;
  final String? verifiedBy;

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    this.description,
    required this.distanceKm,
    this.contact,
    List<String>? contacts,
    this.latitude,
    this.longitude,
    this.addedBy,
    this.verifiedBy,
  }) : contacts = contacts ?? (contact != null ? [contact] : []);

  // Create a copy with modified properties
  EmergencyService copyWith({
    String? id,
    String? name,
    ServiceType? type,
    String? level,
    String? description,
    double? distanceKm,
    String? contact,
    List<String>? contacts,
    double? latitude,
    double? longitude,
    String? addedBy,
    String? verifiedBy,
  }) {
    return EmergencyService(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      level: level ?? this.level,
      description: description ?? this.description,
      distanceKm: distanceKm ?? this.distanceKm,
      contact: contact ?? this.contact,
      contacts: contacts ?? this.contacts,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addedBy: addedBy ?? this.addedBy,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  factory EmergencyService.fromJson(Map<String, dynamic> json) {
    // Determine the service type by comparing lowercase strings
    ServiceType serviceType;
    final typeString = (json['type'] ?? '').toString().toLowerCase();
    
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
    
    // Handle distance_km which might be null or a different type
    double distanceKm = 0.0;
    if (json['distance_km'] != null) {
      if (json['distance_km'] is double) {
        distanceKm = json['distance_km'];
      } else if (json['distance_km'] is int) {
        distanceKm = (json['distance_km'] as int).toDouble();
      } else if (json['distance_km'] is String) {
        distanceKm = double.tryParse(json['distance_km']) ?? 0.0;
      }
    }
    
    // Create with default verification data for development purposes
    return EmergencyService(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Service',
      type: serviceType,
      level: json['level'] ?? 'Standard',
      description: json['description'],
      distanceKm: distanceKm,
      contact: json['contact'],
      contacts: json['contacts'] != null ? List<String>.from(json['contacts']) : 
               (json['contact'] != null ? [json['contact']] : []),
      latitude: json['latitude'] is double ? json['latitude'] : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null),
      longitude: json['longitude'] is double ? json['longitude'] : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null),
      // Hard-coded values for development
      addedBy: json['added_by'] ?? "John Doe",
      verifiedBy: json['verified_by'] ?? "Enzo Panugayan",
    );
  }
}
