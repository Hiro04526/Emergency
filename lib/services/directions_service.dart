import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsService {
  // Singleton pattern
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  // API key - in a real app, this would be stored securely
  // This is a placeholder - you need to replace with a valid Google Maps API key
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Get directions between two points
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      // Build the URL for the directions API
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=${_travelModeToString(travelMode)}'
        '&key=$_apiKey',
      );

      // Make the request
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return DirectionsResult.fromJson(data);
        } else {
          debugPrint('Error getting directions: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('Error getting directions: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return null;
    }
  }

  // Get alternative routes
  Future<List<DirectionsResult>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      // Build the URL for the directions API with alternatives
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=${_travelModeToString(travelMode)}'
        '&alternatives=true'
        '&key=$_apiKey',
      );

      // Make the request
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> routes = data['routes'];
          return routes.map((route) {
            return DirectionsResult.fromRoute(route, data['geocoded_waypoints']);
          }).toList();
        } else {
          debugPrint('Error getting alternative routes: ${data['status']}');
          return [];
        }
      } else {
        debugPrint('Error getting alternative routes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting alternative routes: $e');
      return [];
    }
  }

  // Convert travel mode enum to string
  String _travelModeToString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }
}

// Travel mode enum
enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

// Directions result class
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String startAddress;
  final String endAddress;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<DirectionsStep> steps;
  final String? summary;
  final List<String>? warnings;
  final String? trafficTime;
  final String? trafficDistance;

  DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.startAddress,
    required this.endAddress,
    required this.startLocation,
    required this.endLocation,
    required this.steps,
    this.summary,
    this.warnings,
    this.trafficTime,
    this.trafficDistance,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    // Get the first route
    final route = json['routes'][0];
    final leg = route['legs'][0];
    
    // Decode polyline points
    final polylinePoints = PolylinePoints()
        .decodePolyline(route['overview_polyline']['points'])
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    
    // Extract steps
    final steps = (leg['steps'] as List)
        .map((step) => DirectionsStep.fromJson(step))
        .toList();
    
    return DirectionsResult(
      polylinePoints: polylinePoints,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      startAddress: leg['start_address'],
      endAddress: leg['end_address'],
      startLocation: LatLng(
        leg['start_location']['lat'],
        leg['start_location']['lng'],
      ),
      endLocation: LatLng(
        leg['end_location']['lat'],
        leg['end_location']['lng'],
      ),
      steps: steps,
      summary: route['summary'],
      warnings: route['warnings'] != null
          ? (route['warnings'] as List).cast<String>()
          : null,
      trafficTime: leg['duration_in_traffic'] != null
          ? leg['duration_in_traffic']['text']
          : null,
      trafficDistance: null,
    );
  }

  factory DirectionsResult.fromRoute(Map<String, dynamic> route, List<dynamic> waypoints) {
    final leg = route['legs'][0];
    
    // Decode polyline points
    final polylinePoints = PolylinePoints()
        .decodePolyline(route['overview_polyline']['points'])
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    
    // Extract steps
    final steps = (leg['steps'] as List)
        .map((step) => DirectionsStep.fromJson(step))
        .toList();
    
    return DirectionsResult(
      polylinePoints: polylinePoints,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      startAddress: leg['start_address'],
      endAddress: leg['end_address'],
      startLocation: LatLng(
        leg['start_location']['lat'],
        leg['start_location']['lng'],
      ),
      endLocation: LatLng(
        leg['end_location']['lat'],
        leg['end_location']['lng'],
      ),
      steps: steps,
      summary: route['summary'],
      warnings: route['warnings'] != null
          ? (route['warnings'] as List).cast<String>()
          : null,
      trafficTime: leg['duration_in_traffic'] != null
          ? leg['duration_in_traffic']['text']
          : null,
      trafficDistance: null,
    );
  }
}

// Directions step class
class DirectionsStep {
  final String htmlInstructions;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String travelMode;
  final List<LatLng> polylinePoints;

  DirectionsStep({
    required this.htmlInstructions,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.travelMode,
    required this.polylinePoints,
  });

  factory DirectionsStep.fromJson(Map<String, dynamic> json) {
    // Decode polyline points
    final polylinePoints = PolylinePoints()
        .decodePolyline(json['polyline']['points'])
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    
    return DirectionsStep(
      htmlInstructions: json['html_instructions'],
      distance: json['distance']['text'],
      duration: json['duration']['text'],
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
      travelMode: json['travel_mode'],
      polylinePoints: polylinePoints,
    );
  }
}
