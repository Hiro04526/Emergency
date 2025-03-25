import 'package:flutter/material.dart';
import '../models/emergency_service.dart';

class ServiceCard extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onTap;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
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

              // Call icon
              IconButton(
                icon: const Icon(Icons.phone),
                color: service.type.color,
                onPressed: () {
                  // TODO: Implement direct call functionality
                },
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
      case ServiceType.medical:
        return Icons.medical_services;
      case ServiceType.fireStation:
        return Icons.local_fire_department;
      case ServiceType.government:
        return Icons.account_balance;
      default:
        return Icons.emergency;
    }
  }
}
