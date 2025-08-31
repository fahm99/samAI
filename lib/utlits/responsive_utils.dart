import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مساعد التصميم المتجاوب - يوفر أدوات لجعل التطبيق متجاوب مع جميع أحجام الشاشات
class ResponsiveUtils {
  
  /// تحديد نوع الجهاز بناءً على عرض الشاشة
  static DeviceType getDeviceType(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return DeviceType.mobile;
    } else if (screenWidth < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  /// التحقق من كون الجهاز هاتف محمول
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  /// التحقق من كون الجهاز تابلت
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  /// التحقق من كون الجهاز سطح مكتب
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
  
  /// الحصول على عدد الأعمدة المناسب للشبكة
  static int getGridColumns(BuildContext context) {
    final DeviceType deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }
  
  /// الحصول على نسبة العرض إلى الارتفاع للبطاقات
  static double getCardAspectRatio(BuildContext context) {
    final DeviceType deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 0.8;
      case DeviceType.tablet:
        return 0.9;
      case DeviceType.desktop:
        return 1.0;
    }
  }
  
  /// الحصول على المسافة المناسبة بين العناصر
  static double getSpacing(BuildContext context, SpacingType type) {
    final DeviceType deviceType = getDeviceType(context);
    
    switch (type) {
      case SpacingType.small:
        return deviceType == DeviceType.mobile ? 8.w : 12.w;
      case SpacingType.medium:
        return deviceType == DeviceType.mobile ? 16.w : 20.w;
      case SpacingType.large:
        return deviceType == DeviceType.mobile ? 24.w : 32.w;
      case SpacingType.extraLarge:
        return deviceType == DeviceType.mobile ? 32.w : 48.w;
    }
  }
  
  /// الحصول على حجم الخط المناسب
  static double getFontSize(BuildContext context, FontSizeType type) {
    final DeviceType deviceType = getDeviceType(context);
    
    double baseSize;
    switch (type) {
      case FontSizeType.small:
        baseSize = 12;
        break;
      case FontSizeType.medium:
        baseSize = 14;
        break;
      case FontSizeType.large:
        baseSize = 16;
        break;
      case FontSizeType.extraLarge:
        baseSize = 18;
        break;
      case FontSizeType.title:
        baseSize = 20;
        break;
      case FontSizeType.heading:
        baseSize = 24;
        break;
    }
    
    // تكبير الخط للأجهزة الأكبر
    if (deviceType == DeviceType.tablet) {
      baseSize *= 1.1;
    } else if (deviceType == DeviceType.desktop) {
      baseSize *= 1.2;
    }
    
    return baseSize.sp;
  }
  
  /// الحصول على ارتفاع مناسب للعنصر
  static double getHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }
  
  /// الحصول على عرض مناسب للعنصر
  static double getWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
  
  /// الحصول على حجم الأيقونة المناسب
  static double getIconSize(BuildContext context, IconSizeType type) {
    final DeviceType deviceType = getDeviceType(context);
    
    double baseSize;
    switch (type) {
      case IconSizeType.small:
        baseSize = 16;
        break;
      case IconSizeType.medium:
        baseSize = 20;
        break;
      case IconSizeType.large:
        baseSize = 24;
        break;
      case IconSizeType.extraLarge:
        baseSize = 32;
        break;
    }
    
    // تكبير الأيقونة للأجهزة الأكبر
    if (deviceType == DeviceType.tablet) {
      baseSize *= 1.2;
    } else if (deviceType == DeviceType.desktop) {
      baseSize *= 1.4;
    }
    
    return baseSize.w;
  }
  
  /// الحصول على نصف قطر الحواف المناسب
  static double getBorderRadius(BuildContext context, BorderRadiusType type) {
    final DeviceType deviceType = getDeviceType(context);
    
    double baseRadius;
    switch (type) {
      case BorderRadiusType.small:
        baseRadius = 4;
        break;
      case BorderRadiusType.medium:
        baseRadius = 8;
        break;
      case BorderRadiusType.large:
        baseRadius = 12;
        break;
      case BorderRadiusType.extraLarge:
        baseRadius = 16;
        break;
    }
    
    // تكبير نصف القطر للأجهزة الأكبر
    if (deviceType == DeviceType.tablet) {
      baseRadius *= 1.2;
    } else if (deviceType == DeviceType.desktop) {
      baseRadius *= 1.4;
    }
    
    return baseRadius.r;
  }
  
  /// الحصول على الحشو المناسب
  static EdgeInsets getPadding(BuildContext context, PaddingType type) {
    final double spacing = getSpacing(context, SpacingType.medium);
    
    switch (type) {
      case PaddingType.small:
        return EdgeInsets.all(spacing * 0.5);
      case PaddingType.medium:
        return EdgeInsets.all(spacing);
      case PaddingType.large:
        return EdgeInsets.all(spacing * 1.5);
      case PaddingType.horizontal:
        return EdgeInsets.symmetric(horizontal: spacing);
      case PaddingType.vertical:
        return EdgeInsets.symmetric(vertical: spacing);
      case PaddingType.screen:
        return EdgeInsets.symmetric(
          horizontal: spacing,
          vertical: spacing * 0.5,
        );
    }
  }
  
  /// بناء تخطيط متجاوب بناءً على نوع الجهاز
  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final DeviceType deviceType = getDeviceType(context);
        
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// أنواع الأجهزة
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// أنواع المسافات
enum SpacingType {
  small,
  medium,
  large,
  extraLarge,
}

/// أنواع أحجام الخط
enum FontSizeType {
  small,
  medium,
  large,
  extraLarge,
  title,
  heading,
}

/// أنواع أحجام الأيقونات
enum IconSizeType {
  small,
  medium,
  large,
  extraLarge,
}

/// أنواع نصف قطر الحواف
enum BorderRadiusType {
  small,
  medium,
  large,
  extraLarge,
}

/// أنواع الحشو
enum PaddingType {
  small,
  medium,
  large,
  horizontal,
  vertical,
  screen,
}

/// ويدجت مساعد للتصميم المتجاوب
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildResponsiveLayout(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
