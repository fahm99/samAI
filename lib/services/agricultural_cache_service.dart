// agricultural_cache_service.dart - خدمة التخزين المؤقت للتطبيق الزراعي
import 'dart:async';
import 'dart:collection';
import '../market/market.dart';
import '../profile/profile.dart';

class AgriculturalCacheService {
  static final AgriculturalCacheService _instance =
      AgriculturalCacheService._internal();
  factory AgriculturalCacheService() => _instance;
  AgriculturalCacheService._internal();

  // خريطة لحفظ البيانات في الذاكرة مع انتهاء صلاحية
  final Map<String, CacheItem> _cache = HashMap<String, CacheItem>();

  // خريطة لحفظ المنتجات الزراعية
  final Map<String, Product> _products = HashMap<String, Product>();

  // بيانات المستخدم
  UserProfile? _userProfile;

  // قوائم للبيانات الثابتة
  List<String> _categories = [];
  List<String> _locations = [];

  // بيانات الطقس
  Map<String, dynamic>? _weatherData;

  // بيانات البحث المحفوظة
  final Map<String, List<Product>> _searchResults =
      HashMap<String, List<Product>>();

  // بيانات الأدوات والإعدادات
  final Map<String, dynamic> _toolsData = HashMap<String, dynamic>();

  // بيانات أنظمة الري
  final Map<String, dynamic> _irrigationSystems = HashMap<String, dynamic>();

  // بيانات أجهزة الاستشعار
  final Map<String, List<dynamic>> _sensorData =
      HashMap<String, List<dynamic>>();

  // حالة الاتصال
  bool _isConnected = true;

  // Stream للإشعار بتغييرات البيانات
  final StreamController<String> _dataUpdateController =
      StreamController<String>.broadcast();
  Stream<String> get dataUpdates => _dataUpdateController.stream;

  // === طرق إدارة المنتجات ===

  // حفظ قائمة المنتجات مع مدة انتهاء طويلة (24 ساعة)
  void cacheProducts(List<Product> products) {
    for (var product in products) {
      _products[product.id] = product;
    }
    put('all_products', products.map((p) => p.toMap()).toList(),
        expiry: const Duration(hours: 24));
    _dataUpdateController.add('products_updated');
  }

  // استرجاع جميع المنتجات المحفوظة
  List<Product> getCachedProducts() {
    return _products.values.toList();
  }

  // حفظ منتج واحد
  void cacheProduct(Product product) {
    _products[product.id] = product;
    _dataUpdateController.add('product_updated');
  }

  // استرجاع منتج محدد
  Product? getCachedProduct(String productId) {
    return _products[productId];
  }

  // البحث في المنتجات المحفوظة
  List<Product> searchCachedProducts(
    String query, {
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) {
    var results = _products.values.where((product) {
      // البحث النصي
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());

      // فلتر الفئة
      final matchesCategory = category == null || product.category == category;

      // فلتر الموقع
      final matchesLocation = location == null || product.location == location;

      // فلتر السعر
      final matchesPrice = (minPrice == null || product.price >= minPrice) &&
          (maxPrice == null || product.price <= maxPrice);

      return matchesQuery && matchesCategory && matchesLocation && matchesPrice;
    }).toList();

    // حفظ نتائج البحث
    _searchResults[query] = results;

    return results;
  }

  // === طرق إدارة بيانات المستخدم ===

  // حفظ بيانات المستخدم - مدة أطول للتخزين
  void cacheUserProfile(UserProfile profile) {
    _userProfile = profile;
    put('user_profile', profile.toMap(),
        expiry: const Duration(days: 7)); // زيادة إلى أسبوع
    _dataUpdateController.add('profile_updated');
  }

  // استرجاع بيانات المستخدم
  UserProfile? getCachedUserProfile() {
    return _userProfile;
  }

  // === طرق إدارة الفئات والمواقع ===

