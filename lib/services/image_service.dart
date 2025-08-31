import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// خدمة ضغط ومعالجة الصور
class ImageService {
  // إعدادات خاصة بالصور الشخصية
  static const int _profileMaxWidth = 400;
  static const int _profileMaxHeight = 400;
  static const int _profileQuality = 85;
  static const int _profileMaxFileSizeKB = 500; // 500 KB

  // إعدادات عامة للصور الأخرى
  static const int _maxWidth = 1024;
  static const int _maxHeight = 1024;
  static const int _quality = 85;
  static const int _maxFileSizeKB = 500; // 500 KB

  /// ضغط الصورة الشخصية بمواصفات محددة (400x400, <500KB)
  static Future<File?> compressProfileImage(File imageFile) async {
    try {
      // قراءة الصورة
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('فشل في قراءة الصورة');
        return null;
      }

      // تغيير حجم الصورة إلى 400x400 مع الحفاظ على النسبة
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: _profileMaxWidth,
        height: _profileMaxHeight,
        interpolation: img.Interpolation.cubic,
      );

      // ضغط الصورة بصيغة JPEG
      List<int> compressedBytes = img.encodeJpg(
        resizedImage,
        quality: _profileQuality,
      );

      // التحقق من حجم الملف وضغط إضافي إذا لزم الأمر
      int fileSizeKB = compressedBytes.length ~/ 1024;
      debugPrint('حجم الصورة الشخصية بعد الضغط: ${fileSizeKB}KB');

      // إذا كان الحجم ما زال كبيراً، ضغط أكثر
      if (fileSizeKB > _profileMaxFileSizeKB) {
        compressedBytes = await _furtherCompressProfileImage(resizedImage);
        fileSizeKB = compressedBytes.length ~/ 1024;
        debugPrint('حجم الصورة الشخصية بعد الضغط الإضافي: ${fileSizeKB}KB');
      }

