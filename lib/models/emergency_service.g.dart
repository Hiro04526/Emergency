// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmergencyServiceAdapter extends TypeAdapter<EmergencyService> {
  @override
  final int typeId = 0;

  @override
  EmergencyService read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmergencyService(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as ServiceType,
      level: fields[3] as String,
      description: fields[4] as String?,
      distanceKm: fields[5] as double,
      contact: fields[6] as String?,
      contacts: (fields[7] as List?)?.cast<String>(),
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      isVerified: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyService obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.distanceKm)
      ..writeByte(6)
      ..write(obj.contact)
      ..writeByte(7)
      ..write(obj.contacts)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.isVerified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyServiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ServiceTypeAdapter extends TypeAdapter<ServiceType> {
  @override
  final int typeId = 1;

  @override
  ServiceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ServiceType.police;
      case 1:
        return ServiceType.medical;
      case 2:
        return ServiceType.fireStation;
      case 3:
        return ServiceType.government;
      default:
        return ServiceType.police;
    }
  }

  @override
  void write(BinaryWriter writer, ServiceType obj) {
    switch (obj) {
      case ServiceType.police:
        writer.writeByte(0);
        break;
      case ServiceType.medical:
        writer.writeByte(1);
        break;
      case ServiceType.fireStation:
        writer.writeByte(2);
        break;
      case ServiceType.government:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
