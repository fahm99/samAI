// plant_disease.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sam/services/supabaseservice.dart';
import 'package:sam/theme/theme.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show compute;
import 'package:shared_preferences/shared_preferences.dart';

// Plant Disease Events
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

// Plant Disease States
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


// Plant Disease Bloc
class PlantDiseaseBloc extends Bloc<PlantDiseaseEvent, PlantDiseaseState> {
  final SupabaseService _supabaseService;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _modelLoaded = false;
  String _currentPlantType = '';

  // خريطة جميع أنواع النباتات (مدعومة وغير مدعومة)
  static const Map<String, Map<String, dynamic>> allPlants = {
    // النباتات المدعومة (لها نماذج ذكاء اصطناعي)
    'طماطم': {
      'modelPath': 'assets/models/Tomato/model_unquant.tflite',
      'labelsPath': 'assets/models/Tomato/labels.txt',
      'englishName': 'tomato',
      'isSupported': true,
      'displayName': 'الطماطم',
      'icon': 'eco'
    },
    'بطاطا': {
      'modelPath': 'assets/models/Potato/model_unquant.tflite',
      'labelsPath': 'assets/models/Potato/labels.txt',
      'englishName': 'potato',
      'isSupported': true,
      'displayName': 'البطاطا',
      'icon': 'eco'
    },

    // النباتات غير المدعومة حالياً (بدون نماذج)
    'موز': {
      'englishName': 'banana',
      'isSupported': false,
      'displayName': 'الموز',
      'icon': 'nature',
      'comingSoon': true
    },
    'بصل': {
      'englishName': 'onion',
      'isSupported': false,
      'displayName': 'البصل',
      'icon': 'eco',
      'comingSoon': true
    },
    'قمح': {
      'englishName': 'maize',
      'isSupported': false,
      'displayName': 'القمح',
      'icon': 'grass',
      'comingSoon': true
    },
    'قات': {
      'englishName': 'qat',
      'isSupported': false,
      'displayName': 'القات',
      'icon': 'local_florist',
      'comingSoon': true
    },
  };

  // خريطة النباتات المدعومة فقط (للتوافق مع الكود الحالي)
  static Map<String, Map<String, String>> get supportedPlants {
    return Map.fromEntries(
      allPlants.entries
          .where((entry) => entry.value['isSupported'] == true)
          .map((entry) => MapEntry(
                entry.key,
                {
                  'modelPath': entry.value['modelPath'] as String,
                  'labelsPath': entry.value['labelsPath'] as String,
                  'englishName': entry.value['englishName'] as String,
                },
              )),
    );
  }


