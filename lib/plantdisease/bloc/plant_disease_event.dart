import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class PlantDiseaseEvent extends Equatable {
  const PlantDiseaseEvent();

  @override
  List<Object> get props => [];
}

class PlantDiseaseDataRequested extends PlantDiseaseEvent {}

class PlantDiseaseImageSelected extends PlantDiseaseEvent {
  final File imageFile;
  final String plantType;

  const PlantDiseaseImageSelected({
    required this.imageFile,
    required this.plantType,
  });

  @override
  List<Object> get props => [imageFile, plantType];
}

class PlantDiseaseDiagnosisRequested extends PlantDiseaseEvent {
  final File imageFile;
  final String plantType;

  const PlantDiseaseDiagnosisRequested({
    required this.imageFile,
    required this.plantType,
  });

  @override
  List<Object> get props => [imageFile, plantType];
}

class PlantDiseaseSaveRequested extends PlantDiseaseEvent {
  final Map<String, dynamic> diagnosisData;

  const PlantDiseaseSaveRequested({required this.diagnosisData});

  @override
  List<Object> get props => [diagnosisData];
}

class PlantDiseaseStatusUpdated extends PlantDiseaseEvent {
  final String diagnosisId;
  final String status;

  const PlantDiseaseStatusUpdated({
    required this.diagnosisId,
    required this.status,
  });

  @override
  List<Object> get props => [diagnosisId, status];
}

class PlantTypeChanged extends PlantDiseaseEvent {
  final String plantType;

  const PlantTypeChanged({required this.plantType});

  @override
  List<Object> get props => [plantType];
}
