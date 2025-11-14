import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// أدوات مساعدة للتطبيق
class AppUtils {
  /// تنسيق التاريخ
  static String formatDate(DateTime date, {String? pattern}) {
    final formatter = DateFormat(pattern ?? AppConstants.displayDateFormat);
    return formatter.format(date);
  }

  /// تنسيق الوقت
  static String formatTime(DateTime time, {String? pattern}) {
    final formatter = DateFormat(pattern ?? AppConstants.displayTimeFormat);
    return formatter.format(time);
  }

  /// تنسيق التاريخ والوقت
  static String formatDateTime(DateTime dateTime, {String? pattern}) {
    final formatter = DateFormat(pattern ?? '${AppConstants.displayDateFormat} ${AppConstants.displayTimeFormat}');
    return formatter.format(dateTime);
  }

  /// تنسيق الوقت النسبي (منذ ساعة، منذ يوم، إلخ)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'منذ يوم' : 'منذ ${difference.inDays} أيام';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? 'منذ ساعة' : 'منذ ${difference.inHours} ساعات';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? 'منذ دقيقة' : 'منذ ${difference.inMinutes} دقائق';
    } else {
      return 'الآن';
    }
  }

  /// تنسيق الأرقام
  static String formatNumber(num number, {int? decimalPlaces}) {
    if (decimalPlaces != null) {
      return number.toStringAsFixed(decimalPlaces);
    }
    return NumberFormat('#,##0.##').format(number);
  }

  /// تنسيق العملة
  static String formatCurrency(double amount, {String currency = 'ر.س'}) {
    return '${formatNumber(amount, decimalPlaces: 2)} $currency';
  }

  /// تنسيق حجم الملف
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// التحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(phone.replaceAll(' ', ''));
  }

  /// التحقق من قوة كلمة المرور
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;
    if (password.length >= 8) score++;
    
    if (score < 3) return PasswordStrength.weak;
    if (score < 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// إنشاء معرف فريد
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  /// تنظيف النص من المسافات الزائدة
  static String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// اقتطاع النص
  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// تحويل النص إلى عنوان URL صالح
  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[-\s]+'), '-');
  }

  /// التحقق من نوع الملف
  static bool isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return AppConstants.imageExtensions.any((ext) => ext.contains(extension));
  }

  /// الحصول على لون عشوائي
  static Color getRandomColor() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  /// تحويل اللون إلى نص hex
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// تحويل نص hex إلى لون
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// حساب المسافة بين نقطتين جغرافيتين
  static double calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    const double earthRadius = 6371; // كيلومتر
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// التحقق من الاتصال بالإنترنت
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// تأخير تنفيذ العملية
  static Future<void> delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// إعادة المحاولة مع تأخير
  static Future<T> retryWithDelay<T>(
    Future<T> Function() operation,
    {int maxRetries = 3, Duration delay = const Duration(seconds: 1)}
  ) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// تشفير بسيط للنصوص (Base64)
  static String encodeBase64(String text) {
    return base64Encode(utf8.encode(text));
  }

  /// فك تشفير Base64
  static String decodeBase64(String encoded) {
    return utf8.decode(base64Decode(encoded));
  }

  /// التحقق من إصدار التطبيق
  static bool isVersionGreater(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map(int.parse).toList();
    List<int> v2Parts = version2.split('.').map(int.parse).toList();
    
    int maxLength = max(v1Parts.length, v2Parts.length);
    
    for (int i = 0; i < maxLength; i++) {
      int v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      int v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part > v2Part) return true;
      if (v1Part < v2Part) return false;
    }
    
    return false;
  }
}

/// قوة كلمة المرور
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// أدوات التحقق من الصحة
class ValidationUtils {
  /// التحقق من أن النص غير فارغ
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'هذا الحقل'} مطلوب';
    }
    return null;
  }

  /// التحقق من البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!AppUtils.isValidEmail(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  /// التحقق من كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل';
    }
    return null;
  }

  /// التحقق من رقم الهاتف
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    if (!AppUtils.isValidPhoneNumber(value)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  /// التحقق من السعر
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'السعر مطلوب';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'السعر يجب أن يكون رقماً';
    }
    if (price < AppConstants.minPrice || price > AppConstants.maxPrice) {
      return 'السعر يجب أن يكون بين ${AppConstants.minPrice} و ${AppConstants.maxPrice}';
    }
    return null;
  }

  /// التحقق من التقييم
  static String? validateRating(int? value) {
    if (value == null) {
      return 'التقييم مطلوب';
    }
    if (value < AppConstants.minRating || value > AppConstants.maxRating) {
      return 'التقييم يجب أن يكون بين ${AppConstants.minRating} و ${AppConstants.maxRating}';
    }
    return null;
  }
}

