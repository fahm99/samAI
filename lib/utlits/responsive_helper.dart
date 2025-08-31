import 'package:flutter/material.dart';

/// مساعد للتصميم المتجاوب مع أحجام الشاشات المختلفة
class ResponsiveHelper {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  /// التحقق من نوع الجهاز
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _tabletBreakpoint;
  }

  /// الحصول على عدد الأعمدة حسب حجم الشاشة
  static int getCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// الحصول على نسبة العرض إلى الارتفاع
  static double getChildAspectRatio(BuildContext context) {
    if (isMobile(context)) return 0.75;
    if (isTablet(context)) return 0.8;
    return 0.85;
  }

  /// الحصول على حجم الخط المناسب
  static double getFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseFontSize * 0.9;
    } else if (screenWidth > 600) {
      return baseFontSize * 1.1;
    }
    return baseFontSize;
  }

  /// الحصول على المسافات المناسبة
  static double getPadding(BuildContext context, double basePadding) {
    if (isMobile(context)) return basePadding;
    if (isTablet(context)) return basePadding * 1.2;
    return basePadding * 1.5;
  }

  /// الحصول على حجم الأيقونة المناسب
  static double getIconSize(BuildContext context, double baseIconSize) {
    if (isMobile(context)) return baseIconSize;
    if (isTablet(context)) return baseIconSize * 1.1;
    return baseIconSize * 1.2;
  }

  /// الحصول على ارتفاع AppBar المناسب
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return kToolbarHeight;
    return kToolbarHeight * 1.2;
  }

  /// الحصول على عرض الحاوية المناسب
  static double getContainerWidth(BuildContext context, double maxWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > maxWidth) return maxWidth;
    return screenWidth * 0.9;
  }

  /// الحصول على ارتفاع البطاقة المناسب
  static double getCardHeight(BuildContext context, double baseHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      return baseHeight * 0.8;
    } else if (screenHeight > 800) {
      return baseHeight * 1.1;
    }
    return baseHeight;
  }

  /// تحديد ما إذا كان يجب استخدام تخطيط أفقي أم عمودي
  static bool shouldUseHorizontalLayout(BuildContext context) {
    return MediaQuery.of(context).size.width > 
           MediaQuery.of(context).size.height * 1.2;
  }

  /// الحصول على عدد العناصر في الصف
  static int getItemsPerRow(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  /// الحصول على حجم الصورة المناسب
  static double getImageSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSize * 0.8;
    } else if (screenWidth > 600) {
      return baseSize * 1.2;
    }
    return baseSize;
  }

  /// الحصول على المسافة بين العناصر
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  /// الحصول على نصف قطر الحواف
  static double getBorderRadius(BuildContext context, double baseRadius) {
    if (isMobile(context)) return baseRadius;
    return baseRadius * 1.2;
  }

  /// تحديد ما إذا كان يجب إظهار التفاصيل الإضافية
  static bool shouldShowDetails(BuildContext context) {
    return !isMobile(context);
  }

  /// الحصول على عدد الأسطر المسموح في النص
  static int getMaxLines(BuildContext context, int baseMaxLines) {
    if (isMobile(context)) return baseMaxLines;
    return baseMaxLines + 1;
  }

  /// الحصول على حجم الزر المناسب
  static Size getButtonSize(BuildContext context) {
    if (isMobile(context)) {
      return const Size(double.infinity, 48);
    } else if (isTablet(context)) {
      return const Size(200, 52);
    }
    return const Size(250, 56);
  }

  /// الحصول على نوع التخطيط للقائمة
  static Axis getListDirection(BuildContext context) {
    return isMobile(context) ? Axis.vertical : Axis.horizontal;
  }

  /// الحصول على المسافة الآمنة
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// تحديد ما إذا كان يجب استخدام Drawer أم BottomNavigationBar
  static bool shouldUseDrawer(BuildContext context) {
    return isTablet(context) || isDesktop(context);
  }

  /// الحصول على عرض Drawer
  static double getDrawerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.3;
  }

  /// الحصول على ارتفاع BottomSheet
  static double getBottomSheetHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.6;
  }
}
