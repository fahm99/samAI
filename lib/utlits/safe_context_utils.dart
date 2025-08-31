// safe_context_utils.dart - أدوات آمنة للتعامل مع Context
import 'package:flutter/material.dart';

/// فئة مساعدة للتعامل الآمن مع Context في العمليات غير المتزامنة
class SafeContextUtils {
  /// عرض SnackBar بشكل آمن
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    bool mounted = true,
  }) {
    if (!mounted || !context.mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    } catch (e) {
      debugPrint('خطأ في عرض SnackBar: $e');
    }
  }

  /// عرض Dialog بشكل آمن
  static Future<T?> showSafeDialog<T>(
    BuildContext context,
    Widget dialog, {
    bool barrierDismissible = true,
    bool mounted = true,
  }) async {
    if (!mounted || !context.mounted) return null;
    
    try {
      return await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => dialog,
      );
    } catch (e) {
      debugPrint('خطأ في عرض Dialog: $e');
      return null;
    }
  }

  /// التنقل بشكل آمن
  static Future<T?> safePush<T>(
    BuildContext context,
    Widget page, {
    bool mounted = true,
  }) async {
    if (!mounted || !context.mounted) return null;
    
    try {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } catch (e) {
      debugPrint('خطأ في التنقل: $e');
      return null;
    }
  }

  /// استبدال الصفحة بشكل آمن
  static Future<T?> safePushReplacement<T>(
    BuildContext context,
    Widget page, {
    bool mounted = true,
  }) async {
    if (!mounted || !context.mounted) return null;
    
    try {
      return await Navigator.pushReplacement<T, dynamic>(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } catch (e) {
      debugPrint('خطأ في استبدال الصفحة: $e');
      return null;
    }
  }

  /// العودة بشكل آمن
  static void safePop<T>(
    BuildContext context, {
    T? result,
    bool mounted = true,
  }) {
    if (!mounted || !context.mounted) return;
    
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop<T>(context, result);
      }
    } catch (e) {
      debugPrint('خطأ في العودة: $e');
    }
  }

  /// عرض رسالة خطأ آمنة
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    bool mounted = true,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      mounted: mounted,
    );
  }

  /// عرض رسالة نجاح آمنة
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    bool mounted = true,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      mounted: mounted,
    );
  }

  /// عرض رسالة تحذير آمنة
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    bool mounted = true,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
      mounted: mounted,
    );
  }

  /// عرض dialog تأكيد آمن
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
    bool mounted = true,
  }) async {
    if (!mounted || !context.mounted) return false;
    
    final result = await showSafeDialog<bool>(
      context,
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
      mounted: mounted,
    );
    
    return result ?? false;
  }

  /// عرض loading dialog آمن
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'جاري التحميل...',
    bool mounted = true,
  }) {
    if (!mounted || !context.mounted) return;
    
    showSafeDialog(
      context,
      AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
      barrierDismissible: false,
      mounted: mounted,
    );
  }

  /// إخفاء loading dialog آمن
  static void hideLoadingDialog(
    BuildContext context, {
    bool mounted = true,
  }) {
    safePop(context, mounted: mounted);
  }
}

/// Extension لإضافة خصائص آمنة للـ BuildContext
extension SafeBuildContext on BuildContext {
  /// التحقق من أن الـ context ما زال صالحاً
  bool get isSafe => mounted;
  
  /// عرض SnackBar آمن
  void showSafeSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    SafeContextUtils.showSnackBar(
      this,
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      mounted: mounted,
    );
  }
  
  /// عرض رسالة خطأ آمنة
  void showSafeError(String message) {
    SafeContextUtils.showErrorSnackBar(this, message, mounted: mounted);
  }
  
  /// عرض رسالة نجاح آمنة
  void showSafeSuccess(String message) {
    SafeContextUtils.showSuccessSnackBar(this, message, mounted: mounted);
  }
  
  /// التنقل الآمن
  Future<T?> safePush<T>(Widget page) {
    return SafeContextUtils.safePush<T>(this, page, mounted: mounted);
  }
  
  /// استبدال الصفحة الآمن
  Future<T?> safePushReplacement<T>(Widget page) {
    return SafeContextUtils.safePushReplacement<T>(this, page, mounted: mounted);
  }
  
  /// العودة الآمنة
  void safePop<T>([T? result]) {
    SafeContextUtils.safePop<T>(this, result: result, mounted: mounted);
  }
}
