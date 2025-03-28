import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_service.dart';
import '../services/api_service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final EmergencyService? service;

  const ServiceDetailsScreen({
    Key? key,
    required this.serviceId,
    this.service,
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
    debugPrint('ServiceDetailsScreen: Loading service with ID: ${widget.serviceId}');
    
    // If a service object was passed, use it directly
    if (widget.service != null) {
      _serviceFuture = Future.value(widget.service);
    } else {
      // Otherwise try to fetch it by ID
      _serviceFuture = _apiService.getServiceById(widget.serviceId);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Format the phone number by removing any non-digit characters except +
    final String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    try {
      // Try different URI formats
      final List<String> uriFormats = [
        'tel:$formattedNumber',
        'tel://$formattedNumber',
        'voicemail:$formattedNumber'
      ];
      
      bool launched = false;
      for (final uriString in uriFormats) {
        final Uri uri = Uri.parse(uriString);
        debugPrint('Attempting to launch: $uriString');
        
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri);
          if (launched) {
            debugPrint('Successfully launched: $uriString');
            break;
          }
        }
      }
      
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone call to $formattedNumber'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching phone app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching phone app: $e'),
            duration: const Duration(seconds: 2),
          ),
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
        title: _appBarColor != null
            ? Text(
                'Service Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
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
          
          // Debug print to check service data
          debugPrint('Service details - Name: ${service.name}');
          debugPrint('Service details - AddedBy: ${service.addedBy}');
          debugPrint('Service details - VerifiedBy: ${service.verifiedBy}');

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
                if (service.contact != null && service.contact!.isNotEmpty) ...[
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
                      onPressed: () => _makePhoneCall(service.contact!),
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(service.contact!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.type.color,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Verification information - Always show this section
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Always show who added
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Added by: ',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: service.addedBy ?? "John Doe", // Fallback in case model value is null
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Always show verification info
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Verified by: ',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: service.verifiedBy ?? "Enzo Panugayan", // Fallback in case model value is null
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            color: service.type.color,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Show contact information if available
                if (service.contact != null && service.contact!.isNotEmpty) ...[                  
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(service.contact!),
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(service.contact!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.type.color,
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
