import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/emergency_service.dart';
import '../services/directions_service.dart';
import '../services/location_service.dart';

class DirectionsScreen extends StatefulWidget {
  final EmergencyService service;

  const DirectionsScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  final DirectionsService _directionsService = DirectionsService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  DirectionsResult? _directionsResult;
  bool _isLoading = true;
  bool _showAlternativeRoutes = false;
  TravelMode _travelMode = TravelMode.driving;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeDirections();
  }

  Future<void> _initializeDirections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current position
      final position = await _locationService.getCurrentPosition();

      if (position == null ||
          widget.service.latitude == null ||
          widget.service.longitude == null) {
        throw Exception('Location data is not available');
      }

      // Get directions
      final origin = LatLng(position.latitude, position.longitude);
      final destination =
          LatLng(widget.service.latitude!, widget.service.longitude!);

      final directionsResult = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: _travelMode,
      );

      // Get alternative routes
      final alternativeRoutes = await _directionsService.getAlternativeRoutes(
        origin: origin,
        destination: destination,
        travelMode: _travelMode,
      );

      if (directionsResult == null) {
        throw Exception('Could not get directions');
      }

      // Create markers
      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('origin'),
          position: origin,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.service.name),
        ),
      };

      // Create polyline
      final polylines = <Polyline>{
        Polyline(
          polylineId: const PolylineId('route'),
          points: directionsResult.polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      };

      // Add alternative routes
      for (var i = 0; i < alternativeRoutes.length; i++) {
        if (i == 0) {
          continue; // Skip the first route as it's the same as directionsResult
        }

        polylines.add(
          Polyline(
            polylineId: PolylineId('alternative_$i'),
            points: alternativeRoutes[i].polylinePoints,
            color: Colors.grey,
            width: 5,
            visible: _showAlternativeRoutes,
          ),
        );
      }

      setState(() {
        _directionsResult = directionsResult;
        _markers = markers;
        _polylines = polylines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting directions: $e')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_directionsResult != null) {
      // Zoom to fit the route
      _zoomToFitRoute();
    }
  }

  void _zoomToFitRoute() {
    if (_mapController == null || _directionsResult == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _directionsResult!.polylinePoints
            .map((point) => point.latitude)
            .reduce((value, element) => value < element ? value : element),
        _directionsResult!.polylinePoints
            .map((point) => point.longitude)
            .reduce((value, element) => value < element ? value : element),
      ),
      northeast: LatLng(
        _directionsResult!.polylinePoints
            .map((point) => point.latitude)
            .reduce((value, element) => value > element ? value : element),
        _directionsResult!.polylinePoints
            .map((point) => point.longitude)
            .reduce((value, element) => value > element ? value : element),
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _toggleAlternativeRoutes() {
    setState(() {
      _showAlternativeRoutes = !_showAlternativeRoutes;

      // Update polylines visibility
      final updatedPolylines = <Polyline>{};

      for (var polyline in _polylines) {
        if (polyline.polylineId.value == 'route') {
          updatedPolylines.add(polyline);
        } else {
          updatedPolylines.add(
            polyline.copyWith(
              visibleParam: _showAlternativeRoutes,
            ),
          );
        }
      }

      _polylines = updatedPolylines;
    });
  }

  void _changeTravelMode(TravelMode mode) {
    if (_travelMode == mode) return;

    setState(() {
      _travelMode = mode;
    });

    _initializeDirections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        actions: [
          IconButton(
            icon: Icon(
              _showAlternativeRoutes
                  ? Icons.alt_route
                  : Icons.alt_route_outlined,
            ),
            onPressed: _toggleAlternativeRoutes,
            tooltip: 'Alternative Routes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Travel mode selector
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTravelModeButton(
                        TravelMode.driving,
                        Icons.directions_car,
                        'Driving',
                      ),
                      _buildTravelModeButton(
                        TravelMode.walking,
                        Icons.directions_walk,
                        'Walking',
                      ),
                      _buildTravelModeButton(
                        TravelMode.bicycling,
                        Icons.directions_bike,
                        'Cycling',
                      ),
                      _buildTravelModeButton(
                        TravelMode.transit,
                        Icons.directions_transit,
                        'Transit',
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _directionsResult?.startLocation ??
                          const LatLng(14.5995, 120.9842), // Default to Manila
                      zoom: 12,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                  ),
                ),

                // Directions info
                if (_directionsResult != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route summary
                        Row(
                          children: [
                            Icon(
                              _getTravelModeIcon(_travelMode),
                              color: widget.service.type.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _directionsResult!.distance,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Estimated time: ${_directionsResult!.duration}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _zoomToFitRoute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.service.type.color,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Overview'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Start and end addresses
                        Row(
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: Colors.grey[300],
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Location',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _directionsResult!.startAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Destination',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.service.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Start navigation button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement turn-by-turn navigation
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Turn-by-turn navigation coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text('Start Navigation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.service.type.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTravelModeButton(
    TravelMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = _travelMode == mode;

    return InkWell(
      onTap: () => _changeTravelMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? widget.service.type.color.withAlpha(38) : null,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? Border.all(color: widget.service.type.color) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? widget.service.type.color : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? widget.service.type.color : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTravelModeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return Icons.directions_car;
      case TravelMode.walking:
        return Icons.directions_walk;
      case TravelMode.bicycling:
        return Icons.directions_bike;
      case TravelMode.transit:
        return Icons.directions_transit;
    }
  }
}
