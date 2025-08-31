import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sam/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabaseservice.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Settings Models
class AppSettings extends Equatable {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoBackup;
  final String backupFrequency;
  final bool locationEnabled;
  final String temperatureUnit;
  final String dateFormat;

  // إعدادات الإشعارات المفصلة
  final bool plantCareNotifications;
  final bool marketNotifications;
  final bool systemNotifications;

  // إعدادات الخصوصية
  final bool showPersonalInfo;
  final bool shareLocation;
  final bool profileVisibility;

  const AppSettings({
    required this.isDarkMode,
    required this.language,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.autoBackup,
    required this.backupFrequency,
    required this.locationEnabled,
    required this.temperatureUnit,
    required this.dateFormat,
    required this.plantCareNotifications,
    required this.marketNotifications,
    required this.systemNotifications,
    required this.showPersonalInfo,
    required this.shareLocation,
    required this.profileVisibility,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      isDarkMode: false,
      language: 'ar',
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      autoBackup: true,
      backupFrequency: 'daily',
      locationEnabled: true,
      temperatureUnit: 'celsius',
      dateFormat: 'dd/MM/yyyy',
      plantCareNotifications: true,
      marketNotifications: true,
      systemNotifications: true,
      showPersonalInfo: true,
      shareLocation: false,
      profileVisibility: true,
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      language: map['language'] ?? 'ar',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      autoBackup: map['autoBackup'] ?? true,
      backupFrequency: map['backupFrequency'] ?? 'daily',
      locationEnabled: map['locationEnabled'] ?? true,
      temperatureUnit: map['temperatureUnit'] ?? 'celsius',
      dateFormat: map['dateFormat'] ?? 'dd/MM/yyyy',
      plantCareNotifications: map['plantCareNotifications'] ?? true,
      marketNotifications: map['marketNotifications'] ?? true,
      systemNotifications: map['systemNotifications'] ?? true,
      showPersonalInfo: map['showPersonalInfo'] ?? true,
      shareLocation: map['shareLocation'] ?? false,
      profileVisibility: map['profileVisibility'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency,
      'locationEnabled': locationEnabled,
      'temperatureUnit': temperatureUnit,
      'dateFormat': dateFormat,
      'plantCareNotifications': plantCareNotifications,
      'marketNotifications': marketNotifications,
      'systemNotifications': systemNotifications,
      'showPersonalInfo': showPersonalInfo,
      'shareLocation': shareLocation,
      'profileVisibility': profileVisibility,
    };
  }

  @override
  List<Object> get props => [
        isDarkMode,
        language,
        notificationsEnabled,
        soundEnabled,
        vibrationEnabled,
        autoBackup,
        backupFrequency,
        locationEnabled,
        temperatureUnit,
        dateFormat,
        plantCareNotifications,
        marketNotifications,
        systemNotifications,
        showPersonalInfo,
        shareLocation,
        profileVisibility,
      ];

  AppSettings copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoBackup,
    String? backupFrequency,
    bool? locationEnabled,
    String? temperatureUnit,
    String? dateFormat,
    bool? plantCareNotifications,
    bool? marketNotifications,
    bool? systemNotifications,
    bool? showPersonalInfo,
    bool? shareLocation,
    bool? profileVisibility,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      dateFormat: dateFormat ?? this.dateFormat,
      plantCareNotifications:
          plantCareNotifications ?? this.plantCareNotifications,
      marketNotifications: marketNotifications ?? this.marketNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      showPersonalInfo: showPersonalInfo ?? this.showPersonalInfo,
      shareLocation: shareLocation ?? this.shareLocation,
      profileVisibility: profileVisibility ?? this.profileVisibility,
    );
  }
}

// Settings Events
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateThemeEvent extends SettingsEvent {
  final bool isDarkMode;

  UpdateThemeEvent({required this.isDarkMode});

  @override
  List<Object> get props => [isDarkMode];
}

class UpdateLanguageEvent extends SettingsEvent {
  final String language;

  UpdateLanguageEvent({required this.language});

  @override
  List<Object> get props => [language];
}

