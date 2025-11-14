import 'package:equatable/equatable.dart';
import '../models/irrigation_system.dart';
import '../models/sensor_data.dart';
import '../models/irrigation_log.dart';

abstract class IrrigationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IrrigationInitial extends IrrigationState {}

class IrrigationLoading extends IrrigationState {}

class IrrigationSystemsLoaded extends IrrigationState {
  final List<IrrigationSystem> systems;

  IrrigationSystemsLoaded({required this.systems});

  @override
  List<Object> get props => [systems];

  IrrigationSystemsLoaded copyWith({
    List<IrrigationSystem>? systems,
  }) {
    return IrrigationSystemsLoaded(
      systems: systems ?? this.systems,
    );
  }
}

class SystemDetailsLoaded extends IrrigationState {
  final IrrigationSystem system;
  final List<SensorData> sensorData;
  final List<IrrigationLog> irrigationLogs;

  SystemDetailsLoaded({
    required this.system,
    required this.sensorData,
    required this.irrigationLogs,
  });

  @override
  List<Object> get props => [system, sensorData, irrigationLogs];

  SystemDetailsLoaded copyWith({
    IrrigationSystem? system,
    List<SensorData>? sensorData,
    List<IrrigationLog>? irrigationLogs,
  }) {
    return SystemDetailsLoaded(
      system: system ?? this.system,
      sensorData: sensorData ?? this.sensorData,
      irrigationLogs: irrigationLogs ?? this.irrigationLogs,
    );
  }
}

class IrrigationError extends IrrigationState {
  final String message;

  IrrigationError({required this.message});

  @override
  List<Object> get props => [message];
}

class IrrigationSuccess extends IrrigationState {
  final String message;

  IrrigationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
