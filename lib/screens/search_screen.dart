import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../services/database_service.dart';
import 'service_details_screen.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class SearchScreen extends StatefulWidget {
  final ServiceType initialServiceType;

  const SearchScreen({
    Key? key,
    required this.initialServiceType,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  ServiceType? _selectedType;
  List<EmergencyService> _searchResults = [];
  bool _isLoading = false;

  // Variables for scroll detection
  final ScrollController _scrollController = ScrollController();

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    
    // Set initial service type from the required parameter
    _selectedType = widget.initialServiceType;
    
    // Perform initial search once the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _searchResults = []; // Clear previous results
    });

    debugPrint('Starting search for service type: ${_selectedType?.name}');

    try {
      // First try to search by type
      final results = await _databaseService.searchServices(
        type: _selectedType!, // This is always non-null since it's required
      );

      debugPrint('Search completed. Found ${results.length} results');
      
      if (results.isEmpty) {
        debugPrint('No results found from database, checking if database has any services');
        
        // If no results, check if there are any services in the database at all
        final allServices = await _databaseService.getAllServices();
        
        if (allServices.isEmpty) {
          debugPrint('Database appears to be empty, showing error state');
          // Database might be empty or not properly initialized
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No services found in the database. Please check your connection.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          debugPrint('Database has services but none match the current filter');
        }
      } else {
        debugPrint('First result: ${results.first.name}');
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in search: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  void _callPhoneNumber(String phoneNumber) async {
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
        
        if (await url_launcher.canLaunchUrl(uri)) {
          launched = await url_launcher.launchUrl(uri);
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
              content: Text('Could not launch phone app for $formattedNumber'),
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

  void _navigateToServiceDetails(EmergencyService service) {
    debugPrint('Navigating to service details for: ${service.id} - ${service.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceId: service.id,
          service: service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: widget.initialServiceType.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.initialServiceType.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final service = _searchResults[index];
                          return _buildServiceItem(service);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(EmergencyService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service header
          Container(
            padding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: service.type.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(service.type),
                  color: service.type.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            service.level,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${service.distanceKm.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _navigateToServiceDetails(service);
                  },
                ),
              ],
            ),
          ),
          // Service details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone number button
                if (service.contact != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _callPhoneNumber(service.contact!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: service.type.color,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            service.contact!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
        return Icons.balance;
    }
  }
}
