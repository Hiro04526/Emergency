import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/emergency_alert.dart';
import '../services/alert_service.dart';
import '../providers/theme_provider.dart';

class AlertDetailsScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailsScreen({
    Key? key,
    required this.alertId,
  }) : super(key: key);

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  final AlertService _alertService = AlertService();
  late Future<EmergencyAlert?> _alertFuture;

  @override
  void initState() {
    super.initState();
    _loadAlertDetails();
  }

  Future<void> _loadAlertDetails() async {
    _alertFuture = Future(() async {
      try {
        // First try to find the alert in the local cache
        final cachedAlert = _alertService.alerts.firstWhere(
          (a) => a.id == widget.alertId,
          orElse: () => throw Exception('Alert not found in cache'),
        );
        return cachedAlert;
      } catch (e) {
        // If not found in cache, try to fetch from database
        await _alertService.refreshAlerts();
        try {
          // Check again in the refreshed alerts
          return _alertService.alerts.firstWhere(
            (a) => a.id == widget.alertId,
            orElse: () => throw Exception('Alert not found'),
          );
        } catch (e) {
          // Re-throw if still not found
          rethrow;
        }
      }
    });
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Alert Details'),
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<EmergencyAlert?>(
        future: _alertFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading alert details: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Alert not found',
                textAlign: TextAlign.center,
              ),
            );
          }

          final alert = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? alert.type.color.withAlpha(50)
                        : alert.type.color.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? alert.type.color.withAlpha(70)
                          : alert.type.color.withAlpha(38),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alert.type.icon,
                        color: alert.type.color,
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.type.name,
                              style: TextStyle(
                                color: alert.type.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (alert.isActive) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(38),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE ALERT',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Alert title
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Timestamp
                Text(
                  'Posted ${_formatTimestamp(alert.timestamp)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDarkMode ? Colors.grey[300] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Image (if available) - Placed between description and source
                if (alert.imageUrl != null && alert.imageUrl!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width,
                              maxHeight: MediaQuery.of(context).size.height * 0.8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: const Text('Alert Image'),
                                  leading: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  backgroundColor: alert.type.color,
                                ),
                                Flexible(
                                  child: InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 3.0,
                                    child: Image.network(
                                      alert.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Could not load image',
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'alert_image_${alert.id}',
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  alert.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: alert.type.color,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Could not load image',
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Source
                if (alert.source != null && alert.source!.isNotEmpty) ...[
                  Text(
                    'Source',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.source!,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Location
                if (alert.location != null && alert.location!.isNotEmpty) ...[
                  Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: alert.type.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.location!,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alert.latitude != null && alert.longitude != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openMap(alert.latitude!, alert.longitude!),
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: alert.type.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Related services - only show for Emergency and Natural Disaster alerts
                if (alert.type == AlertType.emergency || alert.type == AlertType.naturalDisaster) ...[
                  Text(
                    'Related Emergency Services',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find emergency services near this alert location:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildServiceButton(
                        context,
                        'Police',
                        Icons.local_police,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildServiceButton(
                        context,
                        'Medical',
                        Icons.medical_services,
                        Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildServiceButton(
                        context,
                        'Fire',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to service search with location
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Find $label services coming soon')),
          );
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
