// offline_manager.dart - مدير الوضع غير المتصل للتطبيق الزراعي
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'agricultural_cache_service.dart';
import '../market/market.dart';
import '../profile/profile.dart';

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final AgriculturalCacheService _cacheService = AgriculturalCacheService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  // Stream للإشعار بتغييرات الاتصال
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  AgriculturalCacheService get cacheService => _cacheService;

  // بدء مراقبة الاتصال
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );

    // فحص الحالة الأولية
    _checkInitialConnectivity();

    // بدء التنظيف الدوري
    _cacheService.startPeriodicCleanup();
  }

  // فحص الحالة الأولية للاتصال
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('خطأ في فحص الاتصال الأولي: $e');
    }
  }

  // التعامل مع تغييرات الاتصال
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = !results.contains(ConnectivityResult.none);

    // تحديث حالة الاتصال في خدمة التخزين المؤقت
    _cacheService.updateConnectionStatus(_isConnected);

    // إرسال إشعار إذا تغيرت الحالة
    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);

      if (_isConnected) {
        debugPrint('تم استعادة الاتصال بالإنترنت');
        _onConnectionRestored();
      } else {
        debugPrint('انقطع الاتصال بالإنترنت - التبديل للوضع غير المتصل');
        _onConnectionLost();
      }
    }
  }

  // عند استعادة الاتصال
  void _onConnectionRestored() {
    // يمكن إضافة منطق لتحديث البيانات تلقائياً
    // مثل إعادة تحميل البيانات الحديثة من الخادم
  }

  // عند فقدان الاتصال
  void _onConnectionLost() {
    // يمكن إضافة منطق للتحضير للوضع غير المتصل
    // مثل حفظ البيانات الحالية
  }

  // === طرق مساعدة للشاشات المختلفة ===

  // للشاشة الرئيسية
  bool hasHomeData() {
    final products = _cacheService.getCachedProducts();
    final weather = _cacheService.getCachedWeatherData();
    return products.isNotEmpty || weather != null;
  }

  // للسوق
  bool hasMarketData() {
    final products = _cacheService.getCachedProducts();
    final categories = _cacheService.getCachedCategories();
    return products.isNotEmpty || categories.isNotEmpty;
  }

  // للملف الشخصي
  bool hasProfileData() {
    final profile = _cacheService.getCachedUserProfile();
    return profile != null;
  }

  // === طرق البحث في البيانات المحفوظة ===

  List<Product> searchOfflineProducts(
    String query, {
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) {
    return _cacheService.searchCachedProducts(
      query,
      category: category,
      location: location,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  // === طرق إدارة البيانات ===

  // حفظ بيانات الشاشة الرئيسية
  void cacheHomeData({
    List<Product>? products,
    Map<String, dynamic>? weatherData,
    Map<String, dynamic>? toolsData,
  }) {
    if (products != null && products.isNotEmpty) {
      _cacheService.cacheProducts(products);
    }
    if (weatherData != null) {
      _cacheService.cacheWeatherData(weatherData);
    }
    if (toolsData != null) {
      _cacheService.cacheToolsData(toolsData);
    }
  }

  // حفظ بيانات السوق
  void cacheMarketData({
    List<Product>? products,
    List<String>? categories,
    List<String>? locations,
  }) {
    if (products != null && products.isNotEmpty) {
      _cacheService.cacheProducts(products);
    }
    if (categories != null && categories.isNotEmpty) {
      _cacheService.cacheCategories(categories);
    }
    if (locations != null && locations.isNotEmpty) {
      _cacheService.cacheLocations(locations);
    }
  }

  // حفظ بيانات الملف الشخصي
  void cacheProfileData(UserProfile profile) {
    _cacheService.cacheUserProfile(profile);
  }

  // === طرق استرجاع البيانات ===

  // بيانات الشاشة الرئيسية
  Map<String, dynamic> getHomeData() {
    return {
      'products': _cacheService.getCachedProducts(),
      'weather': _cacheService.getCachedWeatherData(),
      'tools': _cacheService.getCachedToolsData(),
    };
  }

  // بيانات السوق
  Map<String, dynamic> getMarketData() {
    return {
      'products': _cacheService.getCachedProducts(),
      'categories': _cacheService.getCachedCategories(),
      'locations': _cacheService.getCachedLocations(),
    };
  }

  // بيانات الملف الشخصي
  UserProfile? getProfileData() {
    return _cacheService.getCachedUserProfile();
  }

  // === طرق التنظيف ===

  // مسح بيانات شاشة معينة
  void clearScreenData(String screenName) {
    switch (screenName) {
      case 'home':
        _cacheService.remove('weather_data');
        _cacheService.remove('tools_data');
        break;
      case 'market':
        _cacheService.remove('all_products');
        _cacheService.remove('categories');
        _cacheService.remove('locations');
        break;
      case 'profile':
        _cacheService.remove('user_profile');
        break;
    }
  }

  // مسح جميع البيانات
  void clearAllData() {
    _cacheService.clearAll();
  }

  // === طرق الإحصائيات ===

  Map<String, dynamic> getOfflineStats() {
    final stats = _cacheService.getCacheStats();
    return {
      ...stats,
      'connection_status': _isConnected ? 'متصل' : 'غير متصل',
      'has_home_data': hasHomeData(),
      'has_market_data': hasMarketData(),
      'has_profile_data': hasProfileData(),
    };
  }

  // تنظيف الموارد
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
    _cacheService.dispose();
  }
}

// تم إزالة OfflineIndicator لتحسين تجربة المستخدم
// لا نعرض مؤشرات حالة الاتصال للمستخدم بعد الآن

// Mixin للاستخدام في الشاشات
mixin OfflineMixin<T extends StatefulWidget> on State<T> {
  final OfflineManager _offlineManager = OfflineManager();
  late StreamSubscription<bool> _connectionSubscription;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    isConnected = _offlineManager.isConnected;

    _connectionSubscription = _offlineManager.connectionStream.listen(
      (connected) {
        if (mounted) {
          setState(() {
            isConnected = connected;
          });
          onConnectivityChanged(connected);
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  // دالة يمكن تخصيصها في الشاشات
  void onConnectivityChanged(bool isConnected) {
    // يمكن تخصيصها في كل شاشة
  }

  // طرق مساعدة
  OfflineManager get offlineManager => _offlineManager;

  // تم إزالة buildOfflineIndicator لتحسين تجربة المستخدم
  // لا نعرض مؤشرات حالة الاتصال بعد الآن
}
