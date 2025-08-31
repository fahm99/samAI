import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة النسخ الاحتياطية للبيانات المهمة
class BackupService {
  static const String _lastBackupKey = 'last_backup_date';
  static const String _backupEnabledKey = 'backup_enabled';
  static const int _backupIntervalDays = 3; // نسخ احتياطية كل 3 أيام

  /// تشغيل النسخ الاحتياطي
  static Future<bool> performBackup({bool force = false}) async {
    try {
      debugPrint('بدء عملية النسخ الاحتياطي...');

      if (!force && !await _shouldPerformBackup()) {
        debugPrint('لا حاجة للنسخ الاحتياطي الآن');
        return false;
      }

      // التحقق من تمكين النسخ الاحتياطي
      if (!await isBackupEnabled()) {
        debugPrint('النسخ الاحتياطي معطل');
        return false;
      }

      // إنشاء مجلد النسخ الاحتياطية
      final Directory backupDir = await _getBackupDirectory();
      
      // نسخ احتياطي للإعدادات
      await _backupSettings(backupDir);
      
      // نسخ احتياطي لبيانات المستخدم
      await _backupUserData(backupDir);
      
      // نسخ احتياطي لقائمة المفضلة
      await _backupFavorites(backupDir);
      
      // نسخ احتياطي لتاريخ التشخيصات
      await _backupDiagnosisHistory(backupDir);

      // تحديث تاريخ آخر نسخ احتياطي
      await _updateLastBackupDate();

      debugPrint('تم الانتهاء من النسخ الاحتياطي بنجاح');
      return true;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي: $e');
      return false;
    }
  }

  /// استعادة البيانات من النسخة الاحتياطية
  static Future<bool> restoreFromBackup() async {
    try {
      debugPrint('بدء عملية الاستعادة...');

      final Directory backupDir = await _getBackupDirectory();
      
      if (!await backupDir.exists()) {
        debugPrint('لا توجد نسخة احتياطية');
        return false;
      }

      // استعادة الإعدادات
      await _restoreSettings(backupDir);
      
      // استعادة بيانات المستخدم
      await _restoreUserData(backupDir);
      
      // استعادة المفضلة
      await _restoreFavorites(backupDir);
      
      // استعادة تاريخ التشخيصات
      await _restoreDiagnosisHistory(backupDir);

      debugPrint('تم الانتهاء من الاستعادة بنجاح');
      return true;
    } catch (e) {
      debugPrint('خطأ في الاستعادة: $e');
      return false;
    }
  }

  /// التحقق من ضرورة النسخ الاحتياطي
  static Future<bool> _shouldPerformBackup() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastBackupStr = prefs.getString(_lastBackupKey);
      
      if (lastBackupStr == null) return true;

      final DateTime lastBackup = DateTime.parse(lastBackupStr);
      final DateTime now = DateTime.now();
      final int daysSinceLastBackup = now.difference(lastBackup).inDays;

