import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/emergency_service.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

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
  bool _isVerifying = false;

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
        debugPrint('Attempting to launch A: $uriString');


        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          debugPrint('Successfully launched: $uriString');
          break;
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

  Future<void> _verifyService(EmergencyService service) async {
    setState(() {
      _isVerifying = true;
    });

    try {
      // Simulate API call to verify the service
      await Future.delayed(const Duration(seconds: 2));
      
      // Update the service with verified status
      final updatedService = service.copyWith(isVerified: true);
      
      // Update the UI
      setState(() {
        _serviceFuture = Future.value(updatedService);
        _isVerifying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service verified successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error verifying service: $e');
      setState(() {
        _isVerifying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying service: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _reportIssue(EmergencyService service) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text(
          'Do you want to report an issue with this service? This will help us improve our database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your report. We will review it shortly.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openInMaps(double latitude, double longitude, String name) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _appBarColor ?? (isDarkMode ? Color(0xFF1E1E1E) : Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _backButtonColor ?? (isDarkMode ? Colors.white : Colors.blue)),
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
                    Stack(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: service.type.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconData(service.type),
                            color: service.type.color,
                            size: 30,
                          ),
                        ),
                        if (service.isVerified)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: service.type.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode ? Color(0xFF121212) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
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
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.distanceKm.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                if (service.contacts.isNotEmpty) ...[
                  const Text(
                    'Contact Numbers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...service.contacts.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(contact),
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text(contact),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: service.type.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  )).toList(),
                ] else if (service.contact != null && service.contact!.isNotEmpty) ...[
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Verification and Report buttons
                if (!service.isVerified) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isVerifying ? null : () => _verifyService(service),
                      icon: _isVerifying 
                          ? Container(
                              width: 18,
                              height: 18,
                              padding: const EdgeInsets.all(2),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.verified_user, size: 18),
                      label: Text(_isVerifying ? 'Verifying...' : 'Verify Number'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.type.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        disabledBackgroundColor: service.type.color.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _reportIssue(service),
                    icon: const Icon(Icons.report_problem, size: 18),
                    label: const Text('Report Issue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: service.type.color,
                      side: BorderSide(color: service.type.color),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Location
                if (service.latitude != null && service.longitude != null) ...[
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: service.type.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Latitude: ${service.latitude!.toStringAsFixed(6)}, Longitude: ${service.longitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openInMaps(
                        service.latitude!,
                        service.longitude!,
                        service.name,
                      ),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('View on Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.type.color,
                        foregroundColor: Colors.white,
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
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
