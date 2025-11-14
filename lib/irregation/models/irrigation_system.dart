import 'package:equatable/equatable.dart';

class IrrigationSystem extends Equatable {
  final String id;
  final String name;
  final String deviceSerial;
  final String cropType;
  final double? areaSize;
  final String? location;
  final bool isActive;
  final bool autoIrrigationEnabled;
  final int waterLowThreshold;
  final DateTime createdAt;

  const IrrigationSystem({
    required this.id,
    required this.name,
    required this.deviceSerial,
    required this.cropType,
    this.areaSize,
    this.location,
    required this.isActive,
    required this.autoIrrigationEnabled,
    required this.waterLowThreshold,
    required this.createdAt,
  });

  factory IrrigationSystem.fromMap(Map<String, dynamic> map) {
    return IrrigationSystem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      deviceSerial: map['device_serial'] ?? map['esp32_serial'] ?? '',
      cropType: map['crop_type'] ?? '',
      areaSize: map['area_size']?.toDouble(),
      location: map['location'],
      isActive: map['is_active'] ?? false,
      autoIrrigationEnabled: map['auto_irrigation_enabled'] ?? false,
      waterLowThreshold: map['water_low_threshold'] ?? 30,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        deviceSerial,
        cropType,
        areaSize,
        location,
        isActive,
        autoIrrigationEnabled,
        waterLowThreshold,
        createdAt,
      ];

  IrrigationSystem copyWith({
    String? id,
    String? name,
    String? deviceSerial,
    String? cropType,
    double? areaSize,
    String? location,
    bool? isActive,
    bool? autoIrrigationEnabled,
    int? waterLowThreshold,
    DateTime? createdAt,
  }) {
    return IrrigationSystem(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceSerial: deviceSerial ?? this.deviceSerial,
      cropType: cropType ?? this.cropType,
      areaSize: areaSize ?? this.areaSize,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      autoIrrigationEnabled:
          autoIrrigationEnabled ?? this.autoIrrigationEnabled,
      waterLowThreshold: waterLowThreshold ?? this.waterLowThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