  PlantDiseaseBloc(this._supabaseService) : super(PlantDiseaseLoading()) {
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
      await _loadModelForPlantType(_currentPlantType);
    } catch (e) {
      print('Error initializing default plant type: $e');
      _currentPlantType = 'طماطم';
      _modelLoaded = false;
      _labels = _getDefaultLabelsForPlantType(_currentPlantType);
    }
  }

  Future<void> _loadModelForPlantType(String plantType) async {
    try {
      if (!supportedPlants.containsKey(plantType)) {
        throw Exception('نوع النبات غير مدعوم: $plantType');
      }

      final plantConfig = supportedPlants[plantType]!;
      final modelPath = plantConfig['modelPath']!;
      final labelsPath = plantConfig['labelsPath']!;

      print('🌱 تحميل نموذج $plantType...');
      print('📁 مسار النموذج: $modelPath');
      print('🏷️ مسار التسميات: $labelsPath');

      // إغلاق النموذج السابق إن وجد
      _interpreter?.close();
      _modelLoaded = false;

      // تحميل النموذج المخصص لنوع النبات
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('✅ تم تحميل النموذج بنجاح');

      // تحميل التسميات المخصصة
      await _loadLabelsForPlantType(labelsPath);

      _modelLoaded = true;
      _currentPlantType = plantType;

      // حفظ اختيار المستخدم
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_plant_type', plantType);

      print('🎯 تم تحميل نموذج $plantType بنجاح مع ${_labels.length} تسمية');
    } catch (e) {
      print('❌ خطأ في تحميل نموذج $plantType: $e');
      _modelLoaded = false;
      // استخدام التسميات الافتراضية
      _labels = _getDefaultLabelsForPlantType(plantType);
      print('📋 استخدام التسميات الافتراضية: ${_labels.length}');
    }
  }

  Future<void> _loadLabelsForPlantType(String labelsPath) async {
    try {
      final labelsData = await rootBundle.loadString(labelsPath);
      final rawLabels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      // تنظيف التسميات من الأرقام في البداية
      _labels = rawLabels.map((label) {
        final trimmed = label.trim();
        if (trimmed.contains(' ')) {
          final parts = trimmed.split(' ');
          if (parts.isNotEmpty && RegExp(r'^\d+$').hasMatch(parts[0])) {
            return parts.skip(1).join(' ');
          }
        }
        return trimmed;
      }).toList();

      print('📋 تم تحميل ${_labels.length} تسمية من $labelsPath');
      print('🏷️ التسميات المحملة: ${_labels.take(3).join(', ')}...');
    } catch (e) {
      print('⚠️ فشل في تحميل التسميات من $labelsPath: $e');
      // استخدام تسميات افتراضية حسب نوع النبات
      _labels = _getDefaultLabelsForPlantType(_currentPlantType);
      print('📋 استخدام التسميات الافتراضية: ${_labels.length}');
    }
  }

  List<String> _getDefaultLabelsForPlantType(String plantType) {
    switch (plantType) {
      case 'طماطم':
        return [
          'Tomato Bacterial spot',
          'Tomato Early blight',
          'Tomato healthy',
          'Tomato Late blight',
          'Tomato Leaf Mold',
          'Tomato mosaic virus',
          'Tomato Septoria leaf spot',
          'Tomato Spider mites Two spotted spider mite',
          'Tomato Target Spot',
          'Tomato Yellow Leaf Cur Virus',
          'No Leaf Found'
        ];
      case 'بطاطا':
        return [
          'Potato Bacteria',
          'Potato Fungi',
          'Potato Healthy',
          'Potato Nematode',
          'Potato Pest',
          'Potato Phytopthora',
          'Potato Virus',
          'Potato Diseased',
          'No leaf found'
        ];
      case 'موز':
        return [
          'Banana Healthy',
          'Banana Black Sigatoka',
          'Banana Panama Disease'
        ];
      case 'بصل':
        return ['Onion Healthy', 'Onion Downy Mildew', 'Onion Purple Blotch'];
      case 'قمح':
        return [
          'Maize Healthy',
          'Maize Northern Leaf Blight',
          'Maize Common Rust'
        ];
      case 'قات':
        return ['Qat Healthy', 'Qat Leaf Spot', 'Qat Powdery Mildew'];
      default:
        return ['Healthy', 'Diseased'];
    }
  }

  Future<void> _onPlantTypeChanged(
    PlantTypeChanged event,
    Emitter<PlantDiseaseState> emit,
  ) async {
    try {
      // التحقق من أن النبات مدعوم
      if (!supportedPlants.containsKey(event.plantType)) {
        emit(PlantDiseaseError(
          message:
              'نموذج ${event.plantType} غير مدعوم حالياً. يرجى اختيار نوع نبات آخر.',
        ));
        return;
      }

      emit(PlantDiseaseLoading());
      await _loadModelForPlantType(event.plantType);

      final diagnoses = await _supabaseService.getUserDiagnoses();
      emit(PlantDiseaseLoaded(
        diagnoses: diagnoses,
        selectedPlantType: event.plantType,
      ));
    } catch (e) {
      emit(PlantDiseaseError(
          message: 'فشل في تحميل نموذج ${event.plantType}: $e'));
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
        selectedPlantType: 'طماطم',
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
      String predictedLabel;
      double confidence;

      if (_modelLoaded && _interpreter != null) {
        // معالجة الصورة للنموذج
        final processedImage = await preprocessWithCompression(event.imageFile);

        // تحقق من شكل البيانات المدخلة
        print('=== تحقق من البيانات المدخلة ===');
        print(
            'Input shape: [${processedImage.length}, ${processedImage[0].length}, ${processedImage[0][0].length}, ${processedImage[0][0][0].length}]');
        print('Expected: [1, 224, 224, 3]');

        // عينة من القيم للتحقق من التطبيع (يجب أن تكون بين 0 و 1)
        print('Sample pixel values (should be 0-1):');
        for (int i = 0; i < 3; i++) {
          print(
              '  Channel $i: ${processedImage[0][0][0][i].toStringAsFixed(4)}');
        }

        // تشغيل التنبؤ
        final output =
            List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
        print('Output shape: [${output.length}, ${output[0].length}]');

        _interpreter!.run(processedImage, output);

        // الحصول على التنبؤ
        final predictions = output[0] as List<double>;

        // تحليل التنبؤات
        double maxPred = predictions.reduce((a, b) => a > b ? a : b);
        double minPred = predictions.reduce((a, b) => a < b ? a : b);
        double variance = _calculateVariance(predictions);

        print('📊 تحليل التنبؤات:');
        print('   التباين: ${variance.toStringAsFixed(6)}');
        print('   أقل قيمة: ${(minPred * 100).toStringAsFixed(2)}%');
        print('   أعلى قيمة: ${(maxPred * 100).toStringAsFixed(2)}%');

        if (variance > 0.01) {
          print('✅ التنبؤات متنوعة - النموذج يعمل بشكل صحيح');
        } else {
          print('⚠️ التنبؤات متشابهة - قد تكون هناك مشكلة في التطبيع');
        }

        // طباعة جميع التنبؤات للتشخيص
        print('=== تفاصيل التنبؤ ===');
        for (int i = 0; i < predictions.length && i < _labels.length; i++) {
          print('${_labels[i]}: ${(predictions[i] * 100).toStringAsFixed(2)}%');
        }

        final maxIndex =
            predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
        confidence = predictions[maxIndex];
        predictedLabel = _labels[maxIndex];

        print('=== النتيجة النهائية ===');
        print(
            'Prediction: $predictedLabel, Confidence: ${(confidence * 100).toStringAsFixed(2)}%');
        print('Max Index: $maxIndex');
        print('Total predictions: ${predictions.length}');
        print('Total labels: ${_labels.length}');
      } else {
        // إذا لم يتم تحميل النموذج، أرسل خطأ
        throw Exception(
            'نموذج الذكاء الاصطناعي غير متاح. يرجى إعادة تشغيل التطبيق.');
      }

      // الحصول على معلومات المرض من قاعدة البيانات
      final diseaseInfo =
          await _supabaseService.getCompleteDiseaseInfo(predictedLabel);

      // الحصول على العلاجات وطرق الوقاية
      List<dynamic> treatments = [];
      List<dynamic> preventions = [];

      if (diseaseInfo != null && diseaseInfo['disease'] != null) {
        final diseaseId = diseaseInfo['disease']['id'];
        if (diseaseId != null) {
          try {
            treatments = await _supabaseService.getDiseaseTreatments(diseaseId);
            preventions =
                await _supabaseService.getDiseasePrevention(diseaseId);
          } catch (e) {
            print('Error loading treatments/preventions: $e');
          }
        }
      }

      final diagnosis = {
        'plant_type': event.plantType,
        'predicted_disease': predictedLabel,
        'confidence_score': confidence,
        'image_file': event.imageFile,
        'treatments': treatments,
        'preventions': preventions,
      };

      emit(PlantDiseaseDiagnosed(
        imageFile: event.imageFile,
        diagnosis: diagnosis,
        diseaseInfo: diseaseInfo ?? {},
      ));
    } catch (e) {
      print('Diagnosis error: $e');
      String errorMessage;
      if (e.toString().contains('نموذج الذكاء الاصطناعي غير متاح')) {
        errorMessage =
            'نموذج الذكاء الاصطناعي غير متاح. يرجى إعادة تشغيل التطبيق.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'خطأ في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
      } else if (e.toString().contains('file') ||
          e.toString().contains('image')) {
        errorMessage =
            'خطأ في معالجة الصورة. يرجى اختيار صورة أخرى والمحاولة مرة أخرى.';
      } else {
        errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      }
      emit(PlantDiseaseError(message: errorMessage));
    }
  }

  // دالة حساب التباين للتنبؤات
  double _calculateVariance(List<double> predictions) {
    double mean = predictions.reduce((a, b) => a + b) / predictions.length;
    double variance = predictions
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        predictions.length;
    return variance;
  }

  Future<List<List<List<List<double>>>>> preprocessWithCompression(
      File imageFile) async {
    try {
      // ضغط الصورة أولاً
      final compressed = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 224,
        minHeight: 224,
        quality: 90,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        throw Exception('فشل في ضغط الصورة');
      }

      // معالجة الصورة في خيط منفصل لتجنب تجميد الواجهة
      return await compute(_processImageInBackground, compressed);
    } catch (e) {
      print('Error in preprocessing: $e');
      rethrow;
    }
  }

  // دالة ثابتة لمعالجة الصورة في خيط منفصل
  static List<List<List<List<double>>>> _processImageInBackground(
      List<int> compressedBytes) {
    try {
      // قراءة الصورة وتحويلها (بدون فلاتر إضافية)
      var image = img.decodeImage(Uint8List.fromList(compressedBytes))!;
      image = img.copyResize(image, width: 224, height: 224);

      // استخدم نفس التطبيع المستخدم في المستودع المرجعي
      return _convertToModelInputStatic(image);
    } catch (e) {
      print('خطأ في معالجة الصورة: $e');
      rethrow;
    }
  }

  // دالة ثابتة لتحويل الصورة إلى مدخل النموذج مع تطبيع متعدد
  static List<List<List<List<double>>>> _convertToModelInputStatic(
      img.Image image) {
    try {
      // التأكد من أن الصورة 224x224
      if (image.width != 224 || image.height != 224) {
        image = img.copyResize(image, width: 224, height: 224);
      }

      // تحويل إلى مصفوفة 4D
      var input = List.generate(
          1,
          (i) => List.generate(224,
              (j) => List.generate(224, (k) => List.generate(3, (l) => 0.0))));

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          var pixel = image.getPixel(x, y);

          // استخدم نفس التطبيع المستخدم في المستودع المرجعي
          // imageMean: 0.0, imageStd: 255.0 يعني (pixel - 0.0) / 255.0
          double r = pixel.r / 255.0;
          double g = pixel.g / 255.0;
          double b = pixel.b / 255.0;

          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
        }
      }

      return input;
    } catch (e) {
      print('خطأ في تحويل الصورة: $e');
      rethrow;
    }
  }

  // دالة لاختبار تطبيع مختلف
  static List<List<List<List<double>>>> _convertWithDifferentNormalization(
      img.Image image, int normalizationType) {
    try {
      if (image.width != 224 || image.height != 224) {
        image = img.copyResize(image, width: 224, height: 224);
      }

      var input = List.generate(
          1,
          (i) => List.generate(224,
              (j) => List.generate(224, (k) => List.generate(3, (l) => 0.0))));

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          var pixel = image.getPixel(x, y);

          double r, g, b;

          switch (normalizationType) {
            case 0: // [0, 1]
              r = pixel.r / 255.0;
              g = pixel.g / 255.0;
              b = pixel.b / 255.0;
              break;
            case 1: // [-1, 1]
              r = (pixel.r / 255.0 - 0.5) * 2.0;
              g = (pixel.g / 255.0 - 0.5) * 2.0;
              b = (pixel.b / 255.0 - 0.5) * 2.0;
              break;
            case 2: // ImageNet normalization
              r = (pixel.r / 255.0 - 0.485) / 0.229;
              g = (pixel.g / 255.0 - 0.456) / 0.224;
              b = (pixel.b / 255.0 - 0.406) / 0.225;
              break;
            default:
              r = pixel.r / 255.0;
              g = pixel.g / 255.0;
              b = pixel.b / 255.0;
          }

          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
        }
      }

      return input;
    } catch (e) {
      print('خطأ في تحويل الصورة: $e');
      rethrow;
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

  @override
  Future<void> close() {
    try {
      if (_modelLoaded && _interpreter != null) {
        _interpreter!.close();
      }
    } catch (e) {
      print('Error closing interpreter: $e');
    }
    return super.close();
  }
}