class UpdateNotificationSettingsEvent extends SettingsEvent {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  UpdateNotificationSettingsEvent({
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  @override
  List<Object> get props =>
      [notificationsEnabled, soundEnabled, vibrationEnabled];
}

// أحداث الإشعارات المفصلة
class UpdatePlantCareNotificationsEvent extends SettingsEvent {
  final bool enabled;

  UpdatePlantCareNotificationsEvent({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdateMarketNotificationsEvent extends SettingsEvent {
  final bool enabled;

  UpdateMarketNotificationsEvent({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdateSystemNotificationsEvent extends SettingsEvent {
  final bool enabled;

  UpdateSystemNotificationsEvent({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

// أحداث الخصوصية
class UpdatePrivacySettingsEvent extends SettingsEvent {
  final bool? showPersonalInfo;
  final bool? shareLocation;
  final bool? profileVisibility;

  UpdatePrivacySettingsEvent({
    this.showPersonalInfo,
    this.shareLocation,
    this.profileVisibility,
  });

  @override
  List<Object?> get props =>
      [showPersonalInfo, shareLocation, profileVisibility];
}

class UpdateBackupSettingsEvent extends SettingsEvent {
  final bool autoBackup;
  final String backupFrequency;

  UpdateBackupSettingsEvent({
    required this.autoBackup,
    required this.backupFrequency,
  });

  @override
  List<Object> get props => [autoBackup, backupFrequency];
}

class UpdateLocationSettingEvent extends SettingsEvent {
  final bool locationEnabled;

  UpdateLocationSettingEvent({required this.locationEnabled});

  @override
  List<Object> get props => [locationEnabled];
}

class UpdateDisplaySettingsEvent extends SettingsEvent {
  final String temperatureUnit;
  final String dateFormat;

  UpdateDisplaySettingsEvent({
    required this.temperatureUnit,
    required this.dateFormat,
  });

  @override
  List<Object> get props => [temperatureUnit, dateFormat];
}

class ResetSettingsEvent extends SettingsEvent {}

class ExportDataEvent extends SettingsEvent {}

class ImportDataEvent extends SettingsEvent {}

class ClearCacheEvent extends SettingsEvent {}

class CheckAppUpdateEvent extends SettingsEvent {}

class ShareAppEvent extends SettingsEvent {}

class RateAppEvent extends SettingsEvent {}

class ContactSupportEvent extends SettingsEvent {}

// Settings States
abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  SettingsLoaded({required this.settings});

  @override
  List<Object> get props => [settings];

  SettingsLoaded copyWith({
    AppSettings? settings,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError({required this.message});

  @override
  List<Object> get props => [message];
}

class SettingsSuccess extends SettingsState {
  final String message;

  SettingsSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// Settings Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SupabaseService _supabaseService = SupabaseService();

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateThemeEvent>(_onUpdateTheme, transformer: _debounceTransformer());
    on<UpdateLanguageEvent>(_onUpdateLanguage,
        transformer: _debounceTransformer());
    on<UpdateNotificationSettingsEvent>(_onUpdateNotificationSettings,
        transformer: _debounceTransformer());
    on<UpdateBackupSettingsEvent>(_onUpdateBackupSettings,
        transformer: _debounceTransformer());
    on<UpdateLocationSettingEvent>(_onUpdateLocationSetting,
        transformer: _debounceTransformer());
    on<UpdateDisplaySettingsEvent>(_onUpdateDisplaySettings,
        transformer: _debounceTransformer());
    on<ResetSettingsEvent>(_onResetSettings);
    on<ExportDataEvent>(_onExportData);
    on<ImportDataEvent>(_onImportData);
    on<ClearCacheEvent>(_onClearCache);

    // معالجات الأحداث الجديدة
    on<UpdatePlantCareNotificationsEvent>(_onUpdatePlantCareNotifications,
        transformer: _debounceTransformer());
    on<UpdateMarketNotificationsEvent>(_onUpdateMarketNotifications,
        transformer: _debounceTransformer());
    on<UpdateSystemNotificationsEvent>(_onUpdateSystemNotifications,
        transformer: _debounceTransformer());
    on<UpdatePrivacySettingsEvent>(_onUpdatePrivacySettings,
        transformer: _debounceTransformer());

    // معالجات الأحداث الجديدة
    on<CheckAppUpdateEvent>(_onCheckAppUpdate);
    on<ShareAppEvent>(_onShareApp);
    on<RateAppEvent>(_onRateApp);
    on<ContactSupportEvent>(_onContactSupport);
  }

  // محول التأخير لمنع التحديثات السريعة المتتالية
  EventTransformer<T> _debounceTransformer<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 300))
        .asyncExpand(mapper);
  }

  Future<void> _onLoadSettings(
      LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // محاولة تحميل الإعدادات من Supabase أولاً
      final settingsData =
          await _supabaseService.getUserSettings(currentUser.id);

      Map<String, dynamic> settingsMap;
      if (settingsData != null) {
        // تحويل البيانات من قاعدة البيانات
        settingsMap = {
          'isDarkMode': settingsData['theme_mode'] == 'dark',
          'language': settingsData['language'] ?? 'ar',
          'notificationsEnabled': settingsData['notifications_enabled'] ?? true,
          'soundEnabled': settingsData['sound_enabled'] ?? true,
          'vibrationEnabled': settingsData['vibration_enabled'] ?? true,
          'autoBackup': settingsData['auto_backup'] ?? true,
          'backupFrequency': settingsData['backup_frequency'] ?? 'daily',
          'locationEnabled': settingsData['location_enabled'] ?? true,
          'temperatureUnit': settingsData['temperature_unit'] ?? 'celsius',
          'dateFormat': settingsData['date_format'] ?? 'dd/MM/yyyy',
          'plantCareNotifications':
              settingsData['plant_care_notifications'] ?? true,
          'marketNotifications': settingsData['market_notifications'] ?? true,
          'systemNotifications': settingsData['system_notifications'] ?? true,
          'showPersonalInfo': settingsData['show_personal_info'] ?? true,
          'shareLocation': settingsData['share_location'] ?? false,
          'profileVisibility': settingsData['profile_visibility'] ?? true,
        };
      } else {
        // إنشاء إعدادات افتراضية إذا لم توجد
        settingsMap = {
          'isDarkMode': false,
          'language': 'ar',
          'notificationsEnabled': true,
          'soundEnabled': true,
          'vibrationEnabled': true,
          'autoBackup': true,
          'backupFrequency': 'daily',
          'locationEnabled': true,
          'temperatureUnit': 'celsius',
          'dateFormat': 'dd/MM/yyyy',
          'plantCareNotifications': true,
          'marketNotifications': true,
          'systemNotifications': true,
          'showPersonalInfo': true,
          'shareLocation': false,
          'profileVisibility': true,
        };

        // حفظ الإعدادات الافتراضية في قاعدة البيانات
        await _supabaseService.createUserSettings(currentUser.id, {
          'theme_mode': settingsMap['isDarkMode'] ? 'dark' : 'light',
          'language': settingsMap['language'],
          'notifications_enabled': settingsMap['notificationsEnabled'],
          'sound_enabled': settingsMap['soundEnabled'],
          'vibration_enabled': settingsMap['vibrationEnabled'],
          'auto_backup': settingsMap['autoBackup'],
          'backup_frequency': settingsMap['backupFrequency'],
          'location_enabled': settingsMap['locationEnabled'],
          'temperature_unit': settingsMap['temperatureUnit'],
          'date_format': settingsMap['dateFormat'],
          'plant_care_notifications': settingsMap['plantCareNotifications'],
          'market_notifications': settingsMap['marketNotifications'],
          'system_notifications': settingsMap['systemNotifications'],
          'show_personal_info': settingsMap['showPersonalInfo'],
          'share_location': settingsMap['shareLocation'],
          'profile_visibility': settingsMap['profileVisibility'],
        });
      }

      final settings = AppSettings.fromMap(settingsMap);
      emit(SettingsLoaded(settings: settings));
    } catch (e) {
      emit(SettingsError(message: 'خطأ في تحميل الإعدادات: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTheme(
      UpdateThemeEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'theme_mode': event.isDarkMode ? 'dark' : 'light',
      });

      // تحديث في SharedPreferences كنسخة احتياطية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', event.isDarkMode);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          isDarkMode: event.isDarkMode,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث المظهر بنجاح'));
      }
    } catch (e) {
      emit(SettingsError(message: 'خطأ في تحديث المظهر: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateLanguage(
      UpdateLanguageEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'language': event.language,
      });

      // تحديث في SharedPreferences كنسخة احتياطية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', event.language);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          language: event.language,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تغيير اللغة بنجاح'));
      }
    } catch (e) {
      emit(SettingsError(message: 'خطأ في تحديث اللغة: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotificationSettings(
      UpdateNotificationSettingsEvent event,
      Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'notifications_enabled': event.notificationsEnabled,
        'sound_enabled': event.soundEnabled,
        'vibration_enabled': event.vibrationEnabled,
      });

      // تحديث في SharedPreferences كنسخة احتياطية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', event.notificationsEnabled);
      await prefs.setBool('soundEnabled', event.soundEnabled);
      await prefs.setBool('vibrationEnabled', event.vibrationEnabled);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          notificationsEnabled: event.notificationsEnabled,
          soundEnabled: event.soundEnabled,
          vibrationEnabled: event.vibrationEnabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات التنبيهات'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات التنبيهات: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateBackupSettings(
      UpdateBackupSettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'auto_backup': event.autoBackup,
        'backup_frequency': event.backupFrequency,
      });

      // تحديث في SharedPreferences كنسخة احتياطية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoBackup', event.autoBackup);
      await prefs.setString('backupFrequency', event.backupFrequency);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          autoBackup: event.autoBackup,
          backupFrequency: event.backupFrequency,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات النسخ الاحتياطي'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات النسخ الاحتياطي: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateLocationSetting(
      UpdateLocationSettingEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'location_enabled': event.locationEnabled,
      });

      // تحديث في SharedPreferences كنسخة احتياطية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locationEnabled', event.locationEnabled);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          locationEnabled: event.locationEnabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات الموقع'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات الموقع: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDisplaySettings(
      UpdateDisplaySettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'temperature_unit': event.temperatureUnit,
        'date_format': event.dateFormat,
      });

      // تحديث في SharedPreferences كنسخة احتياطية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temperatureUnit', event.temperatureUnit);
      await prefs.setString('dateFormat', event.dateFormat);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          temperatureUnit: event.temperatureUnit,
          dateFormat: event.dateFormat,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات العرض'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات العرض: ${e.toString()}'));
    }
  }

  Future<void> _onResetSettings(
      ResetSettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all settings
      final keys = [
        'isDarkMode',
        'language',
        'notificationsEnabled',
        'soundEnabled',
        'vibrationEnabled',
        'autoBackup',
        'backupFrequency',
        'locationEnabled',
        'temperatureUnit',
        'dateFormat'
      ];

      for (String key in keys) {
        await prefs.remove(key);
      }

      // Load default settings
      final defaultSettings = AppSettings.defaultSettings();
      emit(SettingsLoaded(settings: defaultSettings));
      emit(SettingsSuccess(message: 'تم إعادة تعيين الإعدادات إلى الافتراضية'));
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في إعادة تعيين الإعدادات: ${e.toString()}'));
    }
  }

  Future<void> _onExportData(
      ExportDataEvent event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // جمع جميع بيانات المستخدم
      final exportData = <String, dynamic>{};

      // إعدادات المستخدم
      final userSettings =
          await _supabaseService.getUserSettings(currentUser.id);
      if (userSettings != null) {
        exportData['user_settings'] = userSettings;
      }

      // بيانات الملف الشخصي
      final userProfile = await _supabaseService.getUserProfile(currentUser.id);
      if (userProfile != null) {
        exportData['user_profile'] = userProfile;
      }

      // تشخيصات الأمراض
      final diagnoses = await _supabaseService.getUserDiagnoses();
      exportData['disease_diagnoses'] = diagnoses;

      // أنظمة الري
      final irrigationSystems =
          await _supabaseService.getIrrigationSystems(currentUser.id);
      exportData['irrigation_systems'] = irrigationSystems;

      // إضافة معلومات التصدير
      exportData['export_info'] = {
        'user_id': currentUser.id,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data_version': '1.0',
      };

      // تحويل إلى JSON
      final jsonString = jsonEncode(exportData);

      // حفظ في ملف مؤقت
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'حصاد_بياناتي_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // مشاركة الملف باستخدام share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ملف بيانات تطبيق حصاد',
        subject: 'نسخة احتياطية من بيانات حصاد',
      );

      emit(SettingsSuccess(message: 'تم تصدير البيانات ومشاركتها بنجاح'));
    } catch (e) {
      emit(SettingsError(message: 'خطأ في تصدير البيانات: ${e.toString()}'));
    }
  }

  Future<void> _onImportData(
      ImportDataEvent event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // استخدام file_picker لاختيار الملف
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final importData = jsonDecode(jsonString) as Map<String, dynamic>;

        // التحقق من صحة البيانات
        if (importData['export_info'] == null ||
            importData['export_info']['user_id'] != currentUser.id) {
          emit(SettingsError(
              message: 'ملف البيانات غير صالح أو لا يخص هذا المستخدم'));
          return;
        }

        // استيراد الإعدادات
        if (importData['user_settings'] != null) {
          await _supabaseService.updateUserSettings(
              currentUser.id, importData['user_settings']);
        }

        // استيراد بيانات الملف الشخصي
        if (importData['user_profile'] != null) {
          await _supabaseService.updateUserProfile(
              currentUser.id, importData['user_profile']);
        }

        emit(SettingsSuccess(message: 'تم استيراد البيانات بنجاح'));
      } else {
        emit(SettingsError(message: 'لم يتم اختيار ملف'));
      }
    } catch (e) {
      emit(SettingsError(message: 'خطأ في استيراد البيانات: ${e.toString()}'));
    }
  }

  Future<void> _onClearCache(
      ClearCacheEvent event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());

      // مسح SharedPreferences (باستثناء الإعدادات المهمة)
      final prefs = await SharedPreferences.getInstance();
      final keysToKeep = [
        'isDarkMode',
        'language',
        'notificationsEnabled',
        'soundEnabled',
        'vibrationEnabled',
        'autoBackup',
        'backupFrequency',
        'locationEnabled',
        'temperatureUnit',
        'dateFormat',
        'plantCareNotifications',
        'marketNotifications',
        'systemNotifications',
        'showPersonalInfo',
        'shareLocation',
        'profileVisibility',
        'user_session'
      ];

      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }

      // مسح ذاكرة التخزين المؤقت للصور (إذا كانت متاحة)
      try {
        // يمكن إضافة مسح ذاكرة الصور هنا إذا كانت مكتبة cached_network_image متاحة
        // await DefaultCacheManager().emptyCache();
      } catch (e) {
        // تجاهل الأخطاء في مسح ذاكرة الصور
      }

      // إعادة تحميل الإعدادات الحالية
      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        emit(currentState);
      }

      emit(SettingsSuccess(message: 'تم مسح ذاكرة التخزين المؤقت بنجاح'));
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في مسح ذاكرة التخزين المؤقت: ${e.toString()}'));
    }
  }

  // معالجات الأحداث الجديدة
  Future<void> _onUpdatePlantCareNotifications(
      UpdatePlantCareNotificationsEvent event,
      Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('plantCareNotifications', event.enabled);

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'plant_care_notifications': event.enabled,
      });

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          plantCareNotifications: event.enabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(
            message: 'تم تحديث إعدادات إشعارات العناية بالنباتات'));
      }
    } catch (e) {
      emit(SettingsError(
          message:
              'خطأ في تحديث إعدادات إشعارات العناية بالنباتات: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateMarketNotifications(
      UpdateMarketNotificationsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('marketNotifications', event.enabled);

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'market_notifications': event.enabled,
      });

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          marketNotifications: event.enabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات إشعارات السوق'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات إشعارات السوق: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSystemNotifications(
      UpdateSystemNotificationsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // تحديث في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('systemNotifications', event.enabled);

      // تحديث في قاعدة البيانات
      await _supabaseService.updateUserSettings(currentUser.id, {
        'system_notifications': event.enabled,
      });

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          systemNotifications: event.enabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات إشعارات النظام'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات إشعارات النظام: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePrivacySettings(
      UpdatePrivacySettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(SettingsError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final currentSettings = currentState.settings;

        // تحديث في SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        final Map<String, dynamic> updates = {};

        if (event.showPersonalInfo != null) {
          await prefs.setBool('showPersonalInfo', event.showPersonalInfo!);
          updates['show_personal_info'] = event.showPersonalInfo;
        }

        if (event.shareLocation != null) {
          await prefs.setBool('shareLocation', event.shareLocation!);
          updates['share_location'] = event.shareLocation;
        }

        if (event.profileVisibility != null) {
          await prefs.setBool('profileVisibility', event.profileVisibility!);
          updates['profile_visibility'] = event.profileVisibility;
        }

        // تحديث في قاعدة البيانات
        if (updates.isNotEmpty) {
          await _supabaseService.updateUserSettings(currentUser.id, updates);
        }

        final updatedSettings = currentSettings.copyWith(
          showPersonalInfo:
              event.showPersonalInfo ?? currentSettings.showPersonalInfo,
          shareLocation: event.shareLocation ?? currentSettings.shareLocation,
          profileVisibility:
              event.profileVisibility ?? currentSettings.profileVisibility,
        );

        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات الخصوصية'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات الخصوصية: ${e.toString()}'));
    }
  }

  // دوال الوظائف الجديدة
  Future<void> _onCheckAppUpdate(
      CheckAppUpdateEvent event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());

      // محاكاة فحص التحديثات
      await Future.delayed(const Duration(seconds: 2));

      // في التطبيق الحقيقي، سيتم فحص متجر التطبيقات
      // أو API خاص للتحقق من الإصدارات الجديدة

      emit(SettingsSuccess(message: 'أنت تستخدم أحدث إصدار من التطبيق'));
    } catch (e) {
      emit(SettingsError(message: 'خطأ في فحص التحديثات: ${e.toString()}'));
    }
  }

  Future<void> _onShareApp(
      ShareAppEvent event, Emitter<SettingsState> emit) async {
    try {
      // رابط التطبيق (سيتم تحديثه عند النشر)
      const appUrl =
          'https://play.google.com/store/apps/details?id=com.example.sam';
      const shareText = '''
🌱 اكتشف تطبيق حصاد - المساعد الزراعي الذكي!

✨ ميزات رائعة:
• تشخيص أمراض النباتات بالذكاء الاصطناعي
• إدارة أنظمة الري الذكية
• سوق زراعي متكامل
• نصائح زراعية متخصصة

📱 حمل التطبيق الآن:
$appUrl

#الزراعة_الذكية #حصاد #تكنولوجيا_زراعية
      ''';

      // استخدام مكتبة share_plus للمشاركة
      await Share.share(
        shareText,
        subject: 'تطبيق حصاد - المساعد الزراعي الذكي',
      );

      emit(SettingsSuccess(message: 'تم مشاركة التطبيق بنجاح'));
    } catch (e) {
      emit(SettingsError(message: 'خطأ في مشاركة التطبيق: ${e.toString()}'));
    }
  }

  Future<void> _onRateApp(
      RateAppEvent event, Emitter<SettingsState> emit) async {
    try {
      // رابط تقييم التطبيق
      const rateUrl =
          'https://play.google.com/store/apps/details?id=com.example.sam';

      if (await canLaunchUrl(Uri.parse(rateUrl))) {
        await launchUrl(Uri.parse(rateUrl),
            mode: LaunchMode.externalApplication);
        emit(SettingsSuccess(message: 'شكراً لك! تم فتح صفحة التقييم'));
      } else {
        emit(SettingsError(message: 'لا يمكن فتح متجر التطبيقات'));
      }
    } catch (e) {
      emit(SettingsError(message: 'خطأ في فتح صفحة التقييم: ${e.toString()}'));
    }
  }

  Future<void> _onContactSupport(
      ContactSupportEvent event, Emitter<SettingsState> emit) async {
    try {
      // بيانات الاتصال
      const supportEmail = 'support@hasad-app.com';
      const supportSubject = 'طلب دعم فني - تطبيق حصاد';
      final supportBody = '''
مرحباً فريق الدعم،

أحتاج مساعدة في:
[اكتب مشكلتك هنا]

معلومات التطبيق:
- الإصدار: 1.0.0
- النظام: ${Platform.operatingSystem}

شكراً لكم
      ''';

      final emailUrl =
          'mailto:$supportEmail?subject=${Uri.encodeComponent(supportSubject)}&body=${Uri.encodeComponent(supportBody)}';

      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
        emit(SettingsSuccess(message: 'تم فتح تطبيق البريد الإلكتروني'));
      } else {
        emit(
            SettingsSuccess(message: 'يمكنك التواصل معنا على:\n$supportEmail'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في فتح البريد الإلكتروني: ${e.toString()}'));
    }
  }
}

// Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is SettingsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // إعادة تحميل الإعدادات بعد النجاح
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                context.read<SettingsBloc>().add(LoadSettingsEvent());
              }
            });
          }
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SettingsLoaded) {
              return _buildSettingsView(state.settings);
            } else if (state is SettingsSuccess) {
              // في حالة النجاح، نحتاج لإعادة تحميل الإعدادات
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<SettingsBloc>().add(LoadSettingsEvent());
              });
              return const Center(child: CircularProgressIndicator());
            } else if (state is SettingsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SettingsBloc>().add(LoadSettingsEvent());
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget _buildSettingsView(AppSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAppearanceSection(settings),
          const SizedBox(height: 16),
          _buildNotificationSection(settings),
          const SizedBox(height: 16),
          _buildPrivacySection(settings),
          const SizedBox(height: 16),
          _buildDisplaySection(settings),
          const SizedBox(height: 16),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'المظهر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('المظهر الداكن'),
              subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
              value: settings.isDarkMode,
              onChanged: (value) {
                // تحديث إعدادات المظهر
                context.read<SettingsBloc>().add(
                      UpdateThemeEvent(isDarkMode: value),
                    );
                // تحديث ThemeBloc فوراً
                context.read<ThemeBloc>().add(
                      SetThemeEvent(isDarkMode: value),
                    );
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            ListTile(
              title: const Text('اللغة'),
              subtitle: Text(settings.language == 'ar' ? 'العربية' : 'English'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(settings.language),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'التنبيهات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تفعيل التنبيهات'),
              subtitle: const Text('استقبال التنبيهات من التطبيق'),
              value: settings.notificationsEnabled,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateNotificationSettingsEvent(
                        notificationsEnabled: value,
                        soundEnabled: settings.soundEnabled,
                        vibrationEnabled: settings.vibrationEnabled,
                      ),
                    );
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            SwitchListTile(
              title: const Text('الصوت'),
              subtitle: const Text('تشغيل الصوت مع التنبيهات'),
              value: settings.soundEnabled,
              onChanged: settings.notificationsEnabled
                  ? (value) {
                      context.read<SettingsBloc>().add(
                            UpdateNotificationSettingsEvent(
                              notificationsEnabled:
                                  settings.notificationsEnabled,
                              soundEnabled: value,
                              vibrationEnabled: settings.vibrationEnabled,
                            ),
                          );
                    }
                  : null,
              activeColor: const Color(0xFF2E7D32),
            ),
            SwitchListTile(
              title: const Text('الاهتزاز'),
              subtitle: const Text('تفعيل الاهتزاز مع التنبيهات'),
              value: settings.vibrationEnabled,
              onChanged: settings.notificationsEnabled
                  ? (value) {
                      context.read<SettingsBloc>().add(
                            UpdateNotificationSettingsEvent(
                              notificationsEnabled:
                                  settings.notificationsEnabled,
                              soundEnabled: settings.soundEnabled,
                              vibrationEnabled: value,
                            ),
                          );
                    }
                  : null,
              activeColor: const Color(0xFF2E7D32),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'أنواع الإشعارات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('إشعارات العناية بالنباتات'),
              subtitle: const Text('تذكيرات الري والعناية والصحة'),
              value: settings.plantCareNotifications,
              onChanged: settings.notificationsEnabled
                  ? (value) {
                      context.read<SettingsBloc>().add(
                            UpdatePlantCareNotificationsEvent(enabled: value),
                          );
                    }
                  : null,
              activeColor: const Color(0xFF2E7D32),
            ),
            SwitchListTile(
              title: const Text('إشعارات السوق'),
              subtitle: const Text('عروض وأخبار السوق والمنتجات'),
              value: settings.marketNotifications,
              onChanged: settings.notificationsEnabled
                  ? (value) {
                      context.read<SettingsBloc>().add(
                            UpdateMarketNotificationsEvent(enabled: value),
                          );
                    }
                  : null,
              activeColor: const Color(0xFF2E7D32),
            ),
            SwitchListTile(
              title: const Text('إشعارات النظام'),
              subtitle: const Text('تحديثات التطبيق والإشعارات المهمة'),
              value: settings.systemNotifications,
              onChanged: settings.notificationsEnabled
                  ? (value) {
                      context.read<SettingsBloc>().add(
                            UpdateSystemNotificationsEvent(enabled: value),
                          );
                    }
                  : null,
              activeColor: const Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.privacy_tip, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'الخصوصية والأمان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('خدمات الموقع'),
              subtitle: const Text('السماح للتطبيق بالوصول للموقع'),
              value: settings.locationEnabled,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateLocationSettingEvent(locationEnabled: value),
                    );
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'إعدادات الخصوصية الشخصية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('إظهار المعلومات الشخصية'),
              subtitle:
                  const Text('عرض الاسم والبريد الإلكتروني للمستخدمين الآخرين'),
              value: settings.showPersonalInfo,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdatePrivacySettingsEvent(showPersonalInfo: value),
                    );
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            SwitchListTile(
              title: const Text('مشاركة الموقع'),
              subtitle:
                  const Text('السماح بمشاركة موقعك مع المستخدمين الآخرين'),
              value: settings.shareLocation,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdatePrivacySettingsEvent(shareLocation: value),
                    );
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            SwitchListTile(
              title: const Text('ظهور الملف الشخصي'),
              subtitle:
                  const Text('إمكانية العثور على ملفك الشخصي من قبل الآخرين'),
              value: settings.profileVisibility,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdatePrivacySettingsEvent(profileVisibility: value),
                    );
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            const Divider(),
            ListTile(
              title: const Text('مسح ذاكرة التخزين المؤقت'),
              subtitle: const Text('حذف الملفات المؤقتة'),
              trailing: const Icon(Icons.delete_sweep),
              onTap: () {
                _showClearCacheDialog();
              },
            ),
            ListTile(
              title: const Text('سياسة الخصوصية'),
              subtitle: const Text('اطلع على سياسة الخصوصية'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            ListTile(
              title: const Text('شروط الاستخدام'),
              subtitle: const Text('اطلع على شروط الاستخدام'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to terms of service
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.display_settings, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'إعدادات العرض',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('وحدة درجة الحرارة'),
              subtitle: Text(settings.temperatureUnit == 'celsius'
                  ? 'مئوية (°C)'
                  : 'فهرنهايت (°F)'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showTemperatureUnitDialog(settings.temperatureUnit),
            ),
            ListTile(
              title: const Text('تنسيق التاريخ'),
              subtitle: Text(settings.dateFormat),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showDateFormatDialog(settings.dateFormat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'حول التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              title: Text('إصدار التطبيق'),
              subtitle: Text('1.0.0'),
              trailing: Icon(Icons.info_outline),
            ),
            ListTile(
              title: const Text('تحديث التطبيق'),
              subtitle: const Text('البحث عن تحديثات'),
              trailing: const Icon(Icons.system_update),
              onTap: () {
                context.read<SettingsBloc>().add(CheckAppUpdateEvent());
              },
            ),
            ListTile(
              title: const Text('تقييم التطبيق'),
              subtitle: const Text('قيم التطبيق في المتجر'),
              trailing: const Icon(Icons.star),
              onTap: () {
                context.read<SettingsBloc>().add(RateAppEvent());
              },
            ),
            ListTile(
              title: const Text('مشاركة التطبيق'),
              subtitle: const Text('شارك التطبيق مع الأصدقاء'),
              trailing: const Icon(Icons.share),
              onTap: () {
                context.read<SettingsBloc>().add(ShareAppEvent());
              },
            ),
            ListTile(
              title: const Text('اتصل بنا'),
              subtitle: const Text('تواصل مع فريق الدعم'),
              trailing: const Icon(Icons.contact_support),
              onTap: () {
                context.read<SettingsBloc>().add(ContactSupportEvent());
              },
            ),
            ListTile(
              title: const Text('إعادة تعيين الإعدادات'),
              subtitle: const Text('استعادة الإعدادات الافتراضية'),
              trailing: const Icon(Icons.restore),
              onTap: () {
                _showResetSettingsDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(String currentLanguage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: currentLanguage,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateLanguageEvent(language: value),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateLanguageEvent(language: value),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureUnitDialog(String currentUnit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('وحدة درجة الحرارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('مئوية (°C)'),
              value: 'celsius',
              groupValue: currentUnit,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: value,
                          dateFormat: (context.read<SettingsBloc>().state
                                  as SettingsLoaded)
                              .settings
                              .dateFormat,
                        ),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('فهرنهايت (°F)'),
              value: 'fahrenheit',
              groupValue: currentUnit,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: value,
                          dateFormat: (context.read<SettingsBloc>().state
                                  as SettingsLoaded)
                              .settings
                              .dateFormat,
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

  void _showDateFormatDialog(String currentFormat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنسيق التاريخ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('dd/MM/yyyy'),
              value: 'dd/MM/yyyy',
              groupValue: currentFormat,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: (context.read<SettingsBloc>().state
                                  as SettingsLoaded)
                              .settings
                              .temperatureUnit,
                          dateFormat: value,
                        ),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('MM/dd/yyyy'),
              value: 'MM/dd/yyyy',
              groupValue: currentFormat,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: (context.read<SettingsBloc>().state
                                  as SettingsLoaded)
                              .settings
                              .temperatureUnit,
                          dateFormat: value,
                        ),
                      );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('yyyy-MM-dd'),
              value: 'yyyy-MM-dd',
              groupValue: currentFormat,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: (context.read<SettingsBloc>().state
                                  as SettingsLoaded)
                              .settings
                              .temperatureUnit,
                          dateFormat: value,
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح ذاكرة التخزين المؤقت'),
        content: const Text(
            'هل تريد مسح جميع الملفات المؤقتة؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(ClearCacheEvent());
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text(
            'هل تريد إعادة تعيين جميع الإعدادات إلى القيم الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(ResetSettingsEvent());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
}
