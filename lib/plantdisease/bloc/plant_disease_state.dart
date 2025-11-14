import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class PlantDiseaseState extends Equatable {
  const PlantDiseaseState();

  @override
  List<Object> get props => [];
}

class PlantDiseaseLoading extends PlantDiseaseState {}

class PlantDiseaseLoaded extends PlantDiseaseState {
  final List<Map<String, dynamic>> diagnoses;
  final String selectedPlantType;

  const PlantDiseaseLoaded({
    required this.diagnoses,
    required this.selectedPlantType,
  });

  @override
  List<Object> get props => [diagnoses, selectedPlantType];
}

class PlantDiseaseImagePreview extends PlantDiseaseState {
  final File imageFile;
  final String plantType;

  const PlantDiseaseImagePreview({
    required this.imageFile,
    required this.plantType,
  });

  @override
  List<Object> get props => [imageFile, plantType];
}

class PlantDiseaseDiagnosing extends PlantDiseaseState {
  final File imageFile;
  final String plantType;

  const PlantDiseaseDiagnosing({
    required this.imageFile,
    required this.plantType,
  });

  @override
  List<Object> get props => [imageFile, plantType];
}

class PlantDiseaseDiagnosed extends PlantDiseaseState {
  final File imageFile;
  final Map<String, dynamic> diagnosis;
  final Map<String, dynamic> diseaseInfo;

  const PlantDiseaseDiagnosed({
    required this.imageFile,
    required this.diagnosis,
    required this.diseaseInfo,
  });

  @override
  List<Object> get props => [imageFile, diagnosis, diseaseInfo];
}

class PlantDiseaseError extends PlantDiseaseState {
  final String message;

  const PlantDiseaseError({required this.message});

  @override
  List<Object> get props => [message];
}