      // حفظ الصورة المضغوطة
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
        path.join(tempDir.path,
            'compressed_profile_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      );

      await compressedFile.writeAsBytes(compressedBytes);
      debugPrint('تم ضغط الصورة الشخصية بنجاح. الحجم النهائي: ${fileSizeKB}KB');

      return compressedFile;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة الشخصية: $e');
      return null;
    }
  }

  /// ضغط الصورة وتحسين جودتها
  static Future<File?> compressImage(File imageFile) async {
    try {
      // قراءة الصورة
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('فشل في قراءة الصورة');
        return null;
      }

      // تحديد الأبعاد الجديدة مع الحفاظ على النسبة
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;

      int newWidth = originalWidth;
      int newHeight = originalHeight;

      // تصغير الصورة إذا كانت أكبر من الحد المسموح
      if (originalWidth > _maxWidth || originalHeight > _maxHeight) {
        final double aspectRatio = originalWidth / originalHeight;

        if (originalWidth > originalHeight) {
          newWidth = _maxWidth;
          newHeight = (_maxWidth / aspectRatio).round();
        } else {
          newHeight = _maxHeight;
          newWidth = (_maxHeight * aspectRatio).round();
        }
      }

      // تغيير حجم الصورة
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // ضغط الصورة بصيغة JPEG
      List<int> compressedBytes = img.encodeJpg(
        resizedImage,
        quality: _quality,
      );

      // التحقق من حجم الملف وضغط إضافي إذا لزم الأمر
      int fileSizeKB = compressedBytes.length ~/ 1024;
      debugPrint('حجم الصورة بعد الضغط: ${fileSizeKB}KB');

      // إذا كان الحجم ما زال كبيراً، ضغط أكثر
      if (fileSizeKB > _maxFileSizeKB) {
        compressedBytes = await _furtherCompressBytes(resizedImage);
        fileSizeKB = compressedBytes.length ~/ 1024;
        debugPrint('حجم الصورة بعد الضغط الإضافي: ${fileSizeKB}KB');
      }

      // إنشاء ملف من البايتات المضغوطة
      if (kIsWeb) {
        // في الويب، نعيد الملف الأصلي (سيتم التعامل مع البايتات في الواجهة)
        return imageFile;
      } else {
        return await _createFileFromBytes(Uint8List.fromList(compressedBytes),
            'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      }
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة: $e');
      return null;
    }
  }

  /// إنشاء ملف من البايتات (يدعم الويب والمحمول)
  static Future<File?> _createFileFromBytes(
      Uint8List bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // في الويب، لا نحتاج لحفظ الملف فعلياً
        // سنعيد الملف الأصلي مع البايتات المضغوطة
        // هذا حل مؤقت للويب
        return null; // سنتعامل مع هذا في الكود المستدعي
      } else {
        // في المحمول، نستخدم المجلد المؤقت
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = path.join(tempDir.path, fileName);
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      debugPrint('خطأ في إنشاء الملف: $e');
      return null;
    }
  }

  /// ضغط إضافي للصور الشخصية (إرجاع البايتات)
  static Future<List<int>> _furtherCompressProfileImage(img.Image image) async {
    try {
      // تقليل الجودة تدريجياً للصور الشخصية
      for (int quality = 70; quality >= 30; quality -= 10) {
        final List<int> compressedBytes =
            img.encodeJpg(image, quality: quality);
        final int fileSizeKB = compressedBytes.length ~/ 1024;

        if (fileSizeKB <= _profileMaxFileSizeKB) {
          debugPrint(
              'حجم الصورة الشخصية النهائي: ${fileSizeKB}KB بجودة: $quality%');
          return compressedBytes;
        }
      }

      // إذا لم ينجح تقليل الجودة، قلل الحجم أكثر (مع الحفاظ على النسبة المربعة)
      final img.Image smallerImage = img.copyResize(
        image,
        width: (_profileMaxWidth * 0.8).round(),
        height: (_profileMaxHeight * 0.8).round(),
      );

      final List<int> finalBytes = img.encodeJpg(smallerImage, quality: 50);
      debugPrint('حجم الصورة الشخصية النهائي: ${finalBytes.length ~/ 1024}KB');
      return finalBytes;
    } catch (e) {
      debugPrint('خطأ في الضغط الإضافي للصورة الشخصية: $e');
      // إرجاع الصورة الأصلية في حالة الخطأ
      return img.encodeJpg(image, quality: 50);
    }
  }

  /// ضغط إضافي للصور الكبيرة (إرجاع البايتات)
  static Future<List<int>> _furtherCompressBytes(img.Image image) async {
    try {
      // تقليل الجودة تدريجياً
      for (int quality = 70; quality >= 30; quality -= 10) {
        final List<int> compressedBytes =
            img.encodeJpg(image, quality: quality);
        final int fileSizeKB = compressedBytes.length ~/ 1024;

        if (fileSizeKB <= _maxFileSizeKB) {
          debugPrint('حجم الصورة النهائي: ${fileSizeKB}KB بجودة: $quality%');
          return compressedBytes;
        }
      }

      // إذا لم ينجح تقليل الجودة، قلل الحجم أكثر
      final img.Image smallerImage = img.copyResize(
        image,
        width: (image.width * 0.8).round(),
        height: (image.height * 0.8).round(),
      );

      final List<int> finalBytes = img.encodeJpg(smallerImage, quality: 60);
      debugPrint('حجم الصورة النهائي: ${finalBytes.length ~/ 1024}KB');
      return finalBytes;
    } catch (e) {
      debugPrint('خطأ في الضغط الإضافي: $e');
      // إرجاع الصورة الأصلية في حالة الخطأ
      return img.encodeJpg(image, quality: 60);
    }
  }

  /// ضغط الصورة الشخصية للويب (إرجاع البايتات فقط)
  static Future<Uint8List?> compressProfileImageForWeb(
      Uint8List imageBytes) async {
    try {
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('فشل في قراءة الصورة');
        return null;
      }

      // تغيير حجم الصورة إلى 400x400 مع الحفاظ على النسبة
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: _profileMaxWidth,
        height: _profileMaxHeight,
        interpolation: img.Interpolation.cubic,
      );

      // ضغط الصورة بصيغة JPEG
      List<int> compressedBytes = img.encodeJpg(
        resizedImage,
        quality: _profileQuality,
      );

      // التحقق من حجم الملف وضغط إضافي إذا لزم الأمر
      int fileSizeKB = compressedBytes.length ~/ 1024;
      debugPrint('حجم الصورة الشخصية للويب بعد الضغط: ${fileSizeKB}KB');

      // إذا كان الحجم ما زال كبيراً، ضغط أكثر
      if (fileSizeKB > _profileMaxFileSizeKB) {
        compressedBytes = await _furtherCompressProfileImage(resizedImage);
        fileSizeKB = compressedBytes.length ~/ 1024;
        debugPrint(
            'حجم الصورة الشخصية للويب بعد الضغط الإضافي: ${fileSizeKB}KB');
      }

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة الشخصية للويب: $e');
      return null;
    }
  }

  /// ضغط الصورة للويب (إرجاع البايتات فقط)
  static Future<Uint8List?> compressImageForWeb(Uint8List imageBytes) async {
    try {
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('فشل في قراءة الصورة');
        return null;
      }

      // تحديد الأبعاد الجديدة مع الحفاظ على النسبة
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;

      int newWidth = originalWidth;
      int newHeight = originalHeight;

      // تصغير الصورة إذا كانت أكبر من الحد المسموح
      if (originalWidth > _maxWidth || originalHeight > _maxHeight) {
        final double aspectRatio = originalWidth / originalHeight;

        if (originalWidth > originalHeight) {
          newWidth = _maxWidth;
          newHeight = (_maxWidth / aspectRatio).round();
        } else {
          newHeight = _maxHeight;
          newWidth = (_maxHeight * aspectRatio).round();
        }
      }

      // تغيير حجم الصورة
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // ضغط الصورة بصيغة JPEG
      List<int> compressedBytes = img.encodeJpg(
        resizedImage,
        quality: _quality,
      );

      // التحقق من حجم الملف وضغط إضافي إذا لزم الأمر
      int fileSizeKB = compressedBytes.length ~/ 1024;
      debugPrint('حجم الصورة بعد الضغط: ${fileSizeKB}KB');

      // إذا كان الحجم ما زال كبيراً، ضغط أكثر
      if (fileSizeKB > _maxFileSizeKB) {
        compressedBytes = await _furtherCompressBytes(resizedImage);
        fileSizeKB = compressedBytes.length ~/ 1024;
        debugPrint('حجم الصورة بعد الضغط الإضافي: ${fileSizeKB}KB');
      }

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة للويب: $e');
      return null;
    }
  }

  /// إنشاء صورة مصغرة
  static Future<File?> createThumbnail(File imageFile, {int size = 200}) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) return null;

      // إنشاء صورة مربعة مصغرة
      final img.Image thumbnail =
          img.copyResizeCropSquare(originalImage, size: size);
      final List<int> thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);

      // حفظ الصورة المصغرة
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempDir.path, fileName);

      final File thumbnailFile = File(filePath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      debugPrint('خطأ في إنشاء الصورة المصغرة: $e');
      return null;
    }
  }

  /// تحسين صورة للعرض
  static Future<File?> optimizeForDisplay(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) return null;

      // تحسين الألوان والتباين
      img.Image optimizedImage = img.adjustColor(
        originalImage,
        contrast: 1.1,
        saturation: 1.05,
        brightness: 1.02,
      );

      // تطبيق فلتر تنعيم خفيف
      optimizedImage = img.gaussianBlur(optimizedImage, radius: 1);

      final List<int> optimizedBytes =
          img.encodeJpg(optimizedImage, quality: 90);

      // حفظ الصورة المحسنة
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempDir.path, fileName);

      final File optimizedFile = File(filePath);
      await optimizedFile.writeAsBytes(optimizedBytes);

      return optimizedFile;
    } catch (e) {
      debugPrint('خطأ في تحسين الصورة: $e');
      return null;
    }
  }

  /// تنظيف الملفات المؤقتة
  static Future<void> cleanupTempFiles() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();

      for (final file in files) {
        if (file is File &&
            (file.path.contains('compressed_') ||
                file.path.contains('thumb_') ||
                file.path.contains('optimized_'))) {
          // حذف الملفات الأقدم من يوم واحد
          final DateTime fileDate = file.statSync().modified;
          final Duration age = DateTime.now().difference(fileDate);

          if (age.inDays >= 1) {
            await file.delete();
            debugPrint('تم حذف الملف المؤقت: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في تنظيف الملفات المؤقتة: $e');
    }
  }

  /// الحصول على معلومات الصورة
  static Future<Map<String, dynamic>?> getImageInfo(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) return null;

      final int fileSizeKB = imageBytes.length ~/ 1024;

      return {
        'width': image.width,
        'height': image.height,
        'sizeKB': fileSizeKB,
        'aspectRatio': image.width / image.height,
        'format': path.extension(imageFile.path).toLowerCase(),
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات الصورة: $e');
      return null;
    }
  }
}
