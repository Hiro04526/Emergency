import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emergency_service.dart';
import '../services/location_service.dart';
import 'search_screen.dart';
//import 'service_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Emergency Services',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Find and contact emergency services near you',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 2x2 Grid of emergency service categories
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildServiceCard(
                    context,
                    ServiceType.police,
                    () {
                      _navigateToServiceTypeScreen(context, ServiceType.police);
                    },
                  ),
                  _buildServiceCard(
                    context,
                    ServiceType.ambulance,
                    () {
                      _navigateToServiceTypeScreen(
                          context, ServiceType.ambulance);
                    },
                  ),
                  _buildServiceCard(
                    context,
                    ServiceType.firetruck,
                    () {
                      _navigateToServiceTypeScreen(
                          context, ServiceType.firetruck);
                    },
                  ),
                  _buildServiceCard(
                    context,
                    ServiceType.government,
                    () {
                      _navigateToServiceTypeScreen(
                          context, ServiceType.government);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Location display
              GestureDetector(
                onTap: () async {
                  // Request location permission and get current location
                  await locationService.getCurrentPosition();
                  if (locationService.currentPosition != null) {
                    await locationService.getAddressFromCoordinates(
                      locationService.currentPosition!.latitude,
                      locationService.currentPosition!.longitude,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<String?>(
                          valueListenable: locationService.addressNotifier,
                          builder: (context, address, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Coordinates',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address ?? 'Tap to set your location',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'In case of emergency, please call the appropriate service directly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToServiceTypeScreen(BuildContext context, ServiceType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(initialServiceType: type),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceType type,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: type.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(38),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(type),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              type.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return Icons.local_police;
      case ServiceType.ambulance:
        return Icons.medical_services;
      case ServiceType.firetruck:
        return Icons.local_fire_department;
      case ServiceType.government:
        return Icons.balance;
    }
  }
}
