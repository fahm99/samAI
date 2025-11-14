import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/supabaseservice.dart';
import '../../services/plant_disease_api_service.dart';
import '../models/plant_types.dart';
import 'plant_disease_event.dart';
import 'plant_disease_state.dart';

class PlantDiseaseApiBloc extends Bloc<PlantDiseaseEvent, PlantDiseaseState> {
  final SupabaseService _supabaseService;
  final PlantDiseaseApiService _apiService;
  String _currentPlantType = '';

  PlantDiseaseApiBloc(this._supabaseService)
      : _apiService = PlantDiseaseApiService(),
        super(PlantDiseaseLoading()) {
    on<PlantDiseaseDataRequested>(_onPlantDiseaseDataRequested);
    on<PlantDiseaseImageSelected>(_onPlantDiseaseImageSelected);
    on<PlantDiseaseDiagnosisRequested>(_onPlantDiseaseDiagnosisRequested);
    on<PlantDiseaseSaveRequested>(_onPlantDiseaseSaveRequested);
    on<PlantDiseaseStatusUpdated>(_onPlantDiseaseStatusUpdated);
    on<PlantTypeChanged>(_onPlantTypeChanged);

    _initializeDefaultPlantType();
  }

  Future<void> _initializeDefaultPlantType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlantType = prefs.getString('selected_plant_type') ?? 'طماطم';
      _currentPlantType = savedPlantType;
      print('🌱 تم تهيئة نوع النبات الافتراضي: $_currentPlantType');
    } catch (e) {
      print('❌ خطأ في تهيئة نوع النبات الافتراضي: $e');
      _currentPlantType = 'طماطم';
    }
  }

  Future<void> _setPlantType(String plantType) async {
    try {
      if (!PlantTypes.supportedPlants.containsKey(plantType)) {
        throw Exception('نوع النبات غير مدعوم: $plantType');
      }

      _currentPlantType = plantType;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_plant_type', plantType);

      print('🌱 تم تحديد نوع النبات: $plantType');
    } catch (e) {
      print('❌ خطأ في تحديد نوع النبات $plantType: $e');
      rethrow;
    }
  }

  Future<void> _onPlantTypeChanged(
    PlantTypeChanged event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    try {
      if (!PlantTypes.supportedPlants.containsKey(event.plantType)) {
        emit(PlantDiseaseError(
          message: 'نوع النبات ${event.plantType} غير مدعوم حالياً.',
        ));
        return;
      }

      emit(PlantDiseaseLoading());
      await _setPlantType(event.plantType);

      final diagnoses = await _supabaseService.getUserDiagnoses();
      emit(PlantDiseaseLoaded(
        diagnoses: diagnoses,
        selectedPlantType: event.plantType,
      ));
    } catch (e) {
      emit(PlantDiseaseError(
          message: 'فشل في تحديد نوع النبات ${event.plantType}: $e'));
    }
  }

  Future<void> _onPlantDiseaseDataRequested(
    PlantDiseaseDataRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    emit(PlantDiseaseLoading());
    try {
      final diagnoses = await _supabaseService.getUserDiagnoses();
      emit(PlantDiseaseLoaded(
        diagnoses: diagnoses,
        selectedPlantType:
            _currentPlantType.isNotEmpty ? _currentPlantType : 'طماطم',
      ));
    } catch (e) {
      emit(PlantDiseaseError(message: e.toString()));
    }
  }

  Future<void> _onPlantDiseaseImageSelected(
    PlantDiseaseImageSelected event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    emit(PlantDiseaseImagePreview(
      imageFile: event.imageFile,
      plantType: event.plantType,
    ));
  }

  Future<void> _onPlantDiseaseDiagnosisRequested(
    PlantDiseaseDiagnosisRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    emit(PlantDiseaseDiagnosing(
      imageFile: event.imageFile,
      plantType: event.plantType,
    ));

    try {
      print('🔍 بدء تشخيص المرض باستخدام API...');

      final apiResult = await _apiService.diagnosePlantDisease(event.imageFile);

      print('✅ تم الحصول على نتيجة التشخيص من API');
      print('📊 النتيجة: ${apiResult['predicted_disease']}');
      print(
          '🎯 الثقة: ${(apiResult['confidence_score'] * 100).toStringAsFixed(1)}%');

      final diagnosis = {
        'plant_type': event.plantType,
        'predicted_disease': apiResult['predicted_disease'],
        'confidence_score': apiResult['confidence_score'],
        'plant_name': apiResult['plant_name'],
        'plant_name_english': apiResult['plant_name_english'],
        'is_healthy': apiResult['is_healthy'],
        'image_file': event.imageFile,
        'api_response': apiResult,
      };

      final treatments = _apiService.getTreatmentSuggestions(
          apiResult['predicted_disease'], apiResult['is_healthy']);

      final preventions = _apiService.getPreventionTips(
          apiResult['predicted_disease'], apiResult['is_healthy']);

      diagnosis['treatments'] = treatments;
      diagnosis['preventions'] = preventions;

      final diseaseInfo = {
        'disease': {
          'name': apiResult['predicted_disease'],
          'description': apiResult['disease_details']['description'],
          'symptoms': apiResult['disease_details']['symptoms'],
          'causes': apiResult['disease_details']['causes'],
        },
        'plant_details': apiResult['plant_details'],
        'similar_images': apiResult['similar_images'],
      };

      emit(PlantDiseaseDiagnosed(
        imageFile: event.imageFile,
        diagnosis: diagnosis,
        diseaseInfo: diseaseInfo,
      ));
    } catch (e) {
      print('❌ خطأ في التشخيص: $e');
      String errorMessage;

      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('internet')) {
        errorMessage =
            'خطأ في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
      } else if (e.toString().contains('file') ||
          e.toString().contains('image')) {
        errorMessage =
            'خطأ في معالجة الصورة. يرجى اختيار صورة أخرى والمحاولة مرة أخرى.';
      } else if (e.toString().contains('API') ||
          e.toString().contains('service')) {
        errorMessage = 'خطأ في خدمة التشخيص. يرجى المحاولة مرة أخرى لاحقاً.';
      } else {
        errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      }

      emit(PlantDiseaseError(message: errorMessage));
    }
  }

  Future<void> _onPlantDiseaseSaveRequested(
    PlantDiseaseSaveRequested event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    try {
      await _supabaseService.saveDiagnosis(event.diagnosisData);
      add(PlantDiseaseDataRequested());
    } catch (e) {
      emit(PlantDiseaseError(message: e.toString()));
    }
  }

  Future<void> _onPlantDiseaseStatusUpdated(
    PlantDiseaseStatusUpdated event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    try {
      await _supabaseService.updateDiagnosisStatus(
          event.diagnosisId, event.status);
      add(PlantDiseaseDataRequested());
    } catch (e) {
      emit(PlantDiseaseError(message: e.toString()));
    }
  }

}
