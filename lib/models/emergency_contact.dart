import '../models/emergency_service.dart';

class EmergencyContact {
  final String id;
  final String name;
  final ServiceType type;
  final String? phoneNumber;
  final String? address;
  final String? barangay;
  final String? city;
  final String? province;
  final String? region;
  final String? street;
  final String? addedBy;
  final bool isVerified;
  final String? verifiedBy;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.type,
    this.phoneNumber,
    this.address,
    this.barangay,
    this.city,
    this.province,
    this.region,
    this.street,
    this.addedBy,
    this.isVerified = false,
    this.verifiedBy,
  });

  // Create a copy with updated fields
  EmergencyContact copyWith({
    String? id,
    String? name,
    ServiceType? type,
    String? phoneNumber,
    String? address,
    String? barangay,
    String? city,
    String? province,
    String? region,
    String? street,
    String? addedBy,
    bool? isVerified,
    String? verifiedBy,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      province: province ?? this.province,
      region: region ?? this.region,
      street: street ?? this.street,
      addedBy: addedBy ?? this.addedBy,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}
