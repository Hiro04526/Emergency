import 'package:flutter/material.dart';

class UserProfile {
  final String? name;
  final String? phoneNumber;
  final String? homeAddress;
  final int? avatarIndex;

  UserProfile({
    this.name,
    this.phoneNumber,
    this.homeAddress,
    this.avatarIndex,
  });

  // Check if the profile has been set up with basic information
  bool get isSetup => name != null && phoneNumber != null;

  // Create a copy of this profile with updated fields
  UserProfile copyWith({
    String? name,
    String? phoneNumber,
    String? homeAddress,
    int? avatarIndex,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      homeAddress: homeAddress ?? this.homeAddress,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }
}

class UserProfileProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();

  UserProfile get profile => _profile;

  void updateProfile({
    String? name,
    String? phoneNumber,
    String? homeAddress,
    int? avatarIndex,
  }) {
    _profile = _profile.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      homeAddress: homeAddress,
      avatarIndex: avatarIndex,
    );
    notifyListeners();
  }
}

// Model for favorite locations
class FavoriteLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  FavoriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // Create from JSON data
  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  // Convert to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
