import 'package:flutter/material.dart';

class UserProfile {
  final String? name;
  final String? phoneNumber;
  final String? homeAddress;

  UserProfile({
    this.name,
    this.phoneNumber,
    this.homeAddress,
  });

  // Check if the profile has been set up with basic information
  bool get isSetup => name != null && phoneNumber != null;

  // Create a copy of this profile with updated fields
  UserProfile copyWith({
    String? name,
    String? phoneNumber,
    String? homeAddress,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      homeAddress: homeAddress ?? this.homeAddress,
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
  }) {
    _profile = _profile.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      homeAddress: homeAddress,
    );
    notifyListeners();
  }
}
