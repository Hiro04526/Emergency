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

    // Perform search automatically with the provided service type
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
    });

    try {
      // Only search by type now, no other filters
      final results = await _databaseService.searchServices(
        type: _selectedType!, // This is always non-null since it's required
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
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
    // Format the phone number for dialing
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await url_launcher.canLaunchUrl(phoneUri)) {
        await url_launcher.launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone app for $phoneNumber'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(serviceId: service.id),
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
                if (service.phoneNumber != null) ...[
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
                            _callPhoneNumber(service.phoneNumber!);
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
                            service.phoneNumber!,
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
