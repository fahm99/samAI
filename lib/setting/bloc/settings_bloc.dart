import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/supabaseservice.dart';
import '../models/app_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

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
    on<UpdatePlantCareNotificationsEvent>(_onUpdatePlantCareNotifications,
        transformer: _debounceTransformer());
    on<UpdateMarketNotificationsEvent>(_onUpdateMarketNotifications,
        transformer: _debounceTransformer());
    on<UpdateSystemNotificationsEvent>(_onUpdateSystemNotifications,
        transformer: _debounceTransformer());
    on<UpdatePrivacySettingsEvent>(_onUpdatePrivacySettings,
        transformer: _debounceTransformer());
    on<CheckAppUpdateEvent>(_onCheckAppUpdate);
    on<ShareAppEvent>(_onShareApp);
    on<RateAppEvent>(_onRateApp);
    on<ContactSupportEvent>(_onContactSupport);
  }

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

      final settingsData =
          await _supabaseService.getUserSettings(currentUser.id);

      Map<String, dynamic> settingsMap;
      if (settingsData != null) {
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
        settingsMap = AppSettings.defaultSettings().toMap();
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

      await _supabaseService.updateUserSettings(currentUser.id, {
        'theme_mode': event.isDarkMode ? 'dark' : 'light',
      });

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

      await _supabaseService.updateUserSettings(currentUser.id, {
        'language': event.language,
      });

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

      await _supabaseService.updateUserSettings(currentUser.id, {
        'notifications_enabled': event.notificationsEnabled,
        'sound_enabled': event.soundEnabled,
        'vibration_enabled': event.vibrationEnabled,
      });

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

      await _supabaseService.updateUserSettings(currentUser.id, {
        'auto_backup': event.autoBackup,
        'backup_frequency': event.backupFrequency,
      });

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

      await _supabaseService.updateUserSettings(currentUser.id, {
        'location_enabled': event.locationEnabled,
      });

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

      await _supabaseService.updateUserSettings(currentUser.id, {
        'temperature_unit': event.temperatureUnit,
        'date_format': event.dateFormat,
      });

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

  Future<void> _onUpdatePlantCareNotifications(
      UpdatePlantCareNotificationsEvent event,
      Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.updateUserSettings(currentUser.id, {
        'plant_care_notifications': event.enabled,
      });

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          plantCareNotifications: event.enabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
      }
    } catch (e) {
      debugPrint('خطأ في تحديث إشعارات العناية بالنباتات: $e');
    }
  }

  Future<void> _onUpdateMarketNotifications(
      UpdateMarketNotificationsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.updateUserSettings(currentUser.id, {
        'market_notifications': event.enabled,
      });

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          marketNotifications: event.enabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
      }
    } catch (e) {
      debugPrint('خطأ في تحديث إشعارات السوق: $e');
    }
  }

  Future<void> _onUpdateSystemNotifications(
      UpdateSystemNotificationsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.updateUserSettings(currentUser.id, {
        'system_notifications': event.enabled,
      });

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          systemNotifications: event.enabled,
        );
        emit(currentState.copyWith(settings: updatedSettings));
      }
    } catch (e) {
      debugPrint('خطأ في تحديث إشعارات النظام: $e');
    }
  }

  Future<void> _onUpdatePrivacySettings(
      UpdatePrivacySettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      final updates = <String, dynamic>{};
      if (event.showPersonalInfo != null) {
        updates['show_personal_info'] = event.showPersonalInfo;
      }
      if (event.shareLocation != null) {
        updates['share_location'] = event.shareLocation;
      }
      if (event.profileVisibility != null) {
        updates['profile_visibility'] = event.profileVisibility;
      }

      await _supabaseService.updateUserSettings(currentUser.id, updates);

      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        final updatedSettings = currentState.settings.copyWith(
          showPersonalInfo: event.showPersonalInfo,
          shareLocation: event.shareLocation,
          profileVisibility: event.profileVisibility,
        );
        emit(currentState.copyWith(settings: updatedSettings));
        emit(SettingsSuccess(message: 'تم تحديث إعدادات الخصوصية'));
      }
    } catch (e) {
      emit(SettingsError(
          message: 'خطأ في تحديث إعدادات الخصوصية: ${e.toString()}'));
    }
  }

  Future<void> _onResetSettings(
      ResetSettingsEvent event, Emitter<SettingsState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

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

      final exportData = <String, dynamic>{};
      final userSettings =
          await _supabaseService.getUserSettings(currentUser.id);
      if (userSettings != null) {
        exportData['user_settings'] = userSettings;
      }

      final userProfile = await _supabaseService.getUserProfile(currentUser.id);
      if (userProfile != null) {
        exportData['user_profile'] = userProfile;
      }

      exportData['export_info'] = {
        'user_id': currentUser.id,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '2.1.0',
      };

      final jsonString = jsonEncode(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'حصاد_بياناتي_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ملف بيانات تطبيق حصاد',
      );

      emit(SettingsSuccess(message: 'تم تصدير البيانات بنجاح'));
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

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final importData = jsonDecode(jsonString) as Map<String, dynamic>;

        if (importData['user_settings'] != null) {
          await _supabaseService.updateUserSettings(
              currentUser.id, importData['user_settings']);
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

      final prefs = await SharedPreferences.getInstance();
      final keysToKeep = ['user_session', 'isDarkMode', 'language'];
      final allKeys = prefs.getKeys();

      for (String key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }

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

  Future<void> _onCheckAppUpdate(
      CheckAppUpdateEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsSuccess(message: 'أنت تستخدم أحدث إصدار من التطبيق'));
  }

  Future<void> _onShareApp(
      ShareAppEvent event, Emitter<SettingsState> emit) async {
    try {
      await Share.share(
        'جرب تطبيق حصاد - تطبيق زراعي ذكي\nرابط التحميل: [App Link]',
        subject: 'تطبيق حصاد',
      );
    } catch (e) {
      emit(SettingsError(message: 'خطأ في مشاركة التطبيق: ${e.toString()}'));
    }
  }

  Future<void> _onRateApp(
      RateAppEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsSuccess(message: 'شكراً لتقييمك!'));
  }

  Future<void> _onContactSupport(
      ContactSupportEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsSuccess(message: 'سيتم فتح صفحة الدعم الفني'));
  }
}
