import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// نموذج بيانات الطقس
class WeatherData {
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final double? rainProbability;
  final double soilMoisture;
  final String cityName;
  final String iconCode;
  final DateTime timestamp;
  final double feelsLike;
  final double uvIndex;
  final int visibility;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    this.rainProbability,
    required this.soilMoisture,
    required this.cityName,
    required this.iconCode,
    required this.timestamp,
    required this.feelsLike,
    required this.uvIndex,
    required this.visibility,
  });

  factory WeatherData.fromWeatherAPI(Map<String, dynamic> json) {
    final current = json['current'];
    final location = json['location'];
    final condition = current['condition'];

    // حساب رطوبة التربة بناءً على الرطوبة الجوية
    final humidity = current['humidity'].toDouble();
    final soilMoisture = humidity * 0.7;

    // احتمالية المطر من forecast إذا كانت متوفرة
    double? rainProb;
    if (json['forecast'] != null &&
        json['forecast']['forecastday'] != null &&
        json['forecast']['forecastday'].isNotEmpty) {
      final today = json['forecast']['forecastday'][0];
      if (today['day'] != null &&
          today['day']['daily_chance_of_rain'] != null) {
        rainProb = today['day']['daily_chance_of_rain'].toDouble();
      }
    }

    return WeatherData(
      temperature: current['temp_c'].toDouble(),
      description: condition['text'] ?? 'غير محدد',
      humidity: humidity.toInt(),
      windSpeed: current['wind_kph']?.toDouble() ?? 0.0,
      rainProbability: rainProb,
      soilMoisture: soilMoisture,
      cityName: location['name'] ?? 'موقع غير محدد',
      iconCode: _extractIconCode(condition['icon'] ?? ''),
      timestamp: DateTime.now(),
      feelsLike: current['feelslike_c']?.toDouble() ?? 0.0,
      uvIndex: current['uv']?.toDouble() ?? 0.0,
      visibility: current['vis_km']?.toInt() ?? 0,
    );
  }

  // تحويل إلى JSON للتخزين المؤقت
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'rainProbability': rainProbability,
      'soilMoisture': soilMoisture,
      'cityName': cityName,
      'iconCode': iconCode,
      'timestamp': timestamp.toIso8601String(),
      'feelsLike': feelsLike,
      'uvIndex': uvIndex,
      'visibility': visibility,
    };
  }

  // إنشاء من JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      humidity: json['humidity']?.toInt() ?? 0,
      windSpeed: json['windSpeed']?.toDouble() ?? 0.0,
      rainProbability: json['rainProbability']?.toDouble(),
      soilMoisture: json['soilMoisture']?.toDouble() ?? 0.0,
      cityName: json['cityName'] ?? '',
      iconCode: json['iconCode'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      feelsLike: json['feelsLike']?.toDouble() ?? 0.0,
      uvIndex: json['uvIndex']?.toDouble() ?? 0.0,
      visibility: json['visibility']?.toInt() ?? 0,
    );
  }

  // استخراج كود الأيقونة من URL
  static String _extractIconCode(String iconUrl) {
    if (iconUrl.isEmpty) return 'day/113'; // صافي نهاراً

    // استخراج اسم الملف من URL
    final parts = iconUrl.split('/');
    if (parts.length >= 2) {
      final fileName = parts[parts.length - 1]; // مثل: 113.png
      final folder = parts[parts.length - 2]; // مثل: day أو night
      return '$folder/${fileName.replaceAll('.png', '')}';
    }

    return 'day/113';
  }
}

