/// إعدادات التطبيق المركزية
class AppConfig {
  // معلومات التطبيق
  static const String appName = 'SamAI - المزارع الذكي';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // إعدادات Supabase
  static const String supabaseUrl = 'https://gwpwvhkcvkfmxodblnll.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3cHd2aGtjdmtmbXhvZGJsbmxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMDY1ODksImV4cCI6MjA2Njg4MjU4OX0.wFyQYDuaUUickuYpqTGHXSZvlOwLCpX2-QVuEgWWrNM';

  // إعدادات API
  static const String plantDiseaseApiUrl = 'https://api.plantdisease.ai';
  static const String weatherApiUrl = 'https://api.openweathermap.org';

  // إعدادات التخزين المؤقت
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // إعدادات الشبكة
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // إعدادات الصور
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int imageQuality = 85;

  // إعدادات التطبيق
  static const int itemsPerPage = 20;
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const int maxSearchHistory = 10;

  // إعدادات الأمان
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // إعدادات الإشعارات
  static const bool enablePushNotifications = true;
  static const bool enableLocalNotifications = true;

  // إعدادات التحليلات
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // روابط مهمة
  static const String privacyPolicyUrl = 'https://samai-app.com/privacy';
  static const String termsOfServiceUrl = 'https://samai-app.com/terms';
  static const String supportEmail = 'support@samai-app.com';
  static const String websiteUrl = 'https://samai-app.com';

  // وسائل التواصل الاجتماعي
  static const String facebookUrl = 'https://facebook.com/SamAIApp';
  static const String twitterUrl = 'https://twitter.com/SamAIApp';
  static const String instagramUrl = 'https://instagram.com/samai_app';

  // إعدادات التطوير
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  static const bool enablePerformanceMonitoring = true;
}

/// إعدادات البيئة
enum Environment {
  development,
  staging,
  production,
}

/// مدير البيئة
class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  static Environment get currentEnvironment => _currentEnvironment;

  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;

  static String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
}
