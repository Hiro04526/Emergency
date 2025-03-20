import 'package:flutter/material.dart';
import '../models/emergency_alert.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Global key for accessing the scaffold messenger
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  Future<void> initialize() async {
    // No initialization needed for this simplified version
  }

  void showNotification({
    required String title,
    required String message,
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 4),
  }) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showAlertNotification(EmergencyAlert alert) {
    showNotification(
      title: alert.title,
      message: alert.description,
      backgroundColor: alert.type.color,
      duration: const Duration(seconds: 10),
    );
  }
}
