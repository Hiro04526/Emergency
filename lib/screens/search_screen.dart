import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../services/api_service.dart';
import 'service_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final ServiceType? initialServiceType;

  const SearchScreen({
    Key? key,
    this.initialServiceType,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  ServiceType? _selectedType;
  String? _selectedRegion;
  String? _selectedCategory;
  String? _selectedClassification;

  List<EmergencyService> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Set initial service type if provided
    _selectedType = widget.initialServiceType;

    // If initial type is provided, perform search automatically
    if (_selectedType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _apiService.searchServices(
        query: _searchController.text,
        type: _selectedType,
        region: _selectedRegion,
        category: _selectedCategory,
        classification: _selectedClassification,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedType != null
            ? 'Nearest ${_selectedType!.name} Services'
            : 'Search Emergency Services'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search emergency services...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<ServiceType>(
                        value: _selectedType,
                        hint: 'Select Type...',
                        items: ServiceType.values
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedRegion,
                        hint: 'Select Region',
                        items: const [
                          DropdownMenuItem(
                              value: 'Metro Manila',
                              child: Text('Metro Manila')),
                          DropdownMenuItem(
                              value: 'Calabarzon', child: Text('Calabarzon')),
                          DropdownMenuItem(
                              value: 'Central Luzon',
                              child: Text('Central Luzon')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRegion = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedCategory,
                        hint: 'Select Category',
                        items: const [
                          DropdownMenuItem(
                              value: 'Emergency', child: Text('Emergency')),
                          DropdownMenuItem(
                              value: 'Non-Emergency',
                              child: Text('Non-Emergency')),
                          DropdownMenuItem(
                              value: 'Information', child: Text('Information')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedClassification,
                        hint: 'Select Classification...',
                        items: const [
                          DropdownMenuItem(
                              value: 'National', child: Text('National')),
                          DropdownMenuItem(
                              value: 'Provincial', child: Text('Provincial')),
                          DropdownMenuItem(
                              value: 'City/Municipal',
                              child: Text('City/Municipal')),
                          DropdownMenuItem(
                              value: 'Barangay', child: Text('Barangay')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClassification = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched && _searchResults.isEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildServiceItem(EmergencyService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsScreen(serviceId: service.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: service.type.color.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(service.type),
                  color: service.type.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Service details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                    Text(
                      '${service.distanceKm.toStringAsFixed(1)} km away',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (service.phoneNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            service.phoneNumber!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Bookmark icon
              Icon(
                Icons.bookmark_outline,
                color: Colors.grey[400],
              ),
            ],
          ),
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
