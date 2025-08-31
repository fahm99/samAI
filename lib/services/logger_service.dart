// خدمة التسجيل المركزية للتطبيق
// تستبدل جميع استخدامات print() لتحسين الأداء والتتبع في الإنتاج

import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// خدمة التسجيل المركزية للتطبيق
/// توفر طرق محسنة للتسجيل مع مستويات مختلفة
/// وتعطيل التسجيل في وضع الإنتاج لتحسين الأداء
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  late final Logger _logger;

  /// تهيئة خدمة التسجيل
  /// يتم استدعاؤها مرة واحدة في بداية التطبيق
  void initialize() {
    _logger = Logger(
      filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2, // عدد الطرق المعروضة في stack trace
        errorMethodCount: 8, // عدد الطرق في حالة الخطأ
        lineLength: 120, // طول السطر
        colors: true, // استخدام الألوان
        printEmojis: true, // استخدام الرموز التعبيرية
        printTime: true, // طباعة الوقت
      ),
      output: ConsoleOutput(),
    );
  }

  /// تسجيل رسالة معلوماتية
  /// يستخدم للمعلومات العامة والتتبع
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل رسالة تحذيرية
  /// يستخدم للتحذيرات التي لا تؤثر على عمل التطبيق
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل رسالة خطأ
  /// يستخدم للأخطاء التي تؤثر على عمل التطبيق
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل رسالة تصحيح
  /// يستخدم فقط في وضع التطوير للتتبع المفصل
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل رسالة مطولة
  /// يستخدم للمعلومات المفصلة جداً
  void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل خطأ فادح
  /// يستخدم للأخطاء الخطيرة التي قد تؤدي لتعطل التطبيق
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل عملية قاعدة البيانات
  /// يستخدم لتتبع العمليات مع قاعدة البيانات
  void database(String operation, String table, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      final message = '🗄️ قاعدة البيانات: $operation في جدول $table';
      if (data != null) {
        _logger.d('$message\nالبيانات: $data');
      } else {
        _logger.d(message);
      }
    }
  }

  /// تسجيل عملية شبكة
  /// يستخدم لتتبع طلبات الشبكة والاستجابات
  void network(String method, String url, {int? statusCode, dynamic data}) {
    if (kDebugMode) {
      final message = '🌐 شبكة: $method $url';
      if (statusCode != null) {
        _logger.d('$message - الحالة: $statusCode');
      } else {
        _logger.d(message);
      }
      if (data != null) {
        _logger.v('البيانات: $data');
      }
    }
  }

  /// تسجيل عملية مصادقة
  /// يستخدم لتتبع عمليات تسجيل الدخول والخروج
  void auth(String action, {String? userId, bool success = true}) {
    final emoji = success ? '✅' : '❌';
    final status = success ? 'نجح' : 'فشل';
    final message = '$emoji مصادقة: $action - $status';
    
    if (userId != null) {
      _logger.i('$message (المستخدم: $userId)');
    } else {
      _logger.i(message);
    }
  }

  /// تسجيل أداء العمليات
  /// يستخدم لتتبع أوقات تنفيذ العمليات
  void performance(String operation, Duration duration) {
    if (kDebugMode) {
      final milliseconds = duration.inMilliseconds;
      final emoji = milliseconds > 1000 ? '🐌' : milliseconds > 500 ? '⚠️' : '⚡';
      _logger.d('$emoji أداء: $operation - ${milliseconds}ms');
    }
  }

  /// تسجيل تفاعل المستخدم
  /// يستخدم لتتبع تفاعلات المستخدم مع التطبيق
  void userAction(String action, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final message = '👤 تفاعل المستخدم: $action';
      if (context != null) {
        _logger.d('$message\nالسياق: $context');
      } else {
        _logger.d(message);
      }
    }
  }
}

/// مرشح الإنتاج - يعرض فقط الأخطاء والتحذيرات المهمة
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= Level.warning.index;
  }
}

/// مثيل عام لخدمة التسجيل للاستخدام في جميع أنحاء التطبيق
final logger = LoggerService();