class WeatherService {
  static const String _apiKey = 'fbe21a67d6b6410f8f0172948250202';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  // دالة لجلب بيانات الطقس بناءً على الموقع
  static Future<WeatherData> getWeatherData() async {
    try {
      Position? position;
      try {
        // محاولة الحصول على الموقع الحالي
        position = await _getCurrentLocation();
      } catch (e) {
        // في حالة فشل الحصول على الموقع، استخدم موقع تعز الافتراضي
        debugPrint('فشل في الحصول على الموقع، استخدام موقع تعز الافتراضي: $e');
      }

      // استخدام إحداثيات تعز كموقع افتراضي (إحداثيات دقيقة لمدينة تعز)
      final lat = position?.latitude ?? 13.5795; // خط عرض تعز
      final lon = position?.longitude ?? 44.0207; // خط طول تعز

      // جلب بيانات الطقس مع التوقعات
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/forecast.json?key=$_apiKey&q=$lat,$lon&days=1&aqi=no&alerts=no&lang=ar'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final weatherData = WeatherData.fromWeatherAPI(jsonData);

        // حفظ البيانات في التخزين المؤقت
        await _cacheWeatherData(weatherData);

        return weatherData;
      } else {
        throw Exception('فشل في جلب بيانات الطقس: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('حدث خطأ في جلب بيانات الطقس: $e');
    }
  }

  // دالة للحصول على الموقع الحالي
  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة الموقع معطلة. يرجى تفعيلها من الإعدادات.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض أذونات الموقع. يرجى السماح بالوصول للموقع.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'تم رفض أذونات الموقع بشكل دائم. يرجى تفعيلها من إعدادات التطبيق.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }

  // دالة للحصول على أيقونة الطقس المناسبة (WeatherAPI codes)
  static String getWeatherIcon(String iconCode) {
    // استخراج رقم الكود من iconCode مثل day/113 أو night/116
    final codeNumber = iconCode.split('/').last;
    final isDay = iconCode.contains('day');

    switch (codeNumber) {
      case '113': // صافي
        return isDay ? '☀️' : '🌙';
      case '116': // غيوم جزئية
        return isDay ? '⛅' : '☁️';
      case '119': // غائم
      case '122': // غائم جداً
        return '☁️';
      case '143': // ضباب
      case '248': // ضباب
      case '260': // ضباب متجمد
        return '🌫️';
      case '176': // مطر خفيف متقطع
      case '263': // رذاذ خفيف
      case '266': // رذاذ خفيف
      case '281': // رذاذ متجمد
      case '284': // رذاذ متجمد كثيف
        return '🌦️';
      case '179': // ثلج خفيف متقطع
      case '227': // ثلج منفوخ
      case '323': // ثلج خفيف متقطع
      case '326': // ثلج خفيف
      case '329': // ثلج متوسط
      case '332': // ثلج كثيف
      case '335': // ثلج كثيف جداً
      case '338': // ثلج كثيف
      case '368': // ثلج خفيف
      case '371': // ثلج متوسط إلى كثيف
        return '❄️';
      case '182': // مطر متجمد خفيف
      case '185': // مطر متجمد خفيف
      case '311': // مطر متجمد خفيف
      case '314': // مطر متجمد متوسط إلى كثيف
      case '317': // مطر متجمد كثيف
        return '🧊';
      case '200': // عاصفة رعدية مع مطر خفيف
      case '386': // عاصفة رعدية خفيفة
      case '389': // عاصفة رعدية متوسطة إلى كثيفة
      case '392': // عاصفة رعدية خفيفة مع ثلج
      case '395': // عاصفة رعدية متوسطة إلى كثيفة مع ثلج
        return '⛈️';
      case '293': // مطر خفيف متقطع
      case '296': // مطر خفيف
      case '299': // مطر متوسط متقطع
      case '302': // مطر متوسط
      case '305': // مطر كثيف متقطع
      case '308': // مطر كثيف
      case '353': // مطر خفيف
      case '356': // مطر متوسط إلى كثيف
      case '359': // مطر غزير
        return '�️';
      default:
        return isDay ? '🌤️' : '🌙';
    }
  }

  // دالة للحصول على لون الخلفية بناءً على حالة الطقس (WeatherAPI)
  static List<Color> getWeatherGradient(String iconCode) {
    final codeNumber = iconCode.split('/').last;
    final isDay = iconCode.contains('day');

    switch (codeNumber) {
      case '113': // صافي
        return isDay
            ? [
                const Color(0xFF4FC3F7),
                const Color(0xFF29B6F6)
              ] // أزرق فاتح نهاراً
            : [
                const Color(0xFF1A237E),
                const Color(0xFF303F9F)
              ]; // أزرق داكن ليلاً

      case '116': // غيوم جزئية
        return isDay
            ? [const Color(0xFF42A5F5), const Color(0xFF1E88E5)] // أزرق متوسط
            : [const Color(0xFF283593), const Color(0xFF3949AB)];

      case '119': // غائم
      case '122': // غائم جداً
        return [const Color(0xFF78909C), const Color(0xFF546E7A)]; // رمادي

      case '143': // ضباب
      case '248':
      case '260':
        return [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)]; // رمادي فاتح

      case '176': // مطر خفيف
      case '263':
      case '266':
      case '281':
      case '284':
      case '293':
      case '296':
      case '299':
      case '302':
      case '305':
      case '308':
      case '353':
      case '356':
      case '359':
        return [
          const Color(0xFF5C6BC0),
          const Color(0xFF3F51B5)
        ]; // أزرق بنفسجي للمطر

      case '179': // ثلج
      case '227':
      case '323':
      case '326':
      case '329':
      case '332':
      case '335':
      case '338':
      case '368':
      case '371':
        return [
          const Color(0xFF90A4AE),
          const Color(0xFF607D8B)
        ]; // رمادي أزرق للثلج

      case '182': // مطر متجمد
      case '185':
      case '311':
      case '314':
      case '317':
        return [
          const Color(0xFF81C784),
          const Color(0xFF4CAF50)
        ]; // أخضر مزرق للمطر المتجمد

      case '200': // عاصفة رعدية
      case '386':
      case '389':
      case '392':
      case '395':
        return [
          const Color(0xFF7E57C2),
          const Color(0xFF512DA8)
        ]; // بنفسجي للعواصف

      default:
        return isDay
            ? [
                const Color(0xFF4FC3F7),
                const Color(0xFF29B6F6)
              ] // افتراضي نهاراً
            : [
                const Color(0xFF1A237E),
                const Color(0xFF303F9F)
              ]; // افتراضي ليلاً
    }
  }

  // دالة للحصول على البيانات المحفوظة
  static Future<WeatherData?> getCachedWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_weather_data');
      if (cachedData != null) {
        final jsonData = json.decode(cachedData);
        return WeatherData.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات المحفوظة: $e');
      return null;
    }
  }

  // دالة لحفظ البيانات في التخزين المؤقت
  static Future<void> _cacheWeatherData(WeatherData weatherData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = weatherData.toJson();
      await prefs.setString('cached_weather_data', json.encode(jsonData));
    } catch (e) {
      debugPrint('خطأ في حفظ البيانات: $e');
    }
  }

  // دالة للحصول على بيانات افتراضية
  static WeatherData getDefaultWeatherData() {
    return WeatherData(
      temperature: 25.0,
      description: 'طقس معتدل',
      humidity: 60,
      windSpeed: 10.0,
      rainProbability: 20.0,
      soilMoisture: 42.0,
      cityName: 'تعز',
      iconCode: '01d',
      timestamp: DateTime.now(),
      feelsLike: 27.0,
      uvIndex: 5.0,
      visibility: 10,
    );
  }
}
