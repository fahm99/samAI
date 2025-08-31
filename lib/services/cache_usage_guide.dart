// cache_usage_guide.dart - دليل استخدام نظام التخزين المؤقت
// هذا الملف يوضح كيفية استخدام نظام التخزين المؤقت في التطبيق الزراعي

/*
=== نظام التخزين المؤقت للتطبيق الزراعي ===

تم تطبيق نظام شامل للتخزين المؤقت في الذاكرة لتحسين تجربة المستخدم أثناء انقطاع الإنترنت.

=== الملفات المحدثة ===

1. lib/services/agricultural_cache_service.dart
   - خدمة التخزين المؤقت الرئيسية
   - حفظ المنتجات، بيانات المستخدم، الفئات، المواقع، بيانات الطقس
   - البحث في البيانات المحفوظة
   - إدارة انتهاء صلاحية البيانات

2. lib/services/offline_manager.dart
   - مدير الوضع غير المتصل
   - مراقبة حالة الاتصال
   - OfflineMixin للاستخدام في الشاشات
   - OfflineIndicator widget

3. lib/services/connectivity_service.dart
   - خدمة مراقبة الاتصال
   - ConnectivityWrapper widget
   - ConnectivityMixin

=== الشاشات المحدثة ===

1. lib/home/home.dart
   - HomeBloc: إضافة AgriculturalCacheService
   - HomeLoadedOffline state جديدة
   - تحميل وحفظ المنتجات الأعلى تقييماً
   - عرض البيانات المحفوظة عند انقطاع الإنترنت
   - مؤشر الوضع غير المتصل

2. lib/market/market.dart
   - MarketBloc: إضافة AgriculturalCacheService
   - MarketLoadedOffline state جديدة
   - حفظ المنتجات والفئات والمواقع
   - البحث في البيانات المحفوظة
   - مؤشر الوضع غير المتصل

3. lib/profile/profile.dart
   - ProfileBloc: إضافة AgriculturalCacheService
   - حفظ وتحديث بيانات المستخدم
   - تحميل البيانات المحفوظة أولاً

4. lib/main.dart
   - تهيئة OfflineManager

=== كيفية الاستخدام ===

### 1. في الـ BLoC:

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();

  // حفظ البيانات
  void cacheData(List<Product> products) {
    _cacheService.cacheProducts(products);
  }

  // استرجاع البيانات
  List<Product> getCachedData() {
    return _cacheService.getCachedProducts();
  }

  // فحص حالة الاتصال
  bool get isConnected => _cacheService.isConnected;
}
```

### 2. في الشاشات:

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with OfflineMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // مؤشر الوضع غير المتصل
          if (!isConnected) buildOfflineIndicator(),
          
          // المحتوى الرئيسي
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  @override
  void onConnectivityChanged(bool isConnected) {
    // تخصيص سلوك تغيير الاتصال
    if (isConnected) {
      // تحديث البيانات عند عودة الاتصال
      _refreshData();
    }
  }
}
```

### 3. حفظ البيانات:

```dart
// حفظ المنتجات
final products = await _supabaseService.getProducts();
_cacheService.cacheProducts(products.map((p) => Product.fromMap(p)).toList());

// حفظ بيانات المستخدم
final userProfile = await _supabaseService.getUserProfile(userId);
_cacheService.cacheUserProfile(UserProfile.fromMap(userProfile));

// حفظ الفئات
final categories = await _supabaseService.getCategories();
_cacheService.cacheCategories(categories);
```

### 4. استرجاع البيانات:

```dart
// استرجاع المنتجات
final cachedProducts = _cacheService.getCachedProducts();

// البحث في البيانات المحفوظة
final searchResults = _cacheService.searchCachedProducts(
  'طماطم',
  category: 'خضروات',
  location: 'صنعاء',
  minPrice: 10.0,
  maxPrice: 100.0,
);

// استرجاع بيانات المستخدم
final userProfile = _cacheService.getCachedUserProfile();
```

### 5. إدارة الحالات:

```dart
// في الـ BLoC
Future<void> _onLoadData(LoadDataEvent event, Emitter<MyState> emit) async {
  // فحص الاتصال
  if (!_cacheService.isConnected) {
    final cachedData = _cacheService.getCachedProducts();
    if (cachedData.isNotEmpty) {
      emit(MyLoadedOffline(data: cachedData));
      return;
    } else {
      emit(MyError(message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'));
      return;
    }
  }

  emit(MyLoading());
  
  try {
    final data = await _loadDataFromServer();
    // حفظ البيانات
    _cacheService.cacheProducts(data);
    emit(MyLoaded(data: data));
  } catch (e) {
    // في حالة الخطأ، جرب البيانات المحفوظة
    final cachedData = _cacheService.getCachedProducts();
    if (cachedData.isNotEmpty) {
      emit(MyLoadedOffline(data: cachedData));
    } else {
      emit(MyError(message: 'خطأ في تحميل البيانات'));
    }
  }
}
```

=== المزايا ===

1. **تجربة مستخدم محسنة**: عرض البيانات المحفوظة بدلاً من رسائل الخطأ
2. **سرعة في التحميل**: البيانات متاحة فوراً من الذاكرة
3. **توفير البيانات**: تقليل استهلاك الإنترنت
4. **مرونة في الاستخدام**: نظام موحد لجميع الشاشات
5. **إدارة ذكية للذاكرة**: تنظيف دوري للبيانات المنتهية الصلاحية

=== الإعدادات ===

- مدة صلاحية المنتجات: 30 دقيقة
- مدة صلاحية بيانات المستخدم: ساعتان
- مدة صلاحية الفئات والمواقع: 6 ساعات
- مدة صلاحية بيانات الطقس: 15 دقيقة
- تنظيف دوري كل 5 دقائق

=== ملاحظات مهمة ===

1. البيانات تُفقد عند إغلاق التطبيق (تخزين في الذاكرة فقط)
2. لا تحفظ كلمات المرور أو البيانات الحساسة
3. يتم تحديث البيانات تلقائياً عند عودة الاتصال
4. مؤشر بصري واضح للوضع غير المتصل
5. رسائل خطأ باللغة العربية مع اقتراحات عملية

=== التطوير المستقبلي ===

يمكن إضافة:
- تخزين دائم باستخدام SQLite
- ضغط البيانات لتوفير الذاكرة
- مزامنة ذكية للبيانات
- إعدادات مخصصة لمدة الصلاحية
- إحصائيات استخدام التخزين المؤقت

*/
