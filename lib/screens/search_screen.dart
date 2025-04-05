import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../providers/theme_provider.dart';
import 'service_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final LocationService _locationService = LocationService();

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
        debugPrint(
            'No results found from database, checking if database has any services');

        // If no results, check if there are any services in the database at all
        final allServices = await _databaseService.getAllServices();

        if (allServices.isEmpty) {
          debugPrint('Database appears to be empty, showing error state');
          // Database might be empty or not properly initialized
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No services found in the database. Please check your connection.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          debugPrint('Database has services but none match the current filter');
        }
      } else {
        debugPrint('First result: ${results.first.name}');

        // Always sort by distance
        _sortByDistance(results);
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

  void _sortByDistance(List<EmergencyService> services) {
    final userPosition = _locationService.positionNotifier.value;
    if (userPosition != null) {
      // First sort by verification status (verified first), then by distance
      services.sort((a, b) {
        // If verification status is different, prioritize verified services
        if (a.isVerified != b.isVerified) {
          return a.isVerified ? -1 : 1; // Verified services first
        }

        // If both have same verification status, sort by distance
        return _compareByDistance(a, b);
      });

      debugPrint(
          'Sorted results by verification status and distance from user location');
    } else {
      // If location is not available, at least sort by verification status
      services.sort((a, b) => a.isVerified ? -1 : (b.isVerified ? 1 : 0));
      debugPrint(
          'User location not available, sorting only by verification status');
    }
  }

  int _compareByDistance(EmergencyService a, EmergencyService b) {
    final userPosition = _locationService.positionNotifier.value;
    if (userPosition != null &&
        a.latitude != null &&
        a.longitude != null &&
        b.latitude != null &&
        b.longitude != null) {
      double distanceA = _locationService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          a.latitude!,
          a.longitude!);

      double distanceB = _locationService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          b.latitude!,
          b.longitude!);

      return distanceA.compareTo(distanceB);
    }
    return 0; // Keep original order if coordinates are missing
  }

  void _callPhoneNumber(BuildContext context, String phoneNumber) async {
    // Format the phone number by removing spaces and any non-digit characters except +
    String formattedNumber = phoneNumber.trim();

    // First preserve the + if it exists at the beginning
    bool startsWithPlus = formattedNumber.startsWith('+');

    // Remove all non-digit characters
    formattedNumber = formattedNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Re-add the + if it was there originally
    if (startsWithPlus) {
      formattedNumber = '+$formattedNumber';
    }

    debugPrint(
        'Formatted phone number: $formattedNumber from original: $phoneNumber');

    try {
      // Try different URI formats
      final List<String> uriFormats = [
        'tel:$formattedNumber',
        'tel://$formattedNumber',
      ];

      bool launched = false;
      for (final uriString in uriFormats) {
        final Uri uri = Uri.parse(uriString);
        debugPrint('Attempting to launch: $uriString');

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
    debugPrint(
        'Navigating to service details for: ${service.id} - ${service.name}');
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.grey[50],
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
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withAlpha(77)
                : Colors.grey.withAlpha(26),
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
            padding:
                const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? service.type.color
                  : service.type.color
                      .withAlpha(51), // Light version in light mode
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                // Service type icon with verification indicator for verified services
                Stack(
                  children: [
                    Icon(
                      _getIconData(service.type),
                      color: isDarkMode ? Colors.white : service.type.color,
                      size: 24,
                    ),
                    if (service.isVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode ? Colors.black : Colors.white,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check,
                              size: 8,
                              color: service.type.color,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            service.level,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${service.distanceKm.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                  ),
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
                // Phone number buttons
                if (service.contacts.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: isDarkMode ? Colors.white60 : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _callPhoneNumber(context, service.contacts[0]);
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
                            service.contacts[0],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (service.contact != null) ...[
                  // Legacy support for the contact field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: isDarkMode ? Colors.white60 : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _callPhoneNumber(context, service.contact!);
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
