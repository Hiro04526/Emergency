import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Current position
  Position? _currentPosition;
  String? _currentAddress;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;

  // Stream controllers
  final ValueNotifier<Position?> positionNotifier = ValueNotifier<Position?>(null);
  final ValueNotifier<String?> addressNotifier = ValueNotifier<String?>(null);

  // Initialize location service
  Future<void> initialize() async {
    await _checkPermission();
    await getCurrentPosition();
  }

  // Check if location permission is granted
  Future<bool> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return false;
    }

    // Permissions are granted
    return true;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkPermission();
      
      if (!hasPermission) {
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      positionNotifier.value = _currentPosition;
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Get address from coordinates (Geocoding)
  // This would typically use a geocoding service
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    // For now, just return a placeholder
    // In a real app, you would use a geocoding service like Google Maps Geocoding API
    _currentAddress = "Current Location";
    addressNotifier.value = _currentAddress;
    return _currentAddress;
  }

  // Calculate distance between two coordinates
  double calculateDistance(double startLatitude, double startLongitude, 
                          double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude, 
      startLongitude, 
      endLatitude, 
      endLongitude
    ) / 1000; // Convert to kilometers
  }
}
