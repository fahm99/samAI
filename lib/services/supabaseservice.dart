// supabaseservice.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // التحقق من صحة الجلسة الحالية
  Future<bool> isSessionValid() async {
    try {
      final session = client.auth.currentSession;
      if (session == null) return false;

      // التحقق من انتهاء صلاحية الجلسة
      final now = DateTime.now();
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

      if (now.isAfter(expiresAt)) {
        // محاولة تجديد الجلسة
        try {
          await client.auth.refreshSession();
          return client.auth.currentSession != null;
        } catch (e) {
          print('Error refreshing session: $e');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  // استعادة الجلسة من التخزين المحلي
  Future<bool> restoreSession() async {
    try {
      // Supabase Flutter يقوم بهذا تلقائياً عند التهيئة
      // لكن يمكننا التحقق من صحة الجلسة المستعادة
      return await isSessionValid();
    } catch (e) {
      print('Error restoring session: $e');
      return false;
    }
  }

  // Authentication Methods
  Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error signing in: $e');
      throw Exception('خطأ في تسجيل الدخول: ${e.toString()}');
    }
  }

  // التحقق من تكرار البريد الإلكتروني
  Future<bool> isEmailExists(String email) async {
    try {
      final response = await client
          .from('profiles')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // التحقق من تكرار رقم الهاتف
  Future<bool> isPhoneExists(String phoneNumber, String countryCode) async {
    try {
      final fullPhoneNumber = '$countryCode$phoneNumber';
      final response = await client
          .from('profiles')
          .select('id')
          .eq('phone_number', phoneNumber.trim())
          .eq('country_code', countryCode)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking phone existence: $e');
      return false;
    }
  }

  // ===== نظام OTP للبريد الإلكتروني =====

  // إرسال رمز التحقق عبر البريد الإلكتروني
  Future<bool> sendEmailOTP(String email) async {
    try {
      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // لا ننشئ المستخدم بعد، فقط نرسل OTP
      );
      return true;
    } catch (e) {
      print('Error sending email OTP: $e');
      throw Exception(_getOTPErrorMessage(e));
    }
  }

  // التحقق من رمز OTP وإنشاء الحساب
  Future<AuthResponse?> verifyEmailOTPAndSignUp(
    String email,
    String otp,
    String password, {
    String? fullName,
    String? location,
    String? phoneNumber,
    String? countryCode,
  }) async {
    try {
      // أولاً نتحقق من صحة OTP
      final otpResponse = await client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: email,
      );

      if (otpResponse.user != null) {
        // إذا نجح التحقق، نقوم بتحديث كلمة المرور وإنشاء البروفايل
        await client.auth.updateUser(UserAttributes(password: password));

        // إنشاء بروفايل المستخدم
        await createUserProfile(otpResponse.user!.id, {
          'full_name': fullName ?? '',
          'location': location ?? '',
          'phone_number': phoneNumber ?? '',
          'country_code': countryCode ?? '+967',
          'email': email,
        });

        return otpResponse;
      }

      return null;
    } catch (e) {
      print('Error verifying email OTP: $e');
      throw Exception(_getOTPVerificationErrorMessage(e));
    }
  }

  // إعادة إرسال رمز التحقق
  Future<bool> resendEmailOTP(String email) async {
    try {
      await client.auth.resend(
        type: OtpType.email,
        email: email,
      );
      return true;
    } catch (e) {
      print('Error resending email OTP: $e');
      throw Exception(_getOTPResendErrorMessage(e));
    }
  }

  // ===== دوال معالجة رسائل أخطاء OTP =====

  String _getOTPErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('rate limit') ||
        errorString.contains('too many')) {
      return 'تم تجاوز الحد المسموح لإرسال رموز التحقق. يرجى المحاولة بعد ساعة.';
    } else if (errorString.contains('invalid email') ||
        errorString.contains('email')) {
      return 'البريد الإلكتروني غير صحيح. يرجى التحقق من البريد المدخل.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'خطأ في الخادم. يرجى المحاولة بعد قليل.';
    } else {
      return 'حدث خطأ في إرسال رمز التحقق. يرجى المحاولة مرة أخرى.';
    }
  }

  String _getOTPVerificationErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid') || errorString.contains('wrong')) {
      return 'رمز التحقق غير صحيح. يرجى التحقق من الرمز والمحاولة مرة أخرى.';
    } else if (errorString.contains('expired') ||
        errorString.contains('expire')) {
      return 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.';
    } else if (errorString.contains('rate limit') ||
        errorString.contains('too many')) {
      return 'تم تجاوز عدد المحاولات المسموح. يرجى طلب رمز جديد.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
    } else {
      return 'فشل في التحقق من الرمز. يرجى المحاولة مرة أخرى أو طلب رمز جديد.';
    }
  }

  String _getOTPResendErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('rate limit') ||
        errorString.contains('too many')) {
      return 'تم تجاوز الحد المسموح لإعادة الإرسال. يرجى الانتظار قبل طلب رمز جديد.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
    } else {
      return 'فشل في إعادة إرسال رمز التحقق. يرجى المحاولة بعد قليل.';
    }
  }

  Future<AuthResponse?> signUp(
    String email,
    String password, {
    String? fullName,
    String? location,
    String? phoneNumber,
    String? countryCode,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
          'location': location ?? '',
          'phone_number': phoneNumber ?? '',
          'country_code': countryCode ?? '+967',
        },
      );

      return response;
    } catch (e) {
      print('Error signing up: $e');
      throw Exception('خطأ في إنشاء الحساب: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('خطأ في تسجيل الخروج: ${e.toString()}');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      throw Exception('خطأ في إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // التحقق من كلمة المرور الحالية عن طريق محاولة تسجيل الدخول
      try {
        await client.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (e) {
        throw Exception('كلمة المرور الحالية غير صحيحة');
      }

      // تغيير كلمة المرور
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return true;
    } catch (e) {
      print('Error changing password: $e');
      throw Exception('خطأ في تغيير كلمة المرور: ${e.toString()}');
    }
  }

  // User Settings Methods
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      final response = await client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }

  Future<bool> createUserSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      // التأكد من وجود جميع الحقول المطلوبة مع القيم الافتراضية
      final defaultSettings = {
        'user_id': userId,
        'theme_mode': 'light',
        'language': 'ar',
        'notifications_enabled': true,
        'sound_enabled': true,
        'vibration_enabled': true,
        'auto_backup': true,
        'backup_frequency': 'daily',
        'location_enabled': true,
        'temperature_unit': 'celsius',
        'date_format': 'dd/MM/yyyy',
        'timezone': 'Asia/Riyadh',
        'plant_care_notifications': true,
        'market_notifications': true,
        'system_notifications': true,
        'show_personal_info': true,
        'share_location': false,
        'profile_visibility': true,
      };

      // دمج الإعدادات المرسلة مع الافتراضية
      final finalSettings = {...defaultSettings, ...settings};

      await client.from('user_settings').insert(finalSettings);
      return true;
    } catch (e) {
      print('Error creating user settings: $e');
      return false;
    }
  }

  Future<bool> updateUserSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      // التأكد من تحديث الوقت
      final updatedSettings = {
        ...settings,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client
          .from('user_settings')
          .update(updatedSettings)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error updating user settings: $e');
      return false;
    }
  }

  Future<bool> deleteUserSettings(String userId) async {
    try {
      await client.from('user_settings').delete().eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error deleting user settings: $e');
      return false;
    }
  }

  // User Profile Methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('profiles').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> createUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await client.from('profiles').insert({
        'id': userId,
        'full_name': data['full_name'] ?? '',
        'location': data['location'] ?? '',
        'phone_number': data['phone_number'] ?? '',
        'country_code': data['country_code'] ?? '+967',
        'email': data['email'] ?? '',
      });
      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await client.from('profiles').update(data).eq('id', userId);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // ESP32/Device Verification Methods
  Future<Map<String, dynamic>?> verifyDeviceSerial(String deviceSerial) async {
    try {
      final response = await client
          .from('irrigation_systems')
          .select(
              'id, user_id, name, crop_type, profiles!inner(full_name, email)')
          .eq('device_serial', deviceSerial)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error verifying device serial: $e');
      return null;
    }
  }

  Future<bool> linkDeviceToUser(
      String userId, String deviceSerial, String systemName) async {
    try {
      // التحقق من وجود الجهاز أولاً
      final existingDevice = await client
          .from('irrigation_systems')
          .select('id, user_id')
          .eq('device_serial', deviceSerial)
          .maybeSingle();

      if (existingDevice != null) {
        if (existingDevice['user_id'] != null &&
            existingDevice['user_id'] != userId) {
          throw Exception('هذا الجهاز مرتبط بمستخدم آخر');
        }

        // ربط الجهاز بالمستخدم
        await client.from('irrigation_systems').update({
          'user_id': userId,
          'name': systemName,
        }).eq('device_serial', deviceSerial);
      } else {
        throw Exception('رقم الجهاز غير موجود في النظام');
      }

      return true;
    } catch (e) {
      print('Error linking device to user: $e');
      throw Exception(e.toString());
    }
  }

  // Home Dashboard Methods
  Future<Map<String, dynamic>> getHomeDashboardData(String userId) async {
    try {
      // Get irrigation systems count
      final systemsResponse = await client
          .from('irrigation_systems')
          .select('id, is_active')
          .eq('user_id', userId);

      final activeSystems =
          systemsResponse.where((system) => system['is_active'] == true).length;

      // Get latest sensor data for all systems
      List<Map<String, dynamic>> latestSensorData = [];
      if (systemsResponse.isNotEmpty) {
        final systemIds = systemsResponse.map((s) => s['id']).toList();

        for (String systemId in systemIds) {
          final sensorData = await getSensorData(systemId, limit: 1);
          if (sensorData.isNotEmpty) {
            latestSensorData.add(sensorData.first);
          }
        }
      }

      // Get recent alerts/notifications
      final alertsResponse = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(5);

      // Get recent irrigation logs
      final recentIrrigationResponse = await client
          .from('irrigation_logs')
          .select('*, irrigation_systems!inner(user_id)')
          .eq('irrigation_systems.user_id', userId)
          .order('start_time', ascending: false)
          .limit(1);

      return {
        'active_systems': activeSystems,
        'total_systems': systemsResponse.length,
        'sensor_data': latestSensorData,
        'alerts': alertsResponse ?? [],
        'last_irrigation': recentIrrigationResponse.isNotEmpty
            ? recentIrrigationResponse.first
            : null,
      };
    } catch (e) {
      print('Error getting home dashboard data: $e');
      return {
        'active_systems': 0,
        'total_systems': 0,
        'sensor_data': [],
        'alerts': [],
        'last_irrigation': null,
      };
    }
  }

  // Irrigation Systems Methods
  Future<List<Map<String, dynamic>>> getIrrigationSystems(String userId) async {
    try {
      final response = await client
          .from('irrigation_systems')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting irrigation systems: $e');
      return [];
    }
  }

  Future<bool> addIrrigationSystem(Map<String, dynamic> systemData) async {
    try {
      await client.from('irrigation_systems').insert(systemData);
      return true;
    } catch (e) {
      print('Error adding irrigation system: $e');
      throw Exception('خطأ في إضافة النظام: ${e.toString()}');
    }
  }

  Future<bool> updateIrrigationSystem(
      String systemId, Map<String, dynamic> data) async {
    try {
      await client.from('irrigation_systems').update(data).eq('id', systemId);
      return true;
    } catch (e) {
      print('Error updating irrigation system: $e');
      throw Exception('خطأ في تحديث النظام: ${e.toString()}');
    }
  }

  Future<bool> deleteIrrigationSystem(String systemId) async {
    try {
      await client.from('irrigation_systems').delete().eq('id', systemId);
      return true;
    } catch (e) {
      print('Error deleting irrigation system: $e');
      throw Exception('خطأ في حذف النظام: ${e.toString()}');
    }
  }

  Future<bool> toggleIrrigationSystem(String systemId, bool isActive) async {
    try {
      await client
          .from('irrigation_systems')
          .update({'is_active': isActive}).eq('id', systemId);
      return true;
    } catch (e) {
      print('Error toggling irrigation system: $e');
      throw Exception('خطأ في تغيير حالة النظام: ${e.toString()}');
    }
  }

  Future<bool> startManualIrrigation(String systemId, {String? notes}) async {
    try {
      // Get current sensor data
      final sensorData = await getSensorData(systemId, limit: 1);
      final currentMoisture =
          sensorData.isNotEmpty ? sensorData.first['soil_moisture'] : null;

      // Create irrigation log
      await client.from('irrigation_logs').insert({
        'system_id': systemId,
        'type': 'manual',
        'start_time': DateTime.now().toIso8601String(),
        'soil_moisture_before': currentMoisture,
        'triggered_by': 'user',
        'notes': notes ?? '',
      });

      return true;
    } catch (e) {
      print('Error starting manual irrigation: $e');
      throw Exception('خطأ في بدء الري اليدوي: ${e.toString()}');
    }
  }

  Future<bool> stopIrrigation(String systemId, String logId) async {
    try {
      // Get current sensor data
      final sensorData = await getSensorData(systemId, limit: 1);
      final currentMoisture =
          sensorData.isNotEmpty ? sensorData.first['soil_moisture'] : null;

      // Update irrigation log
      final endTime = DateTime.now();
      await client.from('irrigation_logs').update({
        'end_time': endTime.toIso8601String(),
        'soil_moisture_after': currentMoisture,
      }).eq('id', logId);

      return true;
    } catch (e) {
      print('Error stopping irrigation: $e');
      throw Exception('خطأ في إيقاف الري: ${e.toString()}');
    }
  }

  // Sensor Data Methods
  Future<List<Map<String, dynamic>>> getSensorData(
    String systemId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query =
          client.from('sensor_data').select('*').eq('system_id', systemId);

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      var orderedQuery = query.order('timestamp', ascending: false);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting sensor data: $e');
      return [];
    }
  }

  Future<bool> addSensorData(Map<String, dynamic> sensorData) async {
    try {
      await client.from('sensor_data').insert(sensorData);
      return true;
    } catch (e) {
      print('Error adding sensor data: $e');
      return false;
    }
  }

  // Irrigation Logs Methods
  Future<List<Map<String, dynamic>>> getIrrigationLogs(
    String systemId, {
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
  }) async {
    try {
      var query =
          client.from('irrigation_logs').select('*').eq('system_id', systemId);

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }
      if (type != null) {
        query = query.eq('type', type);
      }

      var orderedQuery = query.order('start_time', ascending: false);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting irrigation logs: $e');
      return [];
    }
  }

  // Plant Disease Methods - محسن للعمل مع قاعدة البيانات الجديدة
  Future<List<Map<String, dynamic>>> getPlantDiseases() async {
    try {
      final response = await client
          .from('plant_diseases')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting plant diseases: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlantDiseaseByName(
      String diseaseName) async {
    try {
      final response = await client
          .from('plant_diseases')
          .select('*')
          .eq('name', diseaseName)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting plant disease by name: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPlantDiseaseByEnglishName(
      String englishName) async {
    try {
      // تنظيف اسم المرض من الرقم في البداية
      String cleanName = englishName;
      if (cleanName.contains(' ')) {
        final parts = cleanName.split(' ');
        if (parts.isNotEmpty && RegExp(r'^\d+$').hasMatch(parts[0])) {
          cleanName = parts.skip(1).join(' ');
        }
      }

      print('🔍 البحث عن المرض بالاسم الإنجليزي: "$cleanName"');

      final response = await client
          .from('plant_diseases')
          .select('*')
          .eq('english_name', cleanName)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        print('✅ تم العثور على المرض: ${response['name']}');
      } else {
        print('❌ لم يتم العثور على المرض: $cleanName');
      }

      return response;
    } catch (e) {
      print('Error getting plant disease by English name: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPlantDiseasesByType(
      String plantType) async {
    try {
      final response = await client
          .from('plant_diseases')
          .select('*')
          .eq('plant_type', plantType)
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting plant diseases by type: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDiseaseSymptoms(
      String diseaseId) async {
    try {
      final response = await client
          .from('disease_symptoms')
          .select('*')
          .eq('disease_id', diseaseId)
          .order('severity_level', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting disease symptoms: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDiseaseTreatments(
      String diseaseId) async {
    try {
      final response = await client
          .from('disease_treatments')
          .select('*')
          .eq('disease_id', diseaseId)
          .order('effectiveness_rating', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting disease treatments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDiseasePrevention(
      String diseaseId) async {
    try {
      final response = await client
          .from('disease_prevention')
          .select('*')
          .eq('disease_id', diseaseId)
          .order('effectiveness_rating', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting disease prevention: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCompleteDiseaseInfo(
      String englishName) async {
    try {
      // Get disease basic info
      final disease = await getPlantDiseaseByEnglishName(englishName);
      if (disease == null) return null;

      // Get symptoms, treatments, and prevention
      final symptoms = await getDiseaseSymptoms(disease['id']);
      final treatments = await getDiseaseTreatments(disease['id']);
      final prevention = await getDiseasePrevention(disease['id']);

      return {
        'disease': disease,
        'symptoms': symptoms,
        'treatments': treatments,
        'prevention': prevention,
      };
    } catch (e) {
      print('Error getting complete disease info: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchDiseases(String searchTerm) async {
    try {
      final response = await client
          .from('plant_diseases')
          .select('*')
          .or('name.ilike.%$searchTerm%,english_name.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching diseases: $e');
      return [];
    }
  }

  // إضافة بيانات مرض جديد - للاستخدام من قبل المطورين
  Future<bool> addDiseaseData({
    required String diseaseName,
    required String englishName,
    required String plantType,
    required String description,
    required List<String> symptoms,
    List<Map<String, dynamic>>? treatments,
    List<Map<String, dynamic>>? preventionMethods,
    int severityLevel = 1,
  }) async {
    try {
      // إضافة المرض الأساسي
      final diseaseResponse = await client
          .from('plant_diseases')
          .insert({
            'name': diseaseName,
            'english_name': englishName,
            'plant_type': plantType,
            'description': description,
            'symptoms': symptoms,
            'severity_level': severityLevel,
            'is_active': true,
          })
          .select()
          .single();

      final diseaseId = diseaseResponse['id'];

      // إضافة الأعراض التفصيلية
      if (symptoms.isNotEmpty) {
        final symptomsList = symptoms
            .map((symptom) => {
                  'disease_id': diseaseId,
                  'symptom_name': symptom,
                  'description': symptom,
                  'severity_level': severityLevel,
                })
            .toList();

        await client.from('disease_symptoms').insert(symptomsList);
      }

      // إضافة العلاجات
      if (treatments != null && treatments.isNotEmpty) {
        final treatmentsList = treatments
            .map((treatment) => {
                  'disease_id': diseaseId,
                  'treatment_name': treatment['name'] ?? '',
                  'treatment_type': treatment['type'] ?? 'chemical',
                  'description': treatment['description'] ?? '',
                  'application_method': treatment['application_method'] ?? '',
                  'effectiveness_rating':
                      treatment['effectiveness_rating'] ?? 0.5,
                })
            .toList();

        await client.from('disease_treatments').insert(treatmentsList);
      }

      // إضافة طرق الوقاية
      if (preventionMethods != null && preventionMethods.isNotEmpty) {
        final preventionList = preventionMethods
            .map((prevention) => {
                  'disease_id': diseaseId,
                  'prevention_method': prevention['method'] ?? '',
                  'method_type': prevention['type'] ?? 'cultural',
                  'description': prevention['description'] ?? '',
                  'effectiveness_rating':
                      prevention['effectiveness_rating'] ?? 0.5,
                })
            .toList();

        await client.from('disease_prevention').insert(preventionList);
      }

      return true;
    } catch (e) {
      print('Error adding disease data: $e');
      return false;
    }
  }

  // دالة للحصول على قائمة النماذج المتاحة
  Future<List<String>> getAvailableModelLabels() async {
    try {
      final diseases = await getPlantDiseases();
      return diseases
          .map((disease) => disease['english_name'] as String)
          .toList();
    } catch (e) {
      print('Error getting model labels: $e');
      return [];
    }
  }

  // دالة للتحقق من أمان المستخدم
  bool _isValidUser() {
    final user = currentUser;
    if (user == null) {
      print('🚨 خطأ أمني: لا يوجد مستخدم مسجل دخول');
      return false;
    }
    print('🔒 تحقق من المستخدم: ${user.id}');
    return true;
  }

  String? _getCurrentUserId() {
    final user = currentUser;
    return user?.id;
  }

  // Disease Detection Methods - تحديث للجدول الجديد
  Future<List<Map<String, dynamic>>> getUserDiagnoses() async {
    try {
      final currentUser = this.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول لجلب التشخيصات');
        return [];
      }

      print('📋 جلب التشخيصات للمستخدم: ${currentUser.id}');

      final response = await client
          .from('disease_detections')
          .select('''
            id,
            image_path,
            plant_type,
            disease_name,
            confidence,
            status,
            detection_date,
            notes,
            location,
            plant_diseases(
              id,
              name,
              english_name,
              description,
              symptoms,
              severity_level
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('detection_date', ascending: false);

      final diagnoses = List<Map<String, dynamic>>.from(response ?? []);
      print('📊 تم جلب ${diagnoses.length} تشخيص');

      return diagnoses;
    } catch (e) {
      print('❌ خطأ في جلب التشخيصات: $e');
      return [];
    }
  }

  Future<bool> deleteAllUserDiagnoses() async {
    try {
      final currentUser = this.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return false;
      }

      final userId = currentUser.id;
      print('🗑️ بدء حذف جميع التشخيصات للمستخدم: $userId');
      print('🔒 التأكد من الأمان: سيتم حذف التشخيصات للمستخدم $userId فقط');

      // أولاً، تحقق من عدد السجلات الموجودة للمستخدم الحالي فقط
      final countResponse = await client
          .from('disease_detections')
          .select('id, user_id')
          .eq('user_id', userId);

      final recordCount = countResponse.length;
      print('📊 عدد السجلات المراد حذفها للمستخدم $userId: $recordCount');

      // التحقق من أن جميع السجلات تخص المستخدم الحالي
      final invalidRecords =
          countResponse.where((record) => record['user_id'] != userId).toList();
      if (invalidRecords.isNotEmpty) {
        print('🚨 خطأ أمني: وجدت سجلات لا تخص المستخدم الحالي!');
        return false;
      }

      if (recordCount == 0) {
        print('ℹ️ لا توجد سجلات للحذف للمستخدم $userId');
        return true;
      }

      // حذف السجلات مع التأكيد على user_id (طبقة حماية إضافية)
      print('🔄 تنفيذ عملية الحذف...');
// حذف للمستخدم الحالي فقط

      // التحقق من أن الحذف تم بنجاح
      final remainingResponse = await client
          .from('disease_detections')
          .select('id')
          .eq('user_id', userId);

      final remainingCount = remainingResponse.length;

      if (remainingCount == 0) {
        print('✅ تم حذف جميع السجلات ($recordCount) للمستخدم $userId بنجاح');
        print('🔒 تأكيد الأمان: تم حذف سجلات المستخدم $userId فقط');
        return true;
      } else {
        print(
            '⚠️ لم يتم حذف جميع السجلات. متبقي: $remainingCount من أصل $recordCount للمستخدم $userId');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في حذف جميع التشخيصات: $e');
      return false;
    }
  }

  Future<bool> deleteDiagnosis(String diagnosisId) async {
    try {
      final currentUser = this.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return false;
      }

      final userId = currentUser.id;
      print('🗑️ حذف التشخيص: $diagnosisId للمستخدم: $userId');

      // أولاً، تحقق من أن التشخيص يخص المستخدم الحالي
      final checkResponse = await client
          .from('disease_detections')
          .select('id, user_id')
          .eq('id', diagnosisId)
          .maybeSingle();

      if (checkResponse == null) {
        print('❌ التشخيص غير موجود: $diagnosisId');
        return false;
      }

      if (checkResponse['user_id'] != userId) {
        print('🚨 خطأ أمني: التشخيص $diagnosisId لا يخص المستخدم $userId');
        return false;
      }

      print('🔒 تأكيد الأمان: التشخيص $diagnosisId يخص المستخدم $userId');

      // حذف التشخيص مع التأكيد على user_id (طبقة حماية إضافية)
      await client
          .from('disease_detections')
          .delete()
          .eq('id', diagnosisId)
          .eq('user_id', userId); // طبقة حماية إضافية

      print('✅ تم حذف التشخيص $diagnosisId للمستخدم $userId بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في حذف التشخيص: $e');
      return false;
    }
  }

  Future<bool> saveDiagnosis(Map<String, dynamic> diagnosisData) async {
    try {
      final currentUser = this.currentUser;
      if (currentUser == null) return false;

      // رفع الصورة أولاً
      String? imageUrl;
      if (diagnosisData['image_file'] != null) {
        final file = diagnosisData['image_file'] as File;
        final fileName = 'disease-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${currentUser.id}/$fileName';
        imageUrl = await uploadFile('diseaseimages', path, file);
      }

      // البحث عن disease_id من اسم المرض
      String? diseaseId;
      try {
        // تنظيف اسم المرض من الرقم في البداية
        String cleanDiseaseName = diagnosisData['predicted_disease'];
        if (cleanDiseaseName.contains(' ')) {
          // إزالة الرقم من البداية إذا وجد (مثل "3 Tomato Late blight" -> "Tomato Late blight")
          final parts = cleanDiseaseName.split(' ');
          if (parts.isNotEmpty && RegExp(r'^\d+$').hasMatch(parts[0])) {
            cleanDiseaseName = parts.skip(1).join(' ');
          }
        }

        print('🔍 البحث عن المرض: "$cleanDiseaseName"');

        final diseaseResponse = await client
            .from('plant_diseases')
            .select('id')
            .eq('english_name', cleanDiseaseName)
            .single();
        diseaseId = diseaseResponse['id'];
        print('✅ تم العثور على معرف المرض: $diseaseId');
      } catch (e) {
        print(
            '❌ لم يتم العثور على معرف المرض: ${diagnosisData['predicted_disease']}');
        print(
            '   اسم المرض المنظف: ${diagnosisData['predicted_disease'].split(' ').skip(1).join(' ')}');
      }

      // حفظ بيانات التشخيص
      await client.from('disease_detections').insert({
        'user_id': currentUser.id,
        'image_path': imageUrl ?? '',
        'plant_type': diagnosisData['plant_type'],
        'disease_name': diagnosisData['predicted_disease'],
        'disease_id': diseaseId,
        'confidence': diagnosisData['confidence_score'],
        'status': 'new',
        'detection_date': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving diagnosis: $e');
      return false;
    }
  }

  Future<bool> updateDiagnosisStatus(String diagnosisId, String status) async {
    try {
      await client
          .from('disease_detections')
          .update({'status': status}).eq('id', diagnosisId);
      return true;
    } catch (e) {
      print('Error updating diagnosis status: $e');
      return false;
    }
  }

  // Market Products Methods - دوال السوق المحسنة
  Future<List<Map<String, dynamic>>> getMarketProducts({
    String? category,
    String? location,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from('products').select('''
            id,
            name,
            price,
            description,
            category,
            image_urls,
            is_active,
            created_at,
            user_id,
            location,
            profiles!inner(
              id,
              full_name,
              avatar_url,
              location,
              phone_number
            )
          ''');

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (location != null && location.isNotEmpty) {
        query = query.eq('location', location);
      }

      query = query.eq('is_active', true);

      var orderedQuery = query.order('created_at', ascending: false);

      if (limit != null && offset != null) {
        orderedQuery = orderedQuery.range(offset, offset + limit - 1);
      } else if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting market products: $e');
      return [];
    }
  }

  /// البحث المتقدم في المنتجات مع دعم الفلترة المتعددة
  Future<List<Map<String, dynamic>>> searchProducts({
    required String searchTerm,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy = 'created_at',
    bool ascending = false,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from('products').select('''
            id,
            name,
            price,
            description,
            category,
            image_urls,
            is_active,
            created_at,
            user_id,
            location,
            profiles!inner(
              id,
              full_name,
              avatar_url,
              location,
              phone_number
            )
          ''');

      // البحث النصي المحسن في الاسم والوصف والتصنيف
      if (searchTerm.isNotEmpty) {
        query = query.or(
            'name.ilike.%$searchTerm%,description.ilike.%$searchTerm%,category.ilike.%$searchTerm%');
      }

      // فلترة حسب التصنيف
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // فلترة حسب الموقع
      if (location != null && location.isNotEmpty) {
        query = query.eq('location', location);
      }

      // فلترة حسب السعر
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // المنتجات النشطة فقط
      query = query.eq('is_active', true);

      // ترتيب النتائج
      var orderedQuery =
          query.order(sortBy ?? 'created_at', ascending: ascending);

      // تطبيق التصفح (pagination)
      if (limit != null && offset != null) {
        orderedQuery = orderedQuery.range(offset, offset + limit - 1);
      } else if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في البحث عن المنتجات: $e');
      return [];
    }
  }

  // الحصول على المنتجات حسب التصنيف
  Future<List<Map<String, dynamic>>> getProductsByCategory({
    required String category,
    int? limit,
    int? offset,
  }) async {
    try {
      return await getMarketProducts(
        category: category,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  // الحصول على المنتجات حسب الموقع
  Future<List<Map<String, dynamic>>> getProductsByLocation({
    required String location,
    int? limit,
    int? offset,
  }) async {
    try {
      return await getMarketProducts(
        location: location,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('Error getting products by location: $e');
      return [];
    }
  }

  // الحصول على المنتجات حسب نطاق السعر
  Future<List<Map<String, dynamic>>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
    String? category,
    String? location,
    int? limit,
    int? offset,
  }) async {
    try {
      return await searchProducts(
        searchTerm: '',
        category: category,
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('Error getting products by price range: $e');
      return [];
    }
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      await client.from('products').insert(productData);
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      await client.from('products').update(data).eq('id', productId);
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await client.from('products').delete().eq('id', productId);
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  Future<bool> toggleProductLike(String productId, String userId) async {
    try {
      final existingLike = await client
          .from('product_likes')
          .select()
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        await client
            .from('product_likes')
            .delete()
            .eq('product_id', productId)
            .eq('user_id', userId);
      } else {
        await client.from('product_likes').insert({
          'product_id': productId,
          'user_id': userId,
        });
      }
      return true;
    } catch (e) {
      print('Error toggling product like: $e');
      return false;
    }
  }

  Future<int> getProductLikesCount(String productId) async {
    try {
      final response = await client
          .from('product_likes')
          .select('id')
          .eq('product_id', productId);
      return response.length;
    } catch (e) {
      print('Error getting product likes count: $e');
      return 0;
    }
  }

  Future<bool> isProductLiked(String productId, String userId) async {
    try {
      final response = await client
          .from('product_likes')
          .select()
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking if product is liked: $e');
      return false;
    }
  }

  // Chat Methods
  Future<List<Map<String, dynamic>>> getChatConversations(String userId) async {
    try {
      final response = await client
          .from('conversations')
          .select('''
            *,
            participant1:profiles!conversations_participant1_id_fkey(full_name, avatar_url),
            participant2:profiles!conversations_participant2_id_fkey(full_name, avatar_url)
          ''')
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('updated_at', ascending: false);

      for (var conversation in response) {
        final lastMessage = await getLastMessage(conversation['id']);
        conversation['last_message'] = lastMessage;

        final unreadCount =
            await getUnreadMessagesCount(conversation['id'], userId);
        conversation['unread_count'] = unreadCount;
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting chat conversations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLastMessage(String conversationId) async {
    try {
      final response = await client
          .from('messages')
          .select('content, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting last message: $e');
      return null;
    }
  }

  Future<int> getUnreadMessagesCount(
      String conversationId, String userId) async {
    try {
      final response = await client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('is_read', false)
          .neq('sender_id', userId);
      return response.length;
    } catch (e) {
      print('Error getting unread messages count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(
      String conversationId) async {
    try {
      // التحقق من الاتصال أولاً
      if (!await _checkConnection()) {
        print('No internet connection for getting chat messages');
        return [];
      }

      final response = await client
          .from('messages')
          .select('''
            *,
            sender:profiles(full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting chat messages: $e');
      // في حالة فشل الاتصال، إرجاع قائمة فارغة بدلاً من خطأ
      return [];
    }
  }

  // دالة للتحقق من الاتصال
  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> messageData) async {
    try {
      await client.from('messages').insert(messageData);

      await client
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()}).eq(
              'id', messageData['conversation_id']);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // دالة إرسال مؤشر الكتابة
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      final currentUser = this.currentUser;
      if (currentUser == null) return;

      // للبساطة، سنستخدم real-time channel لإرسال مؤشر الكتابة
      final channel = client.channel('typing_$conversationId');

      // استخدام الطريقة الصحيحة لإرسال البيانات
      channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': currentUser.id,
          'is_typing': isTyping,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  Future<String?> createConversation(
      String participant1Id, String participant2Id) async {
    try {
      final existingConversation = await client
          .from('conversations')
          .select()
          .or('and(participant1_id.eq.$participant1Id,participant2_id.eq.$participant2Id),and(participant1_id.eq.$participant2Id,participant2_id.eq.$participant1Id)')
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation['id'];
      }

      final response = await client
          .from('conversations')
          .insert({
            'participant1_id': participant1Id,
            'participant2_id': participant2Id,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  Future<bool> markMessagesAsRead(String conversationId, String userId) async {
    try {
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
      return true;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  // Notifications Methods
  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    bool? isRead,
    int? limit,
  }) async {
    try {
      var query =
          client.from('notifications').select('*').eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (limit != null) {
        final response =
            await query.order('created_at', ascending: false).limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final response = await query.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<bool> addNotification(Map<String, dynamic> notificationData) async {
    try {
      await client.from('notifications').insert(notificationData);
      return true;
    } catch (e) {
      print('Error adding notification: $e');
      return false;
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true}).eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // File Upload Methods
  Future<String?> uploadFile(String bucket, String path, File file) async {
    try {
      final bytes = await file.readAsBytes();
      await client.storage.from(bucket).uploadBinary(path, bytes);

      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // حذف ملف من التخزين
  Future<bool> deleteFile(String bucket, String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // استخراج مسار الملف من URL
  String? extractFilePathFromUrl(String? url, String bucket) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // البحث عن مؤشر bucket في المسار
      final bucketIndex = pathSegments.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        // إرجاع المسار بعد اسم bucket
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }

      return null;
    } catch (e) {
      print('Error extracting file path from URL: $e');
      return null;
    }
  }

  // File Upload for Web (using Uint8List)
  Future<String?> uploadFileWeb(
      String bucket, String path, Uint8List bytes) async {
    try {
      await client.storage.from(bucket).uploadBinary(path, bytes);

      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // رفع صورة المنتج
  Future<String?> uploadProductImage(File file, String productId) async {
    try {
      final fileName =
          'product-$productId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${currentUser?.id}/$fileName';
      return await uploadFile('productimages', path, file);
    } catch (e) {
      print('Error uploading product image: $e');
      return null;
    }
  }

  // رفع صورة البروفايل مع حذف الصورة القديمة
  Future<String?> uploadProfileAvatar(File file, {String? oldAvatarUrl}) async {
    try {
      // حذف الصورة القديمة إذا كانت موجودة
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        final oldPath = extractFilePathFromUrl(oldAvatarUrl, 'avatars');
        if (oldPath != null) {
          await deleteFile('avatars', oldPath);
        }
      }

      final fileName = 'avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${currentUser?.id}/$fileName';
      return await uploadFile('avatars', path, file);
    } catch (e) {
      print('Error uploading profile avatar: $e');
      return null;
    }
  }

  // رفع صورة البروفايل للويب مع حذف الصورة القديمة
  Future<String?> uploadProfileAvatarWeb(Uint8List bytes,
      {String? oldAvatarUrl}) async {
    try {
      // حذف الصورة القديمة إذا كانت موجودة
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        final oldPath = extractFilePathFromUrl(oldAvatarUrl, 'avatars');
        if (oldPath != null) {
          await deleteFile('avatars', oldPath);
        }
      }

      final fileName = 'avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${currentUser?.id}/$fileName';
      return await uploadFileWeb('avatars', path, bytes);
    } catch (e) {
      print('Error uploading profile avatar for web: $e');
      return null;
    }
  }

  // رفع مرفق الدردشة
  Future<String?> uploadChatAttachment(File file, String conversationId) async {
    try {
      final extension = file.path.split('.').last;
      final fileName =
          'chat-$conversationId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '${currentUser?.id}/$fileName';
      return await uploadFile('chatattachments', path, file);
    } catch (e) {
      print('Error uploading chat attachment: $e');
      return null;
    }
  }

  // رفع صور متعددة للمنتج
  Future<List<String>> uploadMultipleProductImages(
      List<File> files, String productId) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final fileName =
            'product-$productId-$i-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${currentUser?.id}/$fileName';
        final url = await uploadFile('productimages', path, files[i]);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        print('Error uploading product image $i: $e');
      }
    }

    return uploadedUrls;
  }

  // حذف صورة من bucket معين
  Future<bool> deleteImageFromBucket(String bucket, String imageUrl) async {
    try {
      // استخراج المسار من الـ URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(bucket);

      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        return await deleteFile(bucket, filePath);
      }

      return false;
    } catch (e) {
      print('Error deleting image from bucket: $e');
      return false;
    }
  }

  // System Settings Methods
  Future<Map<String, dynamic>?> getSystemSettings(String systemId) async {
    try {
      final response = await client
          .from('system_settings')
          .select('*')
          .eq('system_id', systemId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting system settings: $e');
      return null;
    }
  }

  Future<bool> updateSystemSettings(
      String systemId, Map<String, dynamic> settings) async {
    try {
      final existing = await getSystemSettings(systemId);

      if (existing != null) {
        await client
            .from('system_settings')
            .update(settings)
            .eq('system_id', systemId);
      } else {
        await client.from('system_settings').insert({
          'system_id': systemId,
          ...settings,
        });
      }

      return true;
    } catch (e) {
      print('Error updating system settings: $e');
      return false;
    }
  }

  /// Stream لبيانات الحساسات لنظام معين يحدث كل 5 ثواني
  Stream<List<Map<String, dynamic>>> sensorDataPollingStream(String systemId,
      {int limit = 1}) async* {
    while (true) {
      final data = await getSensorData(systemId, limit: limit);
      yield data;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Stream لبيانات جميع الأنظمة للمستخدم (لشاشة home)
  Stream<List<Map<String, dynamic>>> userLatestSensorsPollingStream(
      String userId) async* {
    while (true) {
      final systems = await getIrrigationSystems(userId);
      List<Map<String, dynamic>> latestSensorData = [];
      for (final sys in systems) {
        final data = await getSensorData(sys['id'], limit: 1);
        if (data.isNotEmpty) latestSensorData.add(data.first);
      }
      yield latestSensorData;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Helper method to safely get string values
  String? safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value?.toString();
  }

  // Helper method to safely get double values
  double? safeGetDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Helper method to safely get int values
  int? safeGetInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Helper method to safely get bool values
  bool safeGetBool(Map<String, dynamic> map, String key,
      {bool defaultValue = false}) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }
  // إضافة هذه الدوال إلى ملف supabaseservice.dart في نهاية الكلاس

  // Product Ratings Methods
  Future<bool> addProductRating(Map<String, dynamic> ratingData) async {
    try {
      // Check if user already rated this product
      final existingRating = await client
          .from('product_ratings')
          .select()
          .eq('product_id', ratingData['product_id'])
          .eq('user_id', ratingData['user_id'])
          .maybeSingle();

      if (existingRating != null) {
        // Update existing rating
        await client
            .from('product_ratings')
            .update({
              'rating': ratingData['rating'],
              'comment': ratingData['comment'],
            })
            .eq('product_id', ratingData['product_id'])
            .eq('user_id', ratingData['user_id']);
      } else {
        // Create new rating
        await client.from('product_ratings').insert(ratingData);
      }
      return true;
    } catch (e) {
      print('Error adding product rating: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getProductRatings(String productId) async {
    try {
      final response = await client
          .from('product_ratings')
          .select('''
            *,
            profiles(full_name, avatar_url)
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting product ratings: $e');
      return [];
    }
  }

  Future<double> getProductAverageRating(String productId) async {
    try {
      final response = await client
          .from('product_ratings')
          .select('rating')
          .eq('product_id', productId);

      if (response.isEmpty) return 0.0;

      final ratings =
          response.map((r) => (r['rating'] as num).toDouble()).toList();
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      print('Error getting product average rating: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>?> getUserProductRating(
      String productId, String userId) async {
    try {
      final response = await client
          .from('product_ratings')
          .select()
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user product rating: $e');
      return null;
    }
  }

  // Get detailed product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await client.from('products').select('''
            *,
            profiles!inner(
              id,
              full_name,
              avatar_url,
              location,
              phone_number
            )
          ''').eq('id', productId).maybeSingle();
      return response;
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }

  // Get user's own products
  Future<List<Map<String, dynamic>>> getUserProducts(String userId,
      {int? limit}) async {
    try {
      var query = client
          .from('products')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user products: $e');
      return [];
    }
  }

  /// الحصول على أفضل المنتجات تقييماً
  Future<List<Map<String, dynamic>>> getTopRatedProducts({int? limit}) async {
    try {
      // استعلام معقد للحصول على المنتجات مع متوسط التقييم
      final response = await client.rpc('get_top_rated_products', params: {
        'limit_count': limit ?? 10,
      });

      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }

      // في حالة عدم وجود الدالة المخزنة، استخدم طريقة بديلة
      return await _getTopRatedProductsFallback(limit: limit);
    } catch (e) {
      print('Error getting top rated products: $e');
      // استخدام الطريقة البديلة في حالة الخطأ
      return await _getTopRatedProductsFallback(limit: limit);
    }
  }

  /// طريقة بديلة للحصول على أفضل المنتجات تقييماً
  Future<List<Map<String, dynamic>>> _getTopRatedProductsFallback(
      {int? limit}) async {
    try {
      // الحصول على جميع المنتجات النشطة
      final products = await getMarketProducts(limit: limit ?? 20);

      // حساب متوسط التقييم لكل منتج
      List<Map<String, dynamic>> productsWithRatings = [];

      for (var product in products) {
        final averageRating = await getProductAverageRating(product['id']);
        final ratingsCount = await getProductRatings(product['id']);

        // إضافة المنتجات التي لها تقييمات فقط
        if (averageRating > 0) {
          product['average_rating'] = averageRating;
          product['ratings_count'] = ratingsCount.length;
          productsWithRatings.add(product);
        }
      }

      // ترتيب المنتجات حسب التقييم ثم عدد التقييمات
      productsWithRatings.sort((a, b) {
        final ratingA = a['average_rating'] as double;
        final ratingB = b['average_rating'] as double;
        final countA = a['ratings_count'] as int;
        final countB = b['ratings_count'] as int;

        // ترتيب حسب التقييم أولاً، ثم عدد التقييمات
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA);
        }
        return countB.compareTo(countA);
      });

      // إرجاع العدد المطلوب
      final limitCount = limit ?? 10;
      return productsWithRatings.take(limitCount).toList();
    } catch (e) {
      print('Error in fallback method for top rated products: $e');
      return [];
    }
  }

  // Start conversation from product
  Future<String?> startConversationFromProduct(
      String sellerId, String productId, String initialMessage) async {
    try {
      final currentUser = this.currentUser;
      if (currentUser == null) return null;

      // Create or get existing conversation
      final conversationId = await createConversation(currentUser.id, sellerId);

      if (conversationId != null) {
        // Send initial message with product reference
        final messageData = {
          'conversation_id': conversationId,
          'sender_id': currentUser.id,
          'content': initialMessage,
          'is_read': false,
          'message_type': 'product_inquiry',
        };

        await sendMessage(messageData);
        return conversationId;
      }
      return null;
    } catch (e) {
      print('Error starting conversation from product: $e');
      return null;
    }
  }

  // تفعيل أو تعطيل الري التلقائي
  Future<bool> setAutoIrrigation(String systemId, bool enabled) async {
    try {
      await client
          .from('irrigation_systems')
          .update({'auto_irrigation_enabled': enabled}).eq('id', systemId);
      return true;
    } catch (e) {
      print('Error setting auto irrigation: $e');
      return false;
    }
  }

  // تحديث إعدادات الري التلقائي (عتبات الحساسات)
  Future<bool> updateAutoIrrigationSettings(
    String systemId, {
    double? startThreshold,
    double? stopThreshold,
  }) async {
    try {
      final settings = <String, dynamic>{};
      if (startThreshold != null) settings['start_threshold'] = startThreshold;
      if (stopThreshold != null) settings['stop_threshold'] = stopThreshold;
      if (settings.isEmpty) return false;
      await updateSystemSettings(systemId, settings);
      return true;
    } catch (e) {
      print('Error updating auto irrigation settings: $e');
      return false;
    }
  }

  // تفعيل أو تعطيل الري الذكي
  Future<bool> setSmartIrrigation(
    String systemId, {
    required bool enabled,
    String? cropType,
    String? growthStage,
  }) async {
    try {
      final response = await client.from('irrigation_systems').update({
        'smart_irrigation_enabled': enabled,
        'auto_irrigation_enabled': false,
        'is_active': false,
        if (cropType != null) 'crop_type': cropType,
      }).eq('id', systemId);

      if (enabled && cropType != null && growthStage != null) {
        // حفظ إعدادات الري الذكي في جدول system_settings
        final growthStages = [
          'الإنبات',
          'النمو الخضري',
          'الإزهار/التزهير',
          'النضج'
        ];

        // استخدام updateSystemSettings بدلاً من upsert المباشر لتجنب مشكلة duplicate key
        await updateSystemSettings(systemId, {
          'plant_type_id': cropType,
          'growth_stage': growthStages.indexOf(growthStage),
          'auto_irrigation_enabled': false,
        });
      }

      return response.error == null;
    } catch (e) {
      print('Error setting smart irrigation: $e');
      return false;
    }
  }

  // دالة لمراقبة بيانات الحساسات واتخاذ قرار الري
  Stream<Map<String, dynamic>> monitorSmartIrrigation(String systemId) {
    return client
        .from('sensor_data')
        .stream(primaryKey: ['id'])
        .eq('system_id', systemId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  // ===== دوال إحصائيات السوق =====

  /// الحصول على إحصائيات المنتجات للمستخدم
  Future<Map<String, dynamic>> getProductStatistics(String userId) async {
    try {
      // عدد المنتجات النشطة
      final activeProductsResponse = await client
          .from('products')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      // إجمالي الإعجابات
      final likesResponse = await client
          .from('product_likes')
          .select('id')
          .eq('products.user_id', userId);

      // متوسط التقييم
      final ratingsResponse = await client
          .from('product_ratings')
          .select('rating')
          .eq('products.user_id', userId);

      double averageRating = 0.0;
      if (ratingsResponse.isNotEmpty) {
        final ratings = ratingsResponse
            .map((r) => (r['rating'] as num).toDouble())
            .toList();
        averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }

      return {
        'active_products': activeProductsResponse.length,
        'total_likes': likesResponse.length,
        'average_rating': averageRating,
        'total_ratings': ratingsResponse.length,
      };
    } catch (e) {
      print('Error getting product statistics: $e');
      return {
        'active_products': 0,
        'total_likes': 0,
        'average_rating': 0.0,
        'total_ratings': 0,
      };
    }
  }
}