// Plant Disease Screen Widget
class PlantDiseaseScreen extends StatelessWidget {
  const PlantDiseaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PlantDiseaseBloc(SupabaseService())..add(PlantDiseaseDataRequested()),
      child: Scaffold(
        body: BlocBuilder<PlantDiseaseBloc, PlantDiseaseState>(
          builder: (context, state) {
            if (state is PlantDiseaseLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل النموذج...',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'قد يستغرق هذا بضع ثوانٍ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else if (state is PlantDiseaseError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<PlantDiseaseBloc>()
                            .add(PlantDiseaseDataRequested());
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is PlantDiseaseImagePreview) {
              return ImagePreviewScreen(
                imageFile: state.imageFile,
                plantType: state.plantType,
              );
            } else if (state is PlantDiseaseDiagnosing) {
              return DiagnosingScreen(imageFile: state.imageFile);
            } else if (state is PlantDiseaseDiagnosed) {
              return DiagnosisResultScreen(
                imageFile: state.imageFile,
                diagnosis: state.diagnosis,
                diseaseInfo: state.diseaseInfo,
              );
            } else if (state is PlantDiseaseLoaded) {
              return PlantDiseaseMainScreen(
                diagnoses: state.diagnoses,
                selectedPlantType: state.selectedPlantType,
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: BlocBuilder<PlantDiseaseBloc, PlantDiseaseState>(
          builder: (context, state) {
            if (state is PlantDiseaseLoaded) {
              return FloatingActionButton(
                onPressed: () =>
                    _showImageSourceDialog(context, state.selectedPlantType),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, String plantType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null) {
                  context.read<PlantDiseaseBloc>().add(
                        PlantDiseaseImageSelected(
                          imageFile: File(image.path),
                          plantType: plantType,
                        ),
                      );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  context.read<PlantDiseaseBloc>().add(
                        PlantDiseaseImageSelected(
                          imageFile: File(image.path),
                          plantType: plantType,
                        ),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PlantDiseaseMainScreen extends StatefulWidget {
  final List<Map<String, dynamic>> diagnoses;
  final String selectedPlantType;

  const PlantDiseaseMainScreen({
    super.key,
    required this.diagnoses,
    required this.selectedPlantType,
  });

  @override
  _PlantDiseaseMainScreenState createState() => _PlantDiseaseMainScreenState();
}

class _PlantDiseaseMainScreenState extends State<PlantDiseaseMainScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedPlantType = 'طماطم';

  // Cache للبيانات المحملة
  final Map<String, List<Map<String, dynamic>>> _diagnosesCache = {};
  bool _isLoading = false;

  // Cache للنماذج المحملة
  final Map<String, bool> _modelsLoaded = {};

  // تحميل النموذج بشكل lazy مع تحسينات الأداء
  Future<void> _loadModelIfNeeded(String plantType) async {
    if (_modelsLoaded[plantType] == true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // حفظ مرجع للـ context قبل العمليات غير المتزامنة
      final bloc = context.read<PlantDiseaseBloc>();

      // تأخير قصير لتجنب blocking الـ UI
      await Future.delayed(const Duration(milliseconds: 50));

      // تحميل النموذج في background
      bloc.add(PlantTypeChanged(plantType: plantType));

      _modelsLoaded[plantType] = true;
    } catch (e) {
      _modelsLoaded[plantType] = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true; // الحفاظ على حالة الشاشة

  @override
  void initState() {
    super.initState();
    _selectedPlantType = widget.selectedPlantType;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPlantTypeSelection(),
          const SizedBox(height: 16),
          _buildUploadArea(),
          const SizedBox(height: 16),
          _buildDetectionHistory(),
        ],
      ),
    );
  }

  Widget _buildPlantTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'اختر نوع النبات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: [
                // النباتات المدعومة
                _buildPlantTypeItem('طماطم', 'الطماطم', Icons.eco, true),
                _buildPlantTypeItem('بطاطا', 'البطاطا', Icons.eco, true),

                // النباتات غير المدعومة حالياً
                _buildPlantTypeItem('موز', 'الموز', Icons.nature, false),
                _buildPlantTypeItem('بصل', 'البصل', Icons.eco, false),
                _buildPlantTypeItem('قمح', 'القمح', Icons.grass, false),
                _buildPlantTypeItem('قات', 'القات', Icons.local_florist, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantTypeItem(
      String id, String name, IconData icon, bool isSupported) {
    final isSelected = _selectedPlantType == id;

    return GestureDetector(
      onTap: () async {
        if (isSupported) {
          setState(() {
            _selectedPlantType = id;
          });
          // تحميل النموذج بشكل lazy
          await _loadModelIfNeeded(id);
        } else {
          // إظهار رسالة مفصلة للنباتات غير المدعومة
          _showUnsupportedPlantDialog(context, name);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isSupported ? null : Colors.grey.withOpacity(0.1)),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isSupported ? Colors.grey.shade300 : Colors.grey.shade400),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSupported
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSupported ? AppColors.primary : Colors.grey,
                  ),
                ),
                if (!isSupported)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSupported ? null : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تشخيص أمراض النباتات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'التقط صورة واضحة للنبات المصاب للحصول على تشخيص دقيق',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('التقاط صورة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('من المعرض'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.info),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'سجل التشخيصات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.diagnoses.isNotEmpty)
                  IconButton(
                    onPressed: () => _showDeleteConfirmationDialog(context),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    tooltip: 'حذف جميع التشخيصات',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.diagnoses.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.science, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد تشخيصات',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              // استخدام ListView.builder للأداء الأفضل
              SizedBox(
                height: 400, // ارتفاع محدد للقائمة
                child: ListView.builder(
                  itemCount: widget.diagnoses.length,
                  itemBuilder: (context, index) {
                    return _buildOptimizedDiagnosisItem(
                        widget.diagnoses[index]);
                  },
                  physics: const BouncingScrollPhysics(),
                  cacheExtent: 200, // تحسين الذاكرة
                  addAutomaticKeepAlives: false, // توفير الذاكرة
                  addRepaintBoundaries: false, // تحسين الرسم
                ),
              ),
          ],
        ),
      ),
    );
  }

  // دالة محسنة لعرض التشخيصات مع تحسينات الأداء
  Widget _buildOptimizedDiagnosisItem(Map<String, dynamic> diagnosis) {
    return RepaintBoundary(
      // تحسين الرسم
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DiagnosisDetailScreen(diagnosis: diagnosis),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // صورة التشخيص مع تحسينات
              _buildOptimizedImage(diagnosis['image_path']),
              const SizedBox(width: 12),
              // معلومات التشخيص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnosis['plant_diseases']?['name'] ??
                          diagnosis['disease_name'] ??
                          'مرض غير محدد',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تم التشخيص منذ ${_getTimeAgo(diagnosis['detection_date'] ?? diagnosis['created_at'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(diagnosis['status']),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // دالة محسنة لعرض الصور
  Widget _buildOptimizedImage(String? imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade300,
        child: imagePath != null && imagePath.isNotEmpty
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, color: Colors.grey);
                },
              )
            : Icon(Icons.eco, color: Colors.grey),
      ),
    );
  }

  // دالة محسنة لعرض حالة التشخيص
  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showUnsupportedPlantDialog(BuildContext context, String plantName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'نموذج غير متوفر',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نموذج $plantName غير متوفر حالياً',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'سيتم توفير النموذج قريباً',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى اختيار نوع نبات آخر',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'النماذج المتوفرة حالياً: الطماطم والبطاطا',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'حسناً',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _pickImage(ImageSource source) async {
    final bloc = context.read<PlantDiseaseBloc>();
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image != null) {
      bloc.add(
        PlantDiseaseImageSelected(
          imageFile: File(image.path),
          plantType: _selectedPlantType,
        ),
      );
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return 'غير محدد';

    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} أيام';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعات';
    } else {
      return '${difference.inMinutes} دقائق';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'treated':
        return AppColors.success;
      case 'treating':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'treated':
        return 'تم العلاج';
      case 'treating':
        return 'قيد المعالجة';
      default:
        return 'تم التشخيص';
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('تأكيد الحذف'),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف جميع التشخيصات السابقة؟\n\nلا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAllDiagnoses(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف الكل'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllDiagnoses(BuildContext context) async {
    // حفظ مرجع للـ Navigator قبل العملية غير المتزامنة
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bloc = context.read<PlantDiseaseBloc>();

    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // حذف جميع التشخيصات من قاعدة البيانات
      print('🗑️ بدء عملية حذف جميع التشخيصات...');
      final supabaseService = SupabaseService();

      // التحقق من هوية المستخدم قبل الحذف
      final currentUser = supabaseService.currentUser;
      if (currentUser == null) {
        print('🚨 خطأ أمني: لا يوجد مستخدم مسجل دخول');
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      print('🔒 تأكيد هوية المستخدم: ${currentUser.id}');
      final success = await supabaseService.deleteAllUserDiagnoses();
      print('📋 نتيجة عملية الحذف: ${success ? "نجح" : "فشل"}');

      // إخفاء مؤشر التحميل
      if (mounted) {
        try {
          navigator.pop();
        } catch (e) {
          print('Error closing loading dialog: $e');
        }
      }

      if (mounted) {
        if (success) {
          // إظهار رسالة نجاح
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('تم حذف جميع التشخيصات بنجاح'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );

          // تحديث الشاشة فوراً
          print('🔄 تحديث قائمة التشخيصات...');
          bloc.add(PlantDiseaseDataRequested());
        } else {
          // إظهار رسالة خطأ مع تفاصيل أكثر
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'فشل في حذف التشخيصات. تحقق من الاتصال بالإنترنت وحاول مرة أخرى.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: () {
                  _deleteAllDiagnoses(context);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      if (mounted) {
        try {
          navigator.pop();
        } catch (e) {
          print('Error closing loading dialog in catch: $e');
        }
      }

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('حدث خطأ: $e'),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final String plantType;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.plantType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'معاينة الصورة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 243, 243, 243),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image, color: AppColors.info),
                          const SizedBox(width: 8),
                          const Text(
                            'صورة النبات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<PlantDiseaseBloc>().add(
                        PlantDiseaseDiagnosisRequested(
                          imageFile: imageFile,
                          plantType: plantType,
                        ),
                      );
                },
                icon: const Icon(Icons.biotech),
                label: const Text('تشخيص المرض'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagnosingScreen extends StatelessWidget {
  final File imageFile;

  const DiagnosingScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'جاري التشخيص...',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 253, 255, 253),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // العودة إلى الشاشة الرئيسية
            context.read<PlantDiseaseBloc>().add(PlantDiseaseDataRequested());
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'جاري تشخيص المرض...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قد يستغرق هذا بضع ثوانٍ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagnosisResultScreen extends StatelessWidget {
  final File imageFile;
  final Map<String, dynamic> diagnosis;
  final Map<String, dynamic> diseaseInfo;

  const DiagnosisResultScreen({
    super.key,
    required this.imageFile,
    required this.diagnosis,
    required this.diseaseInfo,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            // عند الضغط على زر العودة في الجهاز، العودة إلى الشاشة الرئيسية
            context.read<PlantDiseaseBloc>().add(PlantDiseaseDataRequested());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'نتائج التشخيص',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color.fromARGB(255, 235, 235, 235),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // العودة إلى الشاشة الرئيسية بدلاً من pop
                context
                    .read<PlantDiseaseBloc>()
                    .add(PlantDiseaseDataRequested());
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDiagnosisResult(),
                const SizedBox(height: 16),
                if (diseaseInfo.isNotEmpty) ...[
                  _buildDiseaseInfo(),
                  const SizedBox(height: 16),
                ],
                _buildActionButtons(context),
              ],
            ),
          ),
        ));
  }

  Widget _buildDiagnosisResult() {
    // الحصول على معلومات المرض من diseaseInfo أو diagnosis
    final diseaseData = diseaseInfo['disease'] ?? {};
    final diseaseName = diseaseData['name'] ?? diagnosis['predicted_disease'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.biotech, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'نتيجة التشخيص',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تشخيص المرض',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          diseaseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'نسبة الثقة',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${((diagnosis['confidence_score'] ?? 0.0) * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseInfo() {
    final diseaseData = diseaseInfo['disease'] ?? {};
    final symptoms = diseaseInfo['symptoms'] ?? [];
    final treatments = diseaseInfo['treatments'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات عن المرض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (diseaseData['description'] != null) ...[
              Text(
                diseaseData['description'],
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            if (symptoms.isNotEmpty) ...[
              const Text(
                'الأعراض',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...symptoms.map((symptom) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, left: 8),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            symptom['symptom_name'] ?? symptom.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (treatments.isNotEmpty) ...[
              const Text(
                'العلاجات المتاحة',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...treatments.take(3).map((treatment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, left: 8),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            treatment['treatment_name'] ?? treatment.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreatmentScreen(
                    diagnosis: diagnosis,
                    diseaseInfo: diseaseInfo,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.medical_services),
            label: const Text('اكتشف العلاج'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Save diagnosis
              context.read<PlantDiseaseBloc>().add(
                    PlantDiseaseSaveRequested(diagnosisData: diagnosis),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم حفظ التشخيص بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
              // العودة إلى الشاشة الرئيسية
              context.read<PlantDiseaseBloc>().add(PlantDiseaseDataRequested());
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ التشخيص'),
          ),
        ),
      ],
    );
  }
}

class DiagnosisDetailScreen extends StatelessWidget {
  final Map<String, dynamic> diagnosis;

  const DiagnosisDetailScreen({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل التشخيص',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (diagnosis['image_path'] != null &&
                        diagnosis['image_path'].isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          diagnosis['image_path'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: Icon(Icons.image,
                                  size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      diagnosis['plant_diseases']?['name'] ??
                          diagnosis['disease_name'] ??
                          'مرض غير محدد',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(diagnosis['status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getStatusText(diagnosis['status']),
                        style: TextStyle(
                          color: _getStatusColor(diagnosis['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تفاصيل إضافية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                        'تاريخ التشخيص',
                        _formatDate(diagnosis['detection_date'] ??
                            diagnosis['created_at'])),
                    _buildDetailRow(
                        'نوع النبات', diagnosis['plant_type'] ?? 'غير محدد'),
                    if (diagnosis['confidence'] != null)
                      _buildDetailRow('نسبة الثقة',
                          '${(diagnosis['confidence'] * 100).toInt()}%'),
                    if (diagnosis['notes'] != null)
                      _buildDetailRow('ملاحظات', diagnosis['notes']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'غير محدد',
              style: const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'treated':
        return AppColors.success;
      case 'treating':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'treated':
        return 'تم العلاج';
      case 'treating':
        return 'قيد المعالجة';
      default:
        return 'تم التشخيص';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }
}

class TreatmentScreen extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  final Map<String, dynamic> diseaseInfo;

  const TreatmentScreen({
    super.key,
    required this.diagnosis,
    required this.diseaseInfo,
  });

  @override
  Widget build(BuildContext context) {
    final diseaseData = diseaseInfo['disease'] ?? {};
    final treatments =
        diagnosis['treatments'] ?? diseaseInfo['treatments'] ?? [];
    final prevention =
        diagnosis['preventions'] ?? diseaseInfo['prevention'] ?? [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'علاج ${diseaseData['name'] ?? 'المرض'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDiseaseSummary(),
            const SizedBox(height: 16),
            if (treatments.isNotEmpty) ...[
              _buildTreatmentOptions(treatments),
              const SizedBox(height: 16),
            ],
            if (prevention.isNotEmpty) ...[
              _buildPreventionMethods(prevention),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseSummary() {
    final diseaseData = diseaseInfo['disease'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: Icon(Icons.eco, color: Colors.grey, size: 40),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diseaseData['name'] ?? diagnosis['predicted_disease'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تم التشخيص بنسبة ثقة ${((diagnosis['confidence_score'] ?? 0.0) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (diseaseData['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      diseaseData['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentOptions(List<dynamic> treatments) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_services, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                const Text(
                  'خيارات العلاج المتاحة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (treatments.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد علاجات متاحة حالياً',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...treatments.asMap().entries.map(
                  (entry) => _buildTreatmentItem(entry.value, entry.key + 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentItem(dynamic treatment, [int? index]) {
    String name = '';
    String description = '';
    String applicationMethod = '';
    String dosage = '';
    double effectiveness = 0.0;

    if (treatment is Map) {
      name = treatment['treatment_name'] ?? '';
      description = treatment['description'] ?? '';
      applicationMethod = treatment['application_method'] ?? '';
      dosage = treatment['dosage'] ?? '';
      effectiveness = (treatment['effectiveness_rating'] ?? 0.0).toDouble();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medical_services, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (effectiveness > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'الفعالية: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(effectiveness * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (applicationMethod.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'طريقة التطبيق: $applicationMethod',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (dosage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'الجرعة: $dosage',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreventionMethods(List<dynamic> prevention) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'إجراءات وقائية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...prevention.map((method) => _buildPreventionItem(method)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreventionItem(dynamic method) {
    String name = '';
    String description = '';

    if (method is Map) {
      name = method['prevention_method'] ?? '';
      description = method['description'] ?? '';
    } else {
      name = method.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم تحديث حالة المرض إلى "تم العلاج"'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.check),
            label: const Text('تم العلاج'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم مشاركة العلاج في السوق'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('مشاركة في السوق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