  // حفظ قائمة الفئات - مدة أطول للتخزين
  void cacheCategories(List<String> categories) {
    _categories = List.from(categories);
    put('categories', categories,
        expiry: const Duration(days: 1)); // زيادة إلى يوم كامل
    _dataUpdateController.add('categories_updated');
  }

  // استرجاع قائمة الفئات
  List<String> getCachedCategories() {
    return List.from(_categories);
  }

  // حفظ قائمة المواقع - مدة أطول للتخزين
  void cacheLocations(List<String> locations) {
    _locations = List.from(locations);
    put('locations', locations,
        expiry: const Duration(days: 1)); // زيادة إلى يوم كامل
    _dataUpdateController.add('locations_updated');
  }

  // استرجاع قائمة المواقع
  List<String> getCachedLocations() {
    return List.from(_locations);
  }

  // === طرق إدارة بيانات الطقس ===

  // حفظ بيانات الطقس مع مدة انتهاء طويلة (6 ساعات)
  void cacheWeatherData(Map<String, dynamic> weatherData) {
    _weatherData = Map.from(weatherData);
    put('weather_data', weatherData, expiry: const Duration(hours: 6));
    _dataUpdateController.add('weather_updated');
  }

  // استرجاع بيانات الطقس
  Map<String, dynamic>? getCachedWeatherData() {
    return _weatherData != null ? Map.from(_weatherData!) : null;
  }

  // === طرق إدارة بيانات الأدوات ===

  // حفظ بيانات الأدوات الزراعية
  void cacheToolsData(Map<String, dynamic> toolsData) {
    _toolsData.addAll(toolsData);
    put('tools_data', toolsData, expiry: const Duration(hours: 1));
    _dataUpdateController.add('tools_updated');
  }

  // استرجاع بيانات الأدوات
  Map<String, dynamic> getCachedToolsData() {
    return Map.from(_toolsData);
  }

  // === طرق إدارة بيانات الري ===

  // حفظ أنظمة الري مع مدة انتهاء طويلة (24 ساعة)
  void cacheIrrigationSystems(List<Map<String, dynamic>> systems) {
    for (var system in systems) {
      _irrigationSystems[system['id'].toString()] = system;
    }
    put('irrigation_systems', systems, expiry: const Duration(hours: 24));
    _dataUpdateController.add('irrigation_systems_updated');
  }

  // استرجاع أنظمة الري
  List<Map<String, dynamic>> getCachedIrrigationSystems() {
    return _irrigationSystems.values.cast<Map<String, dynamic>>().toList();
  }

  // حفظ نظام ري واحد
  void cacheIrrigationSystem(Map<String, dynamic> system) {
    _irrigationSystems[system['id'].toString()] = system;
    _dataUpdateController.add('irrigation_system_updated');
  }

  // استرجاع نظام ري محدد
  Map<String, dynamic>? getCachedIrrigationSystem(String systemId) {
    return _irrigationSystems[systemId];
  }

  // حفظ بيانات أجهزة الاستشعار
  void cacheSensorData(String systemId, List<Map<String, dynamic>> sensorData) {
    _sensorData[systemId] = sensorData;
    put('sensor_data_$systemId', sensorData,
        expiry: const Duration(minutes: 5));
    _dataUpdateController.add('sensor_data_updated');
  }

  // استرجاع بيانات أجهزة الاستشعار
  List<Map<String, dynamic>> getCachedSensorData(String systemId) {
    return List<Map<String, dynamic>>.from(_sensorData[systemId] ?? []);
  }

  // حفظ آخر قراءة للاستشعار
  void cacheLatestSensorReading(String systemId, Map<String, dynamic> reading) {
    final currentData = _sensorData[systemId] ?? [];
    currentData.insert(0, reading); // إضافة في المقدمة
    if (currentData.length > 50) {
      // الاحتفاظ بآخر 50 قراءة فقط
      currentData.removeLast();
    }
    _sensorData[systemId] = currentData;
    _dataUpdateController.add('sensor_reading_updated');
  }

  // === طرق عامة للتخزين المؤقت ===

