/// فئات المنتجات في السوق الزراعي
class MarketCategories {
  /// قائمة التصنيفات الموحدة مع الأيقونات
  static List<Map<String, String>> getCategoriesData() {
    return [
      {'name': 'الكل', 'value': '', 'icon': '🏪'},
      {'name': 'خضروات', 'value': 'خضروات', 'icon': '🥬'},
      {'name': 'فواكه', 'value': 'فواكه', 'icon': '🍎'},
      {'name': 'حبوب', 'value': 'حبوب', 'icon': '🌾'},
      {'name': 'بذور', 'value': 'بذور', 'icon': '🌱'},
      {'name': 'أسمدة', 'value': 'أسمدة', 'icon': '🧪'},
      {'name': 'أدوات زراعية', 'value': 'أدوات زراعية', 'icon': '🔧'},
      {'name': 'أخرى', 'value': 'أخرى', 'icon': '📦'},
    ];
  }

  /// الحصول على قائمة أسماء الفئات فقط
  static List<String> getCategoryNames() {
    return getCategoriesData()
        .map((cat) => cat['name']!)
        .where((name) => name != 'الكل')
        .toList();
  }

  /// الحصول على قائمة قيم الفئات فقط
  static List<String> getCategoryValues() {
    return getCategoriesData()
        .map((cat) => cat['value']!)
        .where((value) => value.isNotEmpty)
        .toList();
  }

  /// الحصول على أيقونة الفئة
  static String getCategoryIcon(String categoryValue) {
    final category = getCategoriesData().firstWhere(
      (cat) => cat['value'] == categoryValue,
      orElse: () => {'icon': '📦'},
    );
    return category['icon'] ?? '📦';
  }

  /// الحصول على اسم الفئة من القيمة
  static String getCategoryName(String categoryValue) {
    final category = getCategoriesData().firstWhere(
      (cat) => cat['value'] == categoryValue,
      orElse: () => {'name': 'أخرى'},
    );
    return category['name'] ?? 'أخرى';
  }
}
