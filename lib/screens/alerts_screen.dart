import 'package:flutter/material.dart';
import '../models/emergency_alert.dart';
import '../services/alert_service.dart';
import 'alert_details_screen.dart';

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
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alerts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            ...AlertType.values.map((type) => Tab(text: type.name)).toList(),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          // TODO: Navigate to report alert screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report Alert feature coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlertsList(List<EmergencyAlert> alerts) {
    if (alerts.isEmpty) {
      return const Center(
        child: Text('No alerts found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.type.color.withAlpha(76),
          width: 1,
        ),
      ),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alert.type.color.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      alert.type.icon,
                      color: alert.type.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type.name,
                          style: TextStyle(
                            color: alert.type.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(alert.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alert.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Alert title and description
              Text(
                alert.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Location and source
              if (alert.location != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      alert.location!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              if (alert.source != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.source_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Source: ${alert.source}',
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
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