  // حفظ البيانات مع انتهاء صلاحية اختياري
  void put(String key, dynamic value, {Duration? expiry}) {
    final expiryTime = expiry != null ? DateTime.now().add(expiry) : null;

    _cache[key] = CacheItem(
      value: value,
      timestamp: DateTime.now(),
      expiry: expiryTime,
    );
  }

  // استرجاع البيانات
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;

    // فحص انتهاء الصلاحية
    if (item.expiry != null && DateTime.now().isAfter(item.expiry!)) {
      _cache.remove(key);
      return null;
    }

    return item.value as T?;
  }

  // === طرق إدارة حالة الاتصال ===

  // تحديث حالة الاتصال مع آلية التحديث الخفي
  void updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;

      // عند استعادة الاتصال، ابدأ التحديث الخفي في الخلفية
      if (isConnected) {
        _startSilentBackgroundUpdate();
        _dataUpdateController.add('connection_restored_silent');
      } else {
        _dataUpdateController.add('connection_lost_silent');
      }
    }
  }

  // فحص حالة الاتصال
  bool get isConnected => _isConnected;

  // آلية التحديث الخفي في الخلفية
  void _startSilentBackgroundUpdate() {
    // تحديث خفي بدون إشعار المستخدم
    Timer(const Duration(seconds: 2), () {
      if (_isConnected) {
        _dataUpdateController.add('silent_update_started');
        // يمكن للـ BLoCs الاستماع لهذا الحدث وتحديث البيانات خفياً
      }
    });
  }

  // فحص ما إذا كانت البيانات تحتاج تحديث (قديمة)
  bool isDataStale(String key, Duration maxAge) {
    final item = _cache[key];
    if (item == null) return true;

    final age = DateTime.now().difference(item.timestamp);
    return age > maxAge;
  }

  // الحصول على عمر البيانات
  Duration? getDataAge(String key) {
    final item = _cache[key];
    if (item == null) return null;

    return DateTime.now().difference(item.timestamp);
  }

  // === طرق التنظيف والإدارة ===

  // فحص وجود البيانات
  bool contains(String key) {
    final item = _cache[key];
    if (item == null) return false;

    // فحص انتهاء الصلاحية
    if (item.expiry != null && DateTime.now().isAfter(item.expiry!)) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  // حذف عنصر محدد
  void remove(String key) {
    _cache.remove(key);
  }

  // مسح جميع البيانات
  void clearAll() {
    _cache.clear();
    _products.clear();
    _userProfile = null;
    _categories.clear();
    _locations.clear();
    _weatherData = null;
    _searchResults.clear();
    _toolsData.clear();
    _irrigationSystems.clear();
    _sensorData.clear();
    _dataUpdateController.add('cache_cleared');
  }

  // مسح البيانات المنتهية الصلاحية
  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cache.forEach((key, item) {
      if (item.expiry != null && now.isAfter(item.expiry!)) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  // الحصول على إحصائيات التخزين المؤقت
  Map<String, dynamic> getCacheStats() {
    return {
      'total_cache_items': _cache.length,
      'products_count': _products.length,
      'categories_count': _categories.length,
      'locations_count': _locations.length,
      'has_user_profile': _userProfile != null,
      'has_weather_data': _weatherData != null,
      'search_results_count': _searchResults.length,
      'tools_data_count': _toolsData.length,
      'irrigation_systems_count': _irrigationSystems.length,
      'sensor_data_systems_count': _sensorData.length,
      'is_connected': _isConnected,
    };
  }

  // تشغيل تنظيف دوري للبيانات المنتهية الصلاحية
  void startPeriodicCleanup() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      clearExpired();
    });
  }

  // === طرق التحديث الذكي ===

  // تحديث ذكي للمنتجات - يحدث في الخلفية دون إشعار المستخدم
  void smartUpdateProducts(List<Product> newProducts) {
    if (newProducts.isNotEmpty) {
      // دمج البيانات الجديدة مع القديمة بذكاء
      for (final newProduct in newProducts) {
        // إضافة أو تحديث المنتج في الخريطة
        _products[newProduct.id] = newProduct;
      }

      // حفظ في التخزين المؤقت مع مدة انتهاء طويلة (24 ساعة)
      final productsList = _products.values.toList();
      put('all_products', productsList.map((p) => p.toMap()).toList(),
          expiry: const Duration(hours: 24));
      _dataUpdateController.add('products_updated_silently');
    }
  }

  // تحديث ذكي لبيانات الطقس مع مدة انتهاء طويلة
  void smartUpdateWeather(Map<String, dynamic> newWeatherData) {
    if (newWeatherData.isNotEmpty) {
      _weatherData = Map.from(newWeatherData);
      put('weather_data', newWeatherData, expiry: const Duration(hours: 6));
      _dataUpdateController.add('weather_updated_silently');
    }
  }

  // تحديث ذكي لبيانات المستخدم
  void smartUpdateUserProfile(UserProfile newProfile) {
    _userProfile = newProfile;
    put('user_profile', newProfile.toMap(), expiry: const Duration(days: 7));
    _dataUpdateController.add('profile_updated_silently');
  }

  // تحديث ذكي لأنظمة الري مع مدة انتهاء طويلة
  void smartUpdateIrrigationSystems(List<Map<String, dynamic>> newSystems) {
    if (newSystems.isNotEmpty) {
      // تحديث الذاكرة المحلية
      for (var system in newSystems) {
        _irrigationSystems[system['id'].toString()] = system;
      }

      // حفظ في التخزين المؤقت مع مدة انتهاء طويلة (24 ساعة)
      put('irrigation_systems', newSystems, expiry: const Duration(hours: 24));
      _dataUpdateController.add('irrigation_systems_updated_silently');
    }
  }

  // حفظ المنتجات الأعلى تقييماً
  Future<void> cacheTopRatedProducts(
      List<Map<String, dynamic>> products) async {
    if (products.isNotEmpty) {
      // حفظ في التخزين المؤقت مع مدة انتهاء طويلة (24 ساعة)
      put('top_rated_products', products, expiry: const Duration(hours: 24));
      _dataUpdateController.add('top_rated_products_updated');
    }
  }

  // الحصول على المنتجات الأعلى تقييماً المحفوظة
  List<Map<String, dynamic>> getCachedTopRatedProducts() {
    final cached = get('top_rated_products');
    if (cached != null && cached is List) {
      return List<Map<String, dynamic>>.from(cached);
    }
    return [];
  }

  // فحص ما إذا كانت البيانات تحتاج تحديث عاجل (مدد أطول للتحديث)
  bool needsUrgentUpdate(String dataType) {
    switch (dataType) {
      case 'weather':
        return isDataStale('weather_data', const Duration(hours: 3));
      case 'products':
        return isDataStale('all_products', const Duration(hours: 12));
      case 'profile':
        return isDataStale('user_profile', const Duration(days: 7));
      case 'irrigation':
        return isDataStale('irrigation_systems', const Duration(hours: 12));
      default:
        return false;
    }
  }

  // تنظيف الموارد
  void dispose() {
    _dataUpdateController.close();
  }
}

// فئة لحفظ عنصر في الذاكرة المؤقتة
class CacheItem {
  final dynamic value;
  final DateTime timestamp;
  final DateTime? expiry;

  CacheItem({
    required this.value,
    required this.timestamp,
    this.expiry,
  });

  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry!);
  }
}

// إضافة طرق toMap للنماذج إذا لم تكن موجودة
extension ProductExtension on Product {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'image_urls': imageUrls,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'location': location,
      'profiles': {
        'full_name': sellerName,
        'avatar_url': sellerAvatar,
        'phone_number': sellerPhone,
      },
      'likes_count': likesCount,
      'is_liked': isLiked,
      'average_rating': averageRating,
      'ratings_count': ratingsCount,
    };
  }
}

extension UserProfileExtension on UserProfile {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'location': location,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'whatsapp_number': whatsappNumber,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
