import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isActivated = false;
  bool _isCountingDown = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  Timer? _pulseTimer;
  List<EmergencyService> _emergencyServices = [];

  @override
  void initState() {
    super.initState();

    // Set up animation controller for the SOS button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadEmergencyServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmergencyServices() async {
    List<EmergencyService> allServices = [];

    // Get services for each type
    for (var serviceType in ServiceType.values) {
      final services = await _apiService.getServicesByType(serviceType);
      allServices.addAll(services);
    }

    setState(() {
      _emergencyServices = allServices;
    });
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        _countdownTimer?.cancel();
        _activateSOS();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
    });
  }

  void _activateSOS() {
    // Vibrate the device
    HapticFeedback.heavyImpact();

    setState(() {
      _isActivated = true;
      _isCountingDown = false;
    });

    // Start pulsing animation
    _animationController.repeat(reverse: true);

    // Vibrate periodically
    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.heavyImpact();
    });

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('SOS activated! Emergency services have been notified.'),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }

    // In a real app, this would send an emergency alert to authorities
    // and emergency contacts with the user's location
    _sendEmergencyAlert();
  }

  void _deactivateSOS() {
    _pulseTimer?.cancel();
    _animationController.stop();

    setState(() {
      _isActivated = false;
    });

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS deactivated'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        // In a real app, this would send the location to emergency services
        debugPrint(
            'Emergency location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _callEmergencyService(EmergencyService service) async {
    if (service.phoneNumber != null) {
      final uri = Uri.parse('tel:${service.phoneNumber}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not call ${service.name}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: _isActivated ? Colors.red : null,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: _isActivated ? Colors.red : Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                _isActivated
                    ? 'SOS ACTIVATED'
                    : _isCountingDown
                        ? 'SOS will activate in $_countdown seconds'
                        : 'Press and hold the SOS button in case of emergency',
                style: TextStyle(
                  color: _isActivated ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: _isActivated ? Colors.red.withAlpha(38) : null,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SOS button
                    GestureDetector(
                      onLongPress: _isActivated ? null : _startCountdown,
                      onTap: _isCountingDown ? _cancelCountdown : null,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isActivated ? _animation.value : 1.0,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _isActivated ? Colors.red : Colors.red[100],
                                boxShadow: [
                                  BoxShadow(
                                    color: _isActivated
                                        ? Colors.red.withAlpha(140)
                                        : Colors.grey.withAlpha(76),
                                    spreadRadius: _isActivated ? 10 : 2,
                                    blurRadius: _isActivated ? 20 : 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: _isActivated
                                        ? Colors.white
                                        : Colors.red,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Instructions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _isActivated
                            ? 'Emergency services have been notified. Stay calm and wait for help.'
                            : _isCountingDown
                                ? 'Tap to cancel'
                                : 'Press and hold the SOS button to activate emergency mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: _isActivated ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Deactivate button
                    if (_isActivated)
                      ElevatedButton(
                        onPressed: _deactivateSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Deactivate SOS'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Quick call buttons
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Emergency Calls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: _emergencyServices.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _emergencyServices.length,
                          itemBuilder: (context, index) {
                            final service = _emergencyServices[index];
                            return _buildQuickCallButton(service);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCallButton(EmergencyService service) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _callEmergencyService(service),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: service.type.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(service.type),
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return Icons.local_police;
      case ServiceType.firetruck:
        return Icons.local_fire_department;
      case ServiceType.ambulance:
        return Icons.medical_services;
      case ServiceType.government:
        return Icons.account_balance;
      default:
        return Icons.emergency;
    }
  }
}
