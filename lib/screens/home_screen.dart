import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../models/emergency_alert.dart';
import '../services/location_service.dart';
import '../services/alert_service.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';
import 'add_emergency_contact_screen.dart';
import 'report_alert_screen.dart';
import 'alerts_screen.dart';
import 'alert_details_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final AlertService _alertService = AlertService();
  List<EmergencyAlert> _recentAlerts = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _locationService.getCurrentPosition();
    _loadRecentAlerts();
  }

  Future<void> _loadRecentAlerts() async {
    try {
      // Ensure we have alerts loaded
      await _alertService.getAlerts();
      
      if (mounted) {
        setState(() {
          _recentAlerts = _alertService.getRecentAlerts(limit: 2);
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading recent alerts: $e');
      if (mounted) {
        setState(() {
          _recentAlerts = [];
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SvgPicture.asset(
          'assets/logo/Component_1.svg', 
          height: 40, 
          width: 150,
        ),
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
            onPressed: () {
              // Check if user is authenticated
              if (authService.isAuthenticated) {
                // Navigate to profile screen if authenticated
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                );
              } else {
                // Show login dialog if not authenticated
                authService.showAuthRequiredDialog(context);
              }
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Alerts Section
                _buildRecentAlertsSection(),
                
                const SizedBox(height: 12),
                
                // Report Alert Button
                _buildReportAlertButton(),
                
                const SizedBox(height: 12),
                
                // Navbar with location
                _buildNavbar(),

                const SizedBox(height: 8),

                // Emergency Services Section
                Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // Grid of emergency service buttons
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: ServiceType.values
                      .map((type) => _buildServiceButton(type))
                      .toList(),
                ),

                const SizedBox(height: 12),

                // Add Emergency Contact Section
                _buildAddEmergencyContactSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: _locationService.addressNotifier,
              builder: (context, address, child) {
                return Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address ?? "Locating your position...",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Add refresh button
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.blue,
              size: 22,
            ),
            onPressed: () {
              _locationService.refreshLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing your location...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(ServiceType type) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(initialServiceType: type),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: type.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(type),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              type.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlertsScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _recentAlerts.isEmpty
          ? Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 40,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No alerts at this time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay tuned for emergency notifications',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Header with refresh button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latest Updates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.blue,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () async {
                            setState(() {
                              _isRefreshing = true;
                            });
                            
                            try {
                              await _alertService.refreshAlerts();
                              await _loadRecentAlerts();
                            } catch (e) {
                              print('Error refreshing alerts: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error refreshing alerts')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isRefreshing = false;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  // Alerts list
                  _isRefreshing 
                    ? Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.blue,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(0),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentAlerts.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          return _buildAlertCard(_recentAlerts[index]);
                        },
                      ),
                  // View all alerts button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AlertsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                      child: Text(
                        'View All Alerts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildAlertCard(EmergencyAlert alert) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertDetailsScreen(alertId: alert.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alert.type.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                alert.type.icon,
                color: alert.type.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Alert content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert title
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Alert description
                  Text(
                    alert.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Alert metadata
                  Row(
                    children: [
                      // Alert type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: alert.type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert.type.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: alert.type.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Alert time
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(alert.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportAlertButton() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Alert'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isDarkMode ? 4 : 2,
        ),
        onPressed: () {
          if (authService.canAccessContributorFeature(context)) {
            // Only navigate if user is authenticated
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportAlertScreen(),
              ),
            ).then((_) => _loadRecentAlerts());
          }
        },
      ),
    );
  }

  Widget _buildAddEmergencyContactSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contribute to Emergency Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.blue.withValues(alpha: 51), // Increased from 26 to 51 (0.2 * 255)
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help us improve our emergency services database by adding contact information for emergency services in your area.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (authService.canAccessContributorFeature(context)) {
                      // Only navigate if user is authenticated
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddEmergencyContactScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
