import 'package:equatable/equatable.dart';

class IrrigationLog extends Equatable {
  final String id;
  final String systemId;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? waterUsedLiters;
  final double? soilMoistureBefore;
  final double? soilMoistureAfter;
  final String? triggeredBy;
  final String? notes;

  const IrrigationLog({
    required this.id,
    required this.systemId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.waterUsedLiters,
    this.soilMoistureBefore,
    this.soilMoistureAfter,
    this.triggeredBy,
    this.notes,
  });

  factory IrrigationLog.fromMap(Map<String, dynamic> map) {
    return IrrigationLog(
      id: map['id'] ?? '',
      systemId: map['system_id'] ?? '',
      type: map['type'] ?? 'manual',
      startTime:
          DateTime.parse(map['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      durationMinutes: map['duration_minutes'],
      waterUsedLiters: map['water_used_liters']?.toDouble(),
      soilMoistureBefore: map['soil_moisture_before']?.toDouble(),
      soilMoistureAfter: map['soil_moisture_after']?.toDouble(),
      triggeredBy: map['triggered_by'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        systemId,
        type,
        startTime,
        endTime,
        durationMinutes,
        waterUsedLiters,
        soilMoistureBefore,
        soilMoistureAfter,
        triggeredBy,
        notes,
      ];
}
