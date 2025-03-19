import 'package:flutter/material.dart';

enum AlertType {
  emergency,
  weather,
  naturalDisaster,
  traffic,
  community
}

extension AlertTypeExtension on AlertType {
  String get name {
    switch (this) {
      case AlertType.emergency:
        return 'Emergency';
      case AlertType.weather:
        return 'Weather';
      case AlertType.naturalDisaster:
        return 'Natural Disaster';
      case AlertType.traffic:
        return 'Traffic';
      case AlertType.community:
        return 'Community';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.emergency:
        return Icons.warning_amber_rounded;
      case AlertType.weather:
        return Icons.wb_cloudy;
      case AlertType.naturalDisaster:
        return Icons.tsunami;
      case AlertType.traffic:
        return Icons.traffic;
      case AlertType.community:
        return Icons.people;
    }
  }

  Color get color {
    switch (this) {
      case AlertType.emergency:
        return Colors.red;
      case AlertType.weather:
        return Colors.blue;
      case AlertType.naturalDisaster:
        return Colors.orange;
      case AlertType.traffic:
        return Colors.amber;
      case AlertType.community:
        return Colors.green;
    }
  }
}

class EmergencyAlert {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final DateTime timestamp;
  final String? source;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String? imageUrl;
  final Map<String, dynamic>? additionalData;

  EmergencyAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.source,
    this.location,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.imageUrl,
    this.additionalData,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: AlertType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type'].toLowerCase(),
        orElse: () => AlertType.emergency,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isActive: json['is_active'] ?? true,
      imageUrl: json['image_url'],
      additionalData: json['additional_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name.toLowerCase(),
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'image_url': imageUrl,
      'additional_data': additionalData,
    };
  }
}
