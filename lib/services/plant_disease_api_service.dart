import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlantDiseaseApiService {
  static const String _baseUrl = 'https://insect.kindwise.com/api/v1';
  static const String _apiKey =
      '5w7D0LSFR2l9f8TJtTJxoD8tnd0uno7fMa28vbWlSyMDf1GB4X';

  /// تشخيص أمراض النباتات باستخدام Kindwise API
  Future<Map<String, dynamic>> diagnosePlantDisease(File imageFile) async {
    try {
      // تحويل الصورة إلى base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // إعداد البيانات للإرسال
      final requestData = {
        'images': [base64Image],
        'modifiers': ['crops_fast', 'similar_images'],
        'plant_details': ['common_names', 'url']
      };

      // إرسال الطلب
      final response = await http.post(
        Uri.parse('$_baseUrl/identification'),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _apiKey,
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processApiResponse(data);
      } else {
        throw Exception('فشل في الاتصال بخدمة التشخيص: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في تشخيص المرض: $e');
    }
  }

  /// معالجة استجابة API وتحويلها للتنسيق المطلوب
  Map<String, dynamic> _processApiResponse(Map<String, dynamic> data) {
    try {
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      if (suggestions.isEmpty) {
        return {
          'predicted_disease': 'لم يتم العثور على تشخيص',
          'confidence_score': 0.0,
          'plant_name': 'غير محدد',
          'disease_details': {},
          'is_healthy': false,
          'similar_images': [],
        };
      }

      // أخذ أفضل نتيجة
      final bestSuggestion = suggestions.first as Map<String, dynamic>;
      final probability =
          (bestSuggestion['probability'] as num?)?.toDouble() ?? 0.0;

      // استخراج معلومات النبات
      final plantName = bestSuggestion['plant_name'] as String? ?? 'غير محدد';
      final plantDetails =
          bestSuggestion['plant_details'] as Map<String, dynamic>? ?? {};

      // استخراج الأسماء الشائعة
      final commonNames = plantDetails['common_names'] as List<dynamic>? ?? [];
      final arabicName = _getArabicPlantName(plantName, commonNames);

      // تحديد حالة النبات (صحي أم مريض)
      final isHealthy = _isPlantHealthy(bestSuggestion);

      // استخراج الصور المشابهة
      final similarImages = _extractSimilarImages(bestSuggestion);

      // تحديد نوع المرض أو الحالة
      String diseaseType = 'صحي';
      if (!isHealthy) {
        diseaseType = _extractDiseaseType(bestSuggestion);
      }

      return {
        'predicted_disease': diseaseType,
        'confidence_score': probability,
        'plant_name': arabicName,
        'plant_name_english': plantName,
        'disease_details': {
          'description': _getDiseaseDescription(diseaseType, isHealthy),
          'symptoms': _getDiseaseSymptoms(diseaseType, isHealthy),
          'causes': _getDiseaseCauses(diseaseType, isHealthy),
        },
        'is_healthy': isHealthy,
        'similar_images': similarImages,
        'plant_details': plantDetails,
        'raw_response': bestSuggestion, // للمطورين
      };
    } catch (e) {
      throw Exception('خطأ في معالجة استجابة API: $e');
    }
  }

  /// تحديد ما إذا كان النبات صحياً أم لا
  bool _isPlantHealthy(Map<String, dynamic> suggestion) {
    final plantName = (suggestion['plant_name'] as String? ?? '').toLowerCase();
    final probability = (suggestion['probability'] as num?)?.toDouble() ?? 0.0;

    // إذا كانت الثقة منخفضة، قد يكون هناك مشكلة
    if (probability < 0.3) {
      return false;
    }

    // البحث عن كلمات تدل على المرض
    final diseaseKeywords = [
      'disease',
      'blight',
      'rot',
      'spot',
      'mold',
      'virus',
      'fungus',
      'pest'
    ];
    for (final keyword in diseaseKeywords) {
      if (plantName.contains(keyword)) {
        return false;
      }
    }

    return true;
  }

  /// استخراج نوع المرض من الاستجابة
  String _extractDiseaseType(Map<String, dynamic> suggestion) {
    final plantName = (suggestion['plant_name'] as String? ?? '').toLowerCase();

    // خريطة الأمراض الشائعة
    final diseaseMap = {
      'blight': 'اللفحة',
      'spot': 'التبقع الورقي',
      'rot': 'العفن',
      'mold': 'العفن الفطري',
      'virus': 'الفيروس',
      'fungus': 'الفطريات',
      'pest': 'الآفات',
      'bacterial': 'البكتيريا',
      'mosaic': 'الموزاييك',
      'rust': 'الصدأ',
      'wilt': 'الذبول',
    };

    for (final entry in diseaseMap.entries) {
      if (plantName.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'مرض غير محدد';
  }

  /// الحصول على الاسم العربي للنبات
  String _getArabicPlantName(String englishName, List<dynamic> commonNames) {
    final plantNameMap = {
      'tomato': 'الطماطم',
      'potato': 'البطاطا',
      'corn': 'الذرة',
      'maize': 'الذرة',
      'wheat': 'القمح',
      'rice': 'الأرز',
      'onion': 'البصل',
      'garlic': 'الثوم',
      'pepper': 'الفلفل',
      'cucumber': 'الخيار',
      'lettuce': 'الخس',
      'cabbage': 'الملفوف',
      'carrot': 'الجزر',
      'bean': 'الفاصولياء',
      'pea': 'البازلاء',
    };

    final lowerName = englishName.toLowerCase();
    for (final entry in plantNameMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    // البحث في الأسماء الشائعة
    for (final name in commonNames) {
      final nameStr = name.toString().toLowerCase();
      for (final entry in plantNameMap.entries) {
        if (nameStr.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return englishName; // إرجاع الاسم الإنجليزي إذا لم نجد ترجمة
  }

  /// استخراج الصور المشابهة
  List<String> _extractSimilarImages(Map<String, dynamic> suggestion) {
    final similarImages = <String>[];

    try {
      final images = suggestion['similar_images'] as List<dynamic>? ?? [];
      for (final image in images) {
        if (image is Map<String, dynamic>) {
          final url = image['url'] as String?;
          if (url != null && url.isNotEmpty) {
            similarImages.add(url);
          }
        }
      }
    } catch (e) {
      print('خطأ في استخراج الصور المشابهة: $e');
    }

    return similarImages;
  }

  /// الحصول على وصف المرض
  String _getDiseaseDescription(String diseaseType, bool isHealthy) {
    if (isHealthy) {
      return 'النبات يبدو في حالة صحية جيدة. لا توجد علامات واضحة للأمراض أو الآفات.';
    }

    final descriptions = {
      'اللفحة':
          'مرض فطري يصيب الأوراق والسيقان، يسبب بقع بنية أو سوداء تنتشر بسرعة.',
      'التبقع الورقي':
          'مرض يسبب ظهور بقع ملونة على الأوراق، قد تكون فطرية أو بكتيرية.',
      'العفن': 'نمو فطري يظهر على شكل طبقة رقيقة على سطح النبات.',
      'العفن الفطري': 'عدوى فطرية تسبب تعفن أجزاء من النبات.',
      'الفيروس': 'عدوى فيروسية تؤثر على نمو النبات وتسبب تشوهات في الأوراق.',
      'الفطريات': 'عدوى فطرية تصيب أجزاء مختلفة من النبات.',
      'الآفات': 'إصابة بالحشرات أو الآفات الأخرى التي تضر بالنبات.',
      'البكتيريا': 'عدوى بكتيرية تسبب تعفن أو تلف في أنسجة النبات.',
      'الموزاييك': 'فيروس يسبب ظهور نمط موزاييكي على الأوراق.',
      'الصدأ': 'مرض فطري يسبب ظهور بقع صدئة اللون على الأوراق.',
      'الذبول': 'حالة تسبب ذبول النبات وفقدان الماء.',
    };

    return descriptions[diseaseType] ??
        'مرض يؤثر على صحة النبات ويتطلب العلاج المناسب.';
  }

  /// الحصول على أعراض المرض
  List<String> _getDiseaseSymptoms(String diseaseType, bool isHealthy) {
    if (isHealthy) {
      return [
        'أوراق خضراء صحية',
        'نمو طبيعي',
        'لا توجد بقع أو تشوهات',
        'لون طبيعي للنبات'
      ];
    }

    final symptoms = {
      'اللفحة': [
        'بقع بنية أو سوداء على الأوراق',
        'ذبول الأوراق المصابة',
        'انتشار سريع للعدوى',
        'تساقط الأوراق'
      ],
      'التبقع الورقي': [
        'بقع ملونة على الأوراق',
        'تغير لون الأوراق',
        'ضعف في النمو',
        'تشوه في شكل الأوراق'
      ],
      'العفن': [
        'طبقة بيضاء أو رمادية على النبات',
        'رائحة عفنة',
        'تعفن الأنسجة',
        'ضعف عام في النبات'
      ],
      'الفيروس': [
        'تشوه في الأوراق',
        'تغير في اللون',
        'ضعف في النمو',
        'أنماط غير طبيعية على الأوراق'
      ],
      'الآفات': [
        'ثقوب في الأوراق',
        'وجود حشرات',
        'تلف في أجزاء النبات',
        'ضعف عام'
      ],
    };

    return symptoms[diseaseType] ??
        ['تغيرات في مظهر النبات', 'ضعف في النمو', 'علامات المرض واضحة'];
  }

  /// الحصول على أسباب المرض
  List<String> _getDiseaseCauses(String diseaseType, bool isHealthy) {
    if (isHealthy) {
      return ['رعاية جيدة', 'ظروف نمو مناسبة', 'ري منتظم', 'تغذية متوازنة'];
    }

    final causes = {
      'اللفحة': [
        'الرطوبة العالية',
        'سوء التهوية',
        'الري المفرط',
        'درجات حرارة غير مناسبة'
      ],
      'التبقع الورقي': [
        'العدوى الفطرية أو البكتيرية',
        'الرطوبة العالية',
        'ضعف مقاومة النبات',
        'انتشار العدوى من نباتات أخرى'
      ],
      'العفن': [
        'الرطوبة المفرطة',
        'سوء التهوية',
        'الري الزائد',
        'درجات حرارة منخفضة'
      ],
      'الفيروس': [
        'انتقال العدوى عبر الحشرات',
        'استخدام أدوات ملوثة',
        'النباتات المصابة القريبة',
        'ضعف مناعة النبات'
      ],
      'الآفات': [
        'وجود حشرات ضارة',
        'عدم استخدام المبيدات',
        'ظروف بيئية مناسبة للآفات',
        'ضعف النبات'
      ],
    };

    return causes[diseaseType] ??
        ['عوامل بيئية غير مناسبة', 'ضعف في الرعاية', 'انتشار العدوى'];
  }

  /// الحصول على العلاجات المقترحة
  List<Map<String, dynamic>> getTreatmentSuggestions(
      String diseaseType, bool isHealthy) {
    if (isHealthy) {
      return [
        {
          'title': 'الحفاظ على الرعاية الجيدة',
          'description': 'استمر في الرعاية الحالية للنبات',
          'steps': [
            'ري منتظم ومعتدل',
            'تسميد متوازن',
            'مراقبة دورية للنبات',
            'توفير إضاءة مناسبة'
          ]
        }
      ];
    }

    final treatments = {
      'اللفحة': [
        {
          'title': 'العلاج الفطري',
          'description': 'استخدام مبيدات فطرية مناسبة',
          'steps': [
            'إزالة الأجزاء المصابة',
            'رش بمبيد فطري',
            'تحسين التهوية',
            'تقليل الري'
          ]
        }
      ],
      'التبقع الورقي': [
        {
          'title': 'العلاج المتكامل',
          'description': 'علاج شامل للتبقع الورقي',
          'steps': [
            'إزالة الأوراق المصابة',
            'استخدام مبيد مناسب',
            'تحسين ظروف النمو',
            'تقوية مناعة النبات'
          ]
        }
      ],
      'العفن': [
        {
          'title': 'مكافحة العفن',
          'description': 'علاج العفن وتحسين البيئة',
          'steps': [
            'تحسين التهوية',
            'تقليل الرطوبة',
            'استخدام مبيد فطري',
            'إزالة الأجزاء المتعفنة'
          ]
        }
      ],
      'الفيروس': [
        {
          'title': 'إدارة العدوى الفيروسية',
          'description': 'لا يوجد علاج مباشر للفيروسات',
          'steps': [
            'عزل النبات المصاب',
            'مكافحة الحشرات الناقلة',
            'تقوية النبات بالتسميد',
            'إزالة النباتات المصابة بشدة'
          ]
        }
      ],
      'الآفات': [
        {
          'title': 'مكافحة الآفات',
          'description': 'علاج الآفات الحشرية',
          'steps': [
            'تحديد نوع الآفة',
            'استخدام مبيد حشري مناسب',
            'إزالة الحشرات يدوياً',
            'تحسين صحة النبات'
          ]
        }
      ],
    };

    return treatments[diseaseType] ??
        [
          {
            'title': 'العلاج العام',
            'description': 'خطوات عامة لعلاج المرض',
            'steps': [
              'تحديد سبب المشكلة',
              'تحسين ظروف النمو',
              'استشارة خبير زراعي',
              'مراقبة تطور الحالة'
            ]
          }
        ];
  }

  /// الحصول على نصائح الوقاية
  List<Map<String, dynamic>> getPreventionTips(
      String diseaseType, bool isHealthy) {
    return [
      {
        'title': 'الوقاية العامة',
        'description': 'نصائح عامة للوقاية من الأمراض',
        'steps': [
          'فحص النباتات بانتظام',
          'توفير تهوية جيدة',
          'ري معتدل ومنتظم',
          'استخدام تربة صحية',
          'تنظيف الأدوات الزراعية',
          'عزل النباتات المصابة'
        ]
      },
      {
        'title': 'التغذية المتوازنة',
        'description': 'تقوية مناعة النبات',
        'steps': [
          'استخدام سماد متوازن',
          'توفير العناصر الغذائية الأساسية',
          'تجنب الإفراط في التسميد',
          'مراقبة علامات نقص التغذية'
        ]
      }
    ];
  }
}
