import 'package:flutter/material.dart';

enum ServiceType { police, ambulance, firetruck, government }

extension ServiceTypeExtension on ServiceType {
  String get name {
    switch (this) {
      case ServiceType.police:
        return 'Police';
      case ServiceType.ambulance:
        return 'Ambulance';
      case ServiceType.firetruck:
        return 'Firetruck';
      case ServiceType.government:
        return 'Government';
    }
  }

  String get iconPath {
    switch (this) {
      case ServiceType.police:
        return 'assets/icons/police_icon.png';
      case ServiceType.ambulance:
        return 'assets/icons/ambulance_icon.png';
      case ServiceType.firetruck:
        return 'assets/icons/firetruck_icon.png';
      case ServiceType.government:
        return 'assets/icons/government_icon.png';
    }
  }

  Color get color {
    switch (this) {
      case ServiceType.police:
        return const Color(0xFF2D7FF9);
      case ServiceType.ambulance:
        return const Color(0xFFE53935);
      case ServiceType.firetruck:
        return const Color(0xFFFF8C00);
      case ServiceType.government:
        return const Color(0xFF4CAF50);
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
    this.latitude,
    this.longitude,
  });

  factory EmergencyService.fromJson(Map<String, dynamic> json) {
    return EmergencyService(
      id: json['id'],
      name: json['name'],
      type: ServiceType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type'].toLowerCase(),
        orElse: () => ServiceType.police,
      ),
      level: json['level'],
      description: json['description'],
      distanceKm: json['distance_km'],
      phoneNumber: json['phone_number'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
