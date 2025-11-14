/// ثوابت التطبيق
class AppConstants {
  // أسماء الجداول في قاعدة البيانات
  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String diagnosesTable = 'diagnoses';
  static const String irrigationTable = 'irrigation_systems';
  static const String ratingsTable = 'product_ratings';
  static const String likesTable = 'product_likes';

  // مفاتيح التخزين المحلي
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String onboardingKey = 'onboarding_completed';
  static const String cacheKey = 'app_cache';

  // أنواع الملفات المدعومة
  static const List<String> imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp'
  ];
  static const List<String> documentExtensions = ['.pdf', '.doc', '.docx'];

  // حدود الملفات
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  static const int maxImagesPerProduct = 5;

  // رسائل الخطأ
  static const String networkErrorMessage = 'خطأ في الاتصال بالشبكة';
  static const String serverErrorMessage = 'خطأ في الخادم';
  static const String unauthorizedMessage = 'غير مصرح لك بالوصول';
  static const String notFoundMessage = 'المحتوى غير موجود';
  static const String validationErrorMessage = 'بيانات غير صحيحة';

  // رسائل النجاح
  static const String loginSuccessMessage = 'تم تسجيل الدخول بنجاح';
  static const String logoutSuccessMessage = 'تم تسجيل الخروج بنجاح';
  static const String saveSuccessMessage = 'تم الحفظ بنجاح';
  static const String updateSuccessMessage = 'تم التحديث بنجاح';
  static const String deleteSuccessMessage = 'تم الحذف بنجاح';

  // أنواع النباتات المدعومة
  static const List<String> supportedPlants = [
    'طماطم',
    'خيار',
    'فلفل',
    'باذنجان',
    'بطاطس',
    'جزر',
    'خس',
    'سبانخ',
    'بصل',
    'ثوم',
  ];

  // حالات المنتجات
  static const String productAvailable = 'متوفر';
  static const String productSoldOut = 'نفد';
  static const String productReserved = 'محجوز';

  // حالات الطلبات
  static const String orderPending = 'في الانتظار';
  static const String orderConfirmed = 'مؤكد';
  static const String orderShipped = 'تم الشحن';
  static const String orderDelivered = 'تم التسليم';
  static const String orderCancelled = 'ملغي';

  // أنواع الإشعارات
  static const String notificationTypeInfo = 'info';
  static const String notificationTypeWarning = 'warning';
  static const String notificationTypeError = 'error';
  static const String notificationTypeSuccess = 'success';

  // مستويات التسجيل
  static const String logLevelDebug = 'DEBUG';
  static const String logLevelInfo = 'INFO';
  static const String logLevelWarning = 'WARNING';
  static const String logLevelError = 'ERROR';

  // أنماط التاريخ والوقت
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayTimeFormat = 'hh:mm a';

  // الحد الأدنى والأقصى للقيم
  static const double minPrice = 0.0;
  static const double maxPrice = 999999.0;
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  // أبعاد الصور
  static const int thumbnailSize = 150;
  static const int mediumImageSize = 500;
  static const int largeImageSize = 1200;

  // مدد الانتظار
  static const int splashScreenDuration = 3; // ثواني
  static const int toastDuration = 3; // ثواني
  static const int snackBarDuration = 4; // ثواني

  // أولويات المهام
  static const int highPriority = 1;
  static const int mediumPriority = 2;
  static const int lowPriority = 3;
}

/// ثوابت الألوان
class ColorConstants {
  // الألوان الأساسية
  static const int primaryColorValue = 0xFF2E7D32;
  static const int secondaryColorValue = 0xFF4CAF50;
  static const int accentColorValue = 0xFF8BC34A;

  // ألوان الحالة
  static const int successColorValue = 0xFF4CAF50;
  static const int warningColorValue = 0xFFFF9800;
  static const int errorColorValue = 0xFFF44336;
  static const int infoColorValue = 0xFF2196F3;

  // ألوان النص
  static const int primaryTextColorValue = 0xFF212121;
  static const int secondaryTextColorValue = 0xFF757575;
  static const int hintTextColorValue = 0xFF9E9E9E;

  // ألوان الخلفية
  static const int backgroundColorValue = 0xFFFAFAFA;
  static const int surfaceColorValue = 0xFFFFFFFF;
  static const int cardColorValue = 0xFFFFFFFF;
}

/// ثوابت الخطوط
class FontConstants {
  // أحجام الخطوط
  static const double extraSmallFontSize = 10.0;
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 18.0;
  static const double titleFontSize = 20.0;
  static const double headingFontSize = 24.0;

  // أوزان الخطوط
  static const String lightWeight = '300';
  static const String normalWeight = '400';
  static const String mediumWeight = '500';
  static const String semiBoldWeight = '600';
  static const String boldWeight = '700';
}

/// ثوابت المسافات
class SpacingConstants {
  // المسافات الأساسية
  static const double extraSmallSpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // الحواف
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;

  // نصف القطر للحواف المنحنية
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
}

/// ثوابت الرسوم المتحركة
class AnimationConstants {
  // مدد الرسوم المتحركة
  static const int fastAnimationDuration = 200; // مللي ثانية
  static const int normalAnimationDuration = 300; // مللي ثانية
  static const int slowAnimationDuration = 500; // مللي ثانية

  // منحنيات الرسوم المتحركة
  static const String easeInCurve = 'easeIn';
  static const String easeOutCurve = 'easeOut';
  static const String easeInOutCurve = 'easeInOut';
  static const String bounceCurve = 'bounce';
}
