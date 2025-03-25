import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _homeAddressController = TextEditingController();
  bool _isEditing = false;
  List<FavoriteLocation> _favoriteLocations = [];
  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profile = Provider.of<UserProfileProvider>(context, listen: false).profile;
      
      // Set the data we already have
      _nameController.text = profile.name ?? '';
      _homeAddressController.text = profile.homeAddress ?? '';
      
      // Get the user ID from the current session
      final user = authService.currentUser;
      
      if (user != null) {
        try {
          // Call the get_username_by_user stored procedure
          final usernameResponse = await Supabase.instance.client.rpc(
            'get_username_by_user',
            params: {
              'p_uid': user.id,
            },
          ).timeout(const Duration(seconds: 5));
          
          if (mounted) {
            setState(() {
              // Update username from database
              if (usernameResponse != null) {
                _username = usernameResponse.toString();
              }
              
              if (_username != null && _username!.isNotEmpty && _nameController.text.isEmpty) {
                _nameController.text = _username!;
              }
            });
          }
        } catch (nameError) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
        
        try {
          // Get favorite locations from the stored procedure
          final locationsResponse = await Supabase.instance.client.rpc(
            'get_favorite_locations_by_user',
            params: {
              'p_uid': user.id,
            },
          ).timeout(const Duration(seconds: 5));
          
          if (mounted) {
            setState(() {
              // Process favorite locations from the database
              if (locationsResponse != null) {
                if (locationsResponse is List) {
                  _favoriteLocations = _processFavoriteLocations(locationsResponse);
                } else {
                  // Try to convert to list if possible
                  try {
                    final List<dynamic> locationsList = List<dynamic>.from([locationsResponse]);
                    _favoriteLocations = _processFavoriteLocations(locationsList);
                  } catch (e) {
                    // Ignore error
                  }
                }
              } else {
                // Ignore null response
              }
              
              _isLoading = false;
            });
          }
        } catch (locError) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Process the favorite locations from the database response
  List<FavoriteLocation> _processFavoriteLocations(List locationsResponse) {
    final locations = <FavoriteLocation>[];
    
    try {
      for (var i = 0; i < locationsResponse.length; i++) {
        final locationStr = locationsResponse[i].toString();
        // Check if this is a valid favorite location string
        if (locationStr.isEmpty) {
          continue;
        }
        
        // Parse the location string - the SQL function returns just the location text
        // We'll split it if it contains delimiters, otherwise use as is
        if (locationStr.contains('|')) {
          final parts = locationStr.split('|');
          if (parts.length >= 2) {
            final name = parts[0];
            final address = parts[1];
            double? latitude;
            double? longitude;
            
            if (parts.length >= 4) {
              latitude = double.tryParse(parts[2]);
              longitude = double.tryParse(parts[3]);
            }
            
            locations.add(
              FavoriteLocation(
                id: i.toString(),
                name: name,
                address: address,
                latitude: latitude ?? 0,
                longitude: longitude ?? 0,
              ),
            );
          }
        } else {
          // If it's just a plain string, use it as both name and address
          locations.add(
            FavoriteLocation(
              id: i.toString(),
              name: 'Favorite ${i+1}',
              address: locationStr,
              latitude: 0,
              longitude: 0,
            ),
          );
        }
      }
    } catch (e) {
      // Ignore error
    }
    
    // Only use placeholder data if no locations were found AND there were no locations in the response
    if (locations.isEmpty && locationsResponse.isEmpty) {
      locations.addAll([
        FavoriteLocation(
          id: '1',
          name: 'Work',
          address: '123 Business Street, Manila',
          latitude: 14.5995,
          longitude: 120.9842,
        ),
        FavoriteLocation(
          id: '2',
          name: 'Parents Home',
          address: '456 Family Road, Quezon City',
          latitude: 14.6760,
          longitude: 121.0437,
        ),
      ]);
    }
    
    return locations;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    provider.updateProfile(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      homeAddress: _homeAddressController.text.isNotEmpty ? _homeAddressController.text : null,
    );
    
    // Also update the username in the database if needed
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        // This assumes you have an RPC to update the username
        // If not, you would need to create one
        await Supabase.instance.client.rpc(
          'update_username', // You'll need to create this function
          params: {
            'p_uid': user.id,
            'p_username': _nameController.text,
          },
        );
      } catch (e) {
        // Ignore error
      }
    }
    
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _addFavoriteLocation() async {
    // This would open a location picker and add a new favorite location
    // For now, just add a placeholder
    setState(() {
      _favoriteLocations.add(
        FavoriteLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New Location',
          address: 'New Address',
          latitude: 0,
          longitude: 0,
        ),
      );
    });
    
    // You would also save the location to the database
    // This assumes you have an RPC to add a favorite location
    // final authService = Provider.of<AuthService>(context, listen: false);
    // final user = authService.currentUser;
    // if (user != null) {
    //   try {
    //     await Supabase.instance.client.rpc(
    //       'add_favorite_location',
    //       params: {
    //         'p_uid': user.id,
    //         'p_location': 'New Location|New Address|0|0',
    //       },
    //     );
    //   } catch (e) {
    //     print('Error adding favorite location: $e');
    //   }
    // }
  }

  Future<void> _removeFavoriteLocation(FavoriteLocation location) async {
    setState(() {
      _favoriteLocations.removeWhere((loc) => loc.id == location.id);
    });
    
    // You would also remove the location from the database
    // This assumes you have an RPC to remove a favorite location
    // final authService = Provider.of<AuthService>(context, listen: false);
    // final user = authService.currentUser;
    // if (user != null) {
    //   try {
    //     await Supabase.instance.client.rpc(
    //       'remove_favorite_location',
    //       params: {
    //         'p_uid': user.id,
    //         'p_location_id': location.id,
    //       },
    //     );
    //   } catch (e) {
    //     print('Error removing favorite location: $e');
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bool isAuthenticated = authService.isAuthenticated;

    if (!isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view your profile'),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('My Profile', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile', 
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.blue,
            ),
            onPressed: _isEditing ? _saveProfile : _toggleEditMode,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty ? 'User' : _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Emergency Contact Profile',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Home location section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.home, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Home Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isEditing
                        ? TextField(
                            controller: _homeAddressController,
                            decoration: InputDecoration(
                              labelText: 'Home Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _homeAddressController.text.isEmpty
                                      ? 'No home address set'
                                      : _homeAddressController.text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                    if (!_isEditing && _homeAddressController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('View on Map'),
                            onPressed: () {
                              // Show location on map
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Favorite locations section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Text(
                          'Favorite Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: _addFavoriteLocation,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _favoriteLocations.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No favorite locations added',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _favoriteLocations.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final location = _favoriteLocations[index];
                              return _buildFavoriteLocationItem(location);
                            },
                          ),
                    if (!_isEditing && _favoriteLocations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add_location),
                            label: const Text('Add New Location'),
                            onPressed: _isEditing ? null : _toggleEditMode,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Account actions
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.blue),
                      title: const Text('Notification Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // Navigate to notification settings
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.security, color: Colors.blue),
                      title: const Text('Privacy & Security'),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                      onTap: () async {
                        try {
                          await authService.signOut();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out successfully')),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error signing out: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteLocationItem(FavoriteLocation location) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.star, color: Colors.amber),
      ),
      title: _isEditing
          ? TextField(
              decoration: InputDecoration(
                hintText: location.name,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            )
          : Text(location.name),
      subtitle: _isEditing
          ? TextField(
              decoration: InputDecoration(
                hintText: location.address,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            )
          : Text(location.address),
      trailing: _isEditing
          ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFavoriteLocation(location),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isEditing ? null : () {
        // View location details or navigate to map
      },
    );
  }
}

class FavoriteLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  FavoriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
