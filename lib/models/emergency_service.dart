import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'emergency_service.g.dart';

@HiveType(typeId: 1)
enum ServiceType {
  @HiveField(0)
  police,

  @HiveField(1)
  medical,

  @HiveField(2)
  fireStation,

  @HiveField(3)
  government,
}

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
    }
  }
}

@HiveType(typeId: 0)
class EmergencyService extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ServiceType type;

  @HiveField(3)
  final String level;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final double distanceKm;

  @HiveField(6)
  final String? contact;

  @HiveField(7)
  final List<String> contacts;

  @HiveField(8)
  final double? latitude;

  @HiveField(9)
  final double? longitude;

  @HiveField(10)
  final bool isVerified;

  @HiveField(11)
  final String? addedBy;

  @HiveField(12)
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
    this.isVerified = false,
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
    bool? isVerified,
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
      isVerified: isVerified ?? this.isVerified,
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
    } else if (typeString.contains('medical') ||
        typeString.contains('ambulance')) {
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

    // Handle contacts which might be a list or a single string
    List<String> contacts = [];
    if (json['contacts'] != null) {
      if (json['contacts'] is List) {
        contacts = List<String>.from(json['contacts']);
      } else if (json['contacts'] is String) {
        // If contacts is a single string, convert to a list
        contacts = [json['contacts']];
      }
    } else if (json['contact'] != null) {
      // Legacy support: use contact field if contacts is not available
      contacts = [json['contact']];
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
      contacts: contacts,
      latitude: json['latitude'] is double
          ? json['latitude']
          : (json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null),
      longitude: json['longitude'] is double
          ? json['longitude']
          : (json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null),
      isVerified: json['is_verified'] == true,
      addedBy: json['added_by'],
      verifiedBy: json['verified_by'],
    );
  }
}
