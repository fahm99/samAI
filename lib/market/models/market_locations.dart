/// مواقع السوق الزراعي في اليمن
class MarketLocations {
  /// قائمة المحافظات والمدن الرئيسية
  static List<String> getLocations() {
    return [
      'صنعاء',
      'عدن',
      'تعز',
      'الحديدة',
      'إب',
      'ذمار',
      'صعدة',
      'حجة',
      'المحويت',
      'عمران',
      'الجوف',
      'مأرب',
      'البيضاء',
      'أبين',
      'شبوة',
      'حضرموت',
      'المهرة',
      'سقطرى',
      'لحج',
      'الضالع',
      'ريمة',
      'أخرى',
    ];
  }

  /// الحصول على المحافظات الرئيسية فقط
  static List<String> getMainGovernorates() {
    return [
      'صنعاء',
      'عدن',
      'تعز',
      'الحديدة',
      'إب',
      'ذمار',
      'حضرموت',
      'أخرى',
    ];
  }

  /// التحقق من صحة الموقع
  static bool isValidLocation(String location) {
    return getLocations().contains(location);
  }

  /// الحصول على الموقع الافتراضي
  static String getDefaultLocation() {
    return 'صنعاء';
  }
}
