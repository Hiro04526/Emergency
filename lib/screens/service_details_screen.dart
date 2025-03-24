import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_service.dart';
import '../services/api_service.dart';
import 'directions_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Future<EmergencyService?> _serviceFuture;
  Color? _appBarColor;
  Color? _backButtonColor;

  @override
  void initState() {
    super.initState();
    _serviceFuture = _apiService.getServiceById(widget.serviceId);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _appBarColor ?? Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _backButtonColor ?? Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: _appBarColor != null ? Text(
          'Service Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ) : null,
      ),
      body: FutureBuilder<EmergencyService?>(
        future: _serviceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading service details: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Service not found'),
            );
          }

          final service = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _appBarColor = service.type.color;
              _backButtonColor = Colors.white;
            });
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: service.type.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconData(service.type),
                        color: service.type.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Service name and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.level,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.distanceKm.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Call buttons
                if (service.phoneNumbers.isNotEmpty) ...[
                  const Text(
                    'Contact Numbers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...service.phoneNumbers.map((phone) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(phone),
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text(phone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: service.type.color,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  )).toList(),
                ] else if (service.phoneNumber != null) ...[
                  const Text(
                    'Contact Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(service.phoneNumber!),
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(service.phoneNumber!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.type.color,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Directions button
                if (service.latitude != null && service.longitude != null) ...[
                  const Text(
                    'Directions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DirectionsScreen(service: service),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Get Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: service.type.color,
                        side: BorderSide(color: service.type.color),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Description
                if (service.description != null) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return Icons.local_police;
      case ServiceType.medical:
        return Icons.medical_services;
      case ServiceType.fireStation:
        return Icons.local_fire_department;
      case ServiceType.government:
        return Icons.account_balance;
      default:
        return Icons.emergency;
    }
  }
}
