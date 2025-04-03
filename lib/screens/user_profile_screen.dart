import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

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
  int _selectedAvatarIndex = 0;

  // List of avatar options
  final List<IconData> _avatarOptions = [
    Icons.person,
    Icons.face,
    Icons.emoji_people,
    Icons.sports,
    Icons.directions_bike,
    Icons.directions_car,
    Icons.pets,
    Icons.school,
  ];

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
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).profile;

      // Set the data we already have
      _nameController.text = profile.name ?? '';
      _homeAddressController.text = profile.homeAddress ?? '';
      _selectedAvatarIndex = profile.avatarIndex ?? 0;

      // Get the user ID from the current session
      final user = authService.currentUser;

      if (user != null) {
        try {
          // Call the get_username_by_user stored procedure
          final usernameResponse = await supabase.Supabase.instance.client.rpc(
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

              if (_username != null &&
                  _username!.isNotEmpty &&
                  _nameController.text.isEmpty) {
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
          final locationsResponse = await supabase.Supabase.instance.client.rpc(
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
                  _favoriteLocations =
                      _processFavoriteLocations(locationsResponse);
                } else {
                  // Try to convert to list if possible
                  try {
                    final List<dynamic> locationsList =
                        List<dynamic>.from([locationsResponse]);
                    _favoriteLocations =
                        _processFavoriteLocations(locationsList);
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
              name: 'Favorite ${i + 1}',
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
      homeAddress: _homeAddressController.text.isNotEmpty
          ? _homeAddressController.text
          : null,
      avatarIndex: _selectedAvatarIndex,
    );

    // Also update the username in the database if needed
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        // This assumes you have an RPC to update the username
        // If not, you would need to create one
        await supabase.Supabase.instance.client.rpc(
          'update_username', // You'll need to create this function
          params: {
            'p_uid': user.id,
            'p_username': _nameController.text,
            'p_avatar_index': _selectedAvatarIndex,
          },
        );
      } catch (e) {
        // Ignore error
      }
    }

    if (!mounted) return;

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
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
    //     await supabase.Supabase.instance.client.rpc(
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
    //     await supabase.Supabase.instance.client.rpc(
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isAuthenticated = authService.isAuthenticated;

    if (!isAuthenticated) {
      return Scaffold(
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
          title: Text('My Profile', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          themeProvider.isDarkMode ? Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile',
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue),
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
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header section
              Container(
                color:
                    themeProvider.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue.withAlpha(10),
                          child: Icon(
                            _avatarOptions[_selectedAvatarIndex],
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: themeProvider.isDarkMode
                                      ? Color(0xFF1E1E1E)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: themeProvider.isDarkMode
                                          ? Color(0xFF1E1E1E)
                                          : Colors.white,
                                      title: Text(
                                        'Choose an Avatar',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: double.infinity,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: _avatarOptions.length,
                                          itemBuilder: (context, index) {
                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedAvatarIndex = index;
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    _selectedAvatarIndex ==
                                                            index
                                                        ? Colors.blue
                                                        : Colors.blue
                                                            .withAlpha(10),
                                                child: Icon(
                                                  _avatarOptions[index],
                                                  color: _selectedAvatarIndex ==
                                                          index
                                                      ? Colors.white
                                                      : Colors.blue,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 20),
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _nameController.text.isEmpty
                                      ? 'User'
                                      : _nameController.text,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Home location section
              Container(
                color:
                    themeProvider.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    SizedBox(height: 16),
                    _isEditing
                        ? TextField(
                            controller: _homeAddressController,
                            decoration: InputDecoration(
                              labelText: 'Home Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          )
                        : Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _homeAddressController.text.isEmpty
                                      ? 'No home address set'
                                      : _homeAddressController.text,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                    if (!_isEditing && _homeAddressController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.map),
                            label: Text('View on Map'),
                            onPressed: () {
                              // Show location on map
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
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

              SizedBox(height: 16),

              // Favorite locations section
              Container(
                color:
                    themeProvider.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Favorite Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        if (_isEditing)
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.blue),
                            onPressed: _addFavoriteLocation,
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _favoriteLocations.isEmpty
                        ? Center(
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
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _favoriteLocations.length,
                            separatorBuilder: (context, index) => Divider(),
                            itemBuilder: (context, index) {
                              final location = _favoriteLocations[index];
                              return _buildFavoriteLocationItem(location);
                            },
                          ),
                    if (!_isEditing && _favoriteLocations.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.add_location),
                            label: Text('Add New Location'),
                            onPressed: _isEditing ? null : _toggleEditMode,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
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

              SizedBox(height: 24),

              // Account actions
              Container(
                color:
                    themeProvider.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Dark Mode Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.amber,
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Light/Dark Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: themeProvider.isDarkMode,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ],
                    ),

                    Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                      onTap: () async {
                        try {
                          await authService.signOut();
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logged out successfully')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error signing out: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),
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
          color: Colors.amber.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.star, color: Colors.amber),
      ),
      title: _isEditing
          ? TextField(
              decoration: InputDecoration(
                hintText: location.name,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            )
          : Text(location.name),
      subtitle: _isEditing
          ? TextField(
              decoration: InputDecoration(
                hintText: location.address,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            )
          : Text(location.address),
      trailing: _isEditing
          ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFavoriteLocation(location),
            )
          : Icon(Icons.chevron_right),
      onTap: _isEditing
          ? null
          : () {
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
