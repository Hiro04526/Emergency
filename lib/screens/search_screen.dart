import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../services/api_service.dart';
import 'service_details_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  ServiceType? _selectedType;
  String? _selectedRegion;
  String? _selectedCategory;
  String? _selectedClassification;

  List<EmergencyService> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Variables for search and filter
  bool _isSearchBarVisible = false;
  final double _maxSearchBarHeight = 280; // Increased height for search panel

  // Variables for scroll detection
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService();

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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // For the service type, we always use the initial type since it's required
      // For other filters, we pass the selected values which may be null
      final results = await _apiService.searchServices(
        query: _searchController.text,
        type: _selectedType!, // This is always non-null since it's required
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

  void _resetFilters() {
    setState(() {
      _selectedRegion = null;
      _selectedCategory = null;
      _selectedClassification = null;
      _searchController.clear();
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _selectedType!.color,
        title: Text('Nearest ${_selectedType!.name} Services'),
        elevation: 0,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: _isSearchBarVisible
                  ? const Icon(
                      Icons.close,
                      key: ValueKey('close'),
                    )
                  : const Icon(
                      Icons.search,
                      key: ValueKey('search'),
                    ),
            ),
            onPressed: () {
              setState(() {
                _isSearchBarVisible = !_isSearchBarVisible;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchBarVisible ? _maxSearchBarHeight : 0.0,
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Search & Filter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedType!.color,
                        ),
                      ),
                    ),

                    // Search input
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search emergency services...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 5),

                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Service Type: ${_selectedType!.name}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

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
                                  value: 'Calabarzon',
                                  child: Text('Calabarzon')),
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
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown<String>(
                            value: _selectedCategory,
                            hint: 'Category',
                            items: const [
                              DropdownMenuItem(
                                  value: 'Emergency', child: Text('Emergency')),
                              DropdownMenuItem(
                                  value: 'Non-Emergency',
                                  child: Text('Non-Emergency')),
                              DropdownMenuItem(
                                  value: 'Information',
                                  child: Text('Information')),
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
                    const SizedBox(height: 5),

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
                                  value: 'Provincial',
                                  child: Text('Provincial')),
                              DropdownMenuItem(
                                  value: 'City/Municipal',
                                  child: Text('City/Municipal')),
                              DropdownMenuItem(
                                  value: 'Barangay', child: Text('Barangay')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedClassification = value ?? '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Search button and reset filters
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                await _performSearch();
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              child: const Text('Search'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Use the search button above to find emergency services',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(child: Text('No results found'))
                        : ListView.builder(
                            controller: _scrollController,
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
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<T>(
                  value: value,
                  hint: Text(hint, style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  iconSize: 18,
                  elevation: 2,
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  dropdownColor: Colors.grey[100],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  onChanged: onChanged,
                  items: items,
                  itemHeight: kMinInteractiveDimension,
                  borderRadius: BorderRadius.circular(8),
                  isDense: true,
                ),
              ),
            ),
          ),
          // Clear button - only show if a value is selected
          if (value != null)
            GestureDetector(
              onTap: () => onChanged(null),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.clear,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
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