      return daysSinceLastBackup >= _backupIntervalDays;
    } catch (e) {
      debugPrint('خطأ في التحقق من ضرورة النسخ الاحتياطي: $e');
      return true;
    }
  }

  /// الحصول على مجلد النسخ الاحتياطية
  static Future<Directory> _getBackupDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory backupDir = Directory('${appDir.path}/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// نسخ احتياطي للإعدادات
  static Future<void> _backupSettings(Directory backupDir) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();
      final Map<String, dynamic> settings = {};

      for (final key in keys) {
        // نسخ الإعدادات المهمة فقط
        if (key.startsWith('setting_') || 
            key.startsWith('user_') ||
            key.startsWith('app_')) {
          final dynamic value = prefs.get(key);
          settings[key] = value;
        }
      }

      final File settingsFile = File('${backupDir.path}/settings.json');
      await settingsFile.writeAsString(jsonEncode(settings));
      
      debugPrint('تم نسخ ${settings.length} إعداد');
    } catch (e) {
      debugPrint('خطأ في نسخ الإعدادات: $e');
    }
  }

  /// نسخ احتياطي لبيانات المستخدم
  static Future<void> _backupUserData(Directory backupDir) async {
    try {
      // هذه الوظيفة تتطلب تكامل مع Supabase
      // سيتم تطبيقها مع تحسينات قاعدة البيانات
      
      final Map<String, dynamic> userData = {
        'backup_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // سيتم الحصول عليها من package_info
        'user_id': 'current_user_id', // سيتم الحصول عليها من Supabase
      };

      final File userDataFile = File('${backupDir.path}/user_data.json');
      await userDataFile.writeAsString(jsonEncode(userData));
      
      debugPrint('تم نسخ بيانات المستخدم');
    } catch (e) {
      debugPrint('خطأ في نسخ بيانات المستخدم: $e');
    }
  }

  /// نسخ احتياطي للمفضلة
  static Future<void> _backupFavorites(Directory backupDir) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? favorites = prefs.getStringList('favorites');
      
      if (favorites != null) {
        final File favoritesFile = File('${backupDir.path}/favorites.json');
        await favoritesFile.writeAsString(jsonEncode(favorites));
        debugPrint('تم نسخ ${favorites.length} عنصر مفضل');
      }
    } catch (e) {
      debugPrint('خطأ في نسخ المفضلة: $e');
    }
  }

  /// نسخ احتياطي لتاريخ التشخيصات
  static Future<void> _backupDiagnosisHistory(Directory backupDir) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('diagnosis_history');
      
      if (historyJson != null) {
        final File historyFile = File('${backupDir.path}/diagnosis_history.json');
        await historyFile.writeAsString(historyJson);
        debugPrint('تم نسخ تاريخ التشخيصات');
      }
    } catch (e) {
      debugPrint('خطأ في نسخ تاريخ التشخيصات: $e');
    }
  }

  /// استعادة الإعدادات
  static Future<void> _restoreSettings(Directory backupDir) async {
    try {
      final File settingsFile = File('${backupDir.path}/settings.json');
      
      if (await settingsFile.exists()) {
        final String content = await settingsFile.readAsString();
        final Map<String, dynamic> settings = jsonDecode(content);
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        for (final entry in settings.entries) {
          final String key = entry.key;
          final dynamic value = entry.value;

          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is List<String>) {
            await prefs.setStringList(key, value);
          }
        }

        debugPrint('تم استعادة ${settings.length} إعداد');
      }
    } catch (e) {
      debugPrint('خطأ في استعادة الإعدادات: $e');
    }
  }

  /// استعادة بيانات المستخدم
  static Future<void> _restoreUserData(Directory backupDir) async {
    try {
      final File userDataFile = File('${backupDir.path}/user_data.json');
      
      if (await userDataFile.exists()) {
        final String content = await userDataFile.readAsString();
        final Map<String, dynamic> userData = jsonDecode(content);
        
        // معالجة بيانات المستخدم المستعادة
        debugPrint('تم استعادة بيانات المستخدم من: ${userData['backup_date']}');
      }
    } catch (e) {
      debugPrint('خطأ في استعادة بيانات المستخدم: $e');
    }
  }

  /// استعادة المفضلة
  static Future<void> _restoreFavorites(Directory backupDir) async {
    try {
      final File favoritesFile = File('${backupDir.path}/favorites.json');
      
      if (await favoritesFile.exists()) {
        final String content = await favoritesFile.readAsString();
        final List<dynamic> favorites = jsonDecode(content);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        
        await prefs.setStringList('favorites', favorites.cast<String>());
        debugPrint('تم استعادة ${favorites.length} عنصر مفضل');
      }
    } catch (e) {
      debugPrint('خطأ في استعادة المفضلة: $e');
    }
  }

  /// استعادة تاريخ التشخيصات
  static Future<void> _restoreDiagnosisHistory(Directory backupDir) async {
    try {
      final File historyFile = File('${backupDir.path}/diagnosis_history.json');
      
      if (await historyFile.exists()) {
        final String content = await historyFile.readAsString();
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('diagnosis_history', content);
        debugPrint('تم استعادة تاريخ التشخيصات');
      }
    } catch (e) {
      debugPrint('خطأ في استعادة تاريخ التشخيصات: $e');
    }
  }

  /// تحديث تاريخ آخر نسخ احتياطي
  static Future<void> _updateLastBackupDate() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('خطأ في تحديث تاريخ النسخ الاحتياطي: $e');
    }
  }

  /// تمكين/تعطيل النسخ الاحتياطي
  static Future<void> setBackupEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, enabled);
  }

  /// التحقق من تمكين النسخ الاحتياطي
  static Future<bool> isBackupEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEnabledKey) ?? true; // مفعل افتراضياً
  }

  /// الحصول على معلومات النسخة الاحتياطية
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastBackupStr = prefs.getString(_lastBackupKey);
      final bool isEnabled = await isBackupEnabled();
      
      final Directory backupDir = await _getBackupDirectory();
      final bool hasBackup = await backupDir.exists();
      
      return {
        'isEnabled': isEnabled,
        'hasBackup': hasBackup,
        'lastBackup': lastBackupStr,
        'nextBackup': lastBackupStr != null 
            ? DateTime.parse(lastBackupStr).add(const Duration(days: _backupIntervalDays)).toIso8601String()
            : null,
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات النسخة الاحتياطية: $e');
      return null;
    }
  }
}
