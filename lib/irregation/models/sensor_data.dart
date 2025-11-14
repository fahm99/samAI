import 'package:equatable/equatable.dart';

class SensorData extends Equatable {
  final String id;
  final String systemId;
  final double? soilMoisture;
  final double? temperature;
  final double? humidity;
  final double? waterLevel;
  final double? lightIntensity;
  final double? phLevel;
  final bool? rainDetected;
  final DateTime timestamp;

  const SensorData({
    required this.id,
    required this.systemId,
    this.soilMoisture,
    this.temperature,
    this.humidity,
    this.waterLevel,
    this.lightIntensity,
    this.phLevel,
    this.rainDetected,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id'] ?? '',
      systemId: map['system_id'] ?? '',
      soilMoisture: map['soil_moisture']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      humidity: map['humidity']?.toDouble(),
      waterLevel: map['water_level']?.toDouble(),
      lightIntensity: map['light_intensity']?.toDouble(),
      phLevel: map['ph_level']?.toDouble(),
      rainDetected:
          map['rain_detected'] == null ? null : map['rain_detected'] == true,
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
        id,
        systemId,
        soilMoisture,
        temperature,
        humidity,
        waterLevel,
        lightIntensity,
        phLevel,
        rainDetected,
        timestamp,
      ];
}
