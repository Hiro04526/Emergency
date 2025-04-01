import 'package:flutter/material.dart';
import '../models/emergency_alert.dart';
import '../services/alert_service.dart';
import 'alert_details_screen.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'report_alert_screen.dart';

class AlertsScreen extends StatefulWidget {
  final AlertType? initialAlertType;

  const AlertsScreen({
    Key? key,
    this.initialAlertType,
  }) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  final AlertService _alertService = AlertService();
  late TabController _tabController;
  List<EmergencyAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AlertType.values.length + 1, // +1 for "All" tab
      vsync: this,
    );

    // Set initial tab if provided
    if (widget.initialAlertType != null) {
      _tabController.index =
          AlertType.values.indexOf(widget.initialAlertType!) + 1;
    }

    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await _alertService.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading alerts in AlertsScreen: $e');
      if (mounted) {
        setState(() {
          _alerts = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading alerts. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadAlerts,
            ),
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
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.blue,
        elevation: isDarkMode ? 0 : 4,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: isDarkMode ? Colors.white : null,
          labelColor: Colors.white,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.white70,
          tabs: [
            const Tab(text: 'All'),
            ...AlertType.values.map((type) => Tab(text: type.name)).toList(),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              color: isDarkMode ? Colors.white : Colors.blue,
            ))
          : TabBarView(
              controller: _tabController,
              children: [
                // All alerts tab
                _buildAlertsList(_alerts),
                // Type-specific tabs
                ...AlertType.values
                    .map((type) => _buildAlertsList(
                        _alerts.where((a) => a.type == type).toList()))
                    .toList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Get the currently selected alert type based on tab index
          AlertType? selectedType;
          if (_tabController.index > 0) {
            // Index 0 is "All", so we subtract 1 to get the correct AlertType
            selectedType = AlertType.values[_tabController.index - 1];
          }
          
          // Navigate to report alert screen with the selected type
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportAlertScreen(
                initialAlertType: selectedType,
              ),
            ),
          );
        },
        backgroundColor: isDarkMode ? Colors.blue : null,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlertsList(List<EmergencyAlert> alerts) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No alerts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAlerts,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: isDarkMode ? Colors.white : Colors.blue,
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildAlertCard(EmergencyAlert alert) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.type.color.withAlpha(isDarkMode ? 100 : 76),
          width: 1,
        ),
      ),
      elevation: isDarkMode ? 2 : 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlertDetailsScreen(alertId: alert.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert header
              Row(
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
                  // Alert details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
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
              const SizedBox(height: 12),
              // Alert description
              Text(
                alert.description,
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              // Alert footer with location and source
              Row(
                children: [
                  if (alert.location != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert.location!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (alert.source != null) ...[
                    Icon(
                      Icons.source,
                      size: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Source: ${alert.source}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
