import 'package:equatable/equatable.dart';

abstract class IrrigationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadIrrigationSystemsEvent extends IrrigationEvent {}

class LoadSystemDetailsEvent extends IrrigationEvent {
  final String systemId;

  LoadSystemDetailsEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class ToggleSystemEvent extends IrrigationEvent {
  final String systemId;
  final bool isActive;

  ToggleSystemEvent({required this.systemId, required this.isActive});

  @override
  List<Object> get props => [systemId, isActive];
}

class StartManualIrrigationEvent extends IrrigationEvent {
  final String systemId;
  final String? notes;

  StartManualIrrigationEvent({required this.systemId, this.notes});

  @override
  List<Object?> get props => [systemId, notes];
}

class StopIrrigationEvent extends IrrigationEvent {
  final String systemId;
  final String logId;

  StopIrrigationEvent({required this.systemId, required this.logId});

  @override
  List<Object> get props => [systemId, logId];
}

class AddSystemEvent extends IrrigationEvent {
  final String name;
  final String deviceSerial;
  final String cropType;
  final double? areaSize;
  final String? location;

  AddSystemEvent({
    required this.name,
    required this.deviceSerial,
    required this.cropType,
    this.areaSize,
    this.location,
  });

  @override
  List<Object?> get props => [name, deviceSerial, cropType, areaSize, location];
}

class LinkDeviceEvent extends IrrigationEvent {
  final String deviceSerial;
  final String systemName;

  LinkDeviceEvent({required this.deviceSerial, required this.systemName});

  @override
  List<Object> get props => [deviceSerial, systemName];
}

class DeleteSystemEvent extends IrrigationEvent {
  final String systemId;

  DeleteSystemEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class ClearIrrigationLogsEvent extends IrrigationEvent {
  final String systemId;

  ClearIrrigationLogsEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class RefreshSensorDataEvent extends IrrigationEvent {
  final String systemId;

  RefreshSensorDataEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class SetAutoIrrigationEvent extends IrrigationEvent {
  final String systemId;
  final bool enabled;

  SetAutoIrrigationEvent({required this.systemId, required this.enabled});

  @override
  List<Object> get props => [systemId, enabled];
}

class UpdateAutoIrrigationSettingsEvent extends IrrigationEvent {
  final String systemId;
  final double? startThreshold;
  final double? stopThreshold;

  UpdateAutoIrrigationSettingsEvent({
    required this.systemId,
    this.startThreshold,
    this.stopThreshold,
  });

  @override
  List<Object?> get props => [systemId, startThreshold, stopThreshold];
}
