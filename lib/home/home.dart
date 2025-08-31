// home.dart - محسن للأداء وتجربة المستخدم
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart'; // لدعم Debounce في Bloc
import 'package:sam/market/Product_Details.dart';
import 'package:sam/market/market.dart';
import 'package:sam/toolsscreens/ExpertConsultationPage%20.dart';
import 'package:sam/toolsscreens/FertilizerCalculator.dart';
import 'package:sam/toolsscreens/PricePredictionPage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_debounce/easy_debounce.dart';
import '../services/supabaseservice.dart';
import '../services/agricultural_cache_service.dart';
import '../services/offline_manager.dart';
import '../widgets/weather_card.dart';

// Home Models
class SensorReading extends Equatable {
  final String name;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const SensorReading({
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  List<Object> get props => [name, value, unit, icon, color];
}

class AlertItem extends Equatable {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final String type;

  const AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  List<Object> get props => [id, title, message, time, icon, color, type];
}

// Home Events
abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class RefreshSensorDataEvent extends HomeEvent {}

class RefreshSensorReadingsOnlyEvent extends HomeEvent {} // جديد

class MarkNotificationAsReadEvent extends HomeEvent {
  final String notificationId;
  MarkNotificationAsReadEvent({required this.notificationId});
  @override
  List<Object> get props => [notificationId];
}

// Home States
abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoaded extends HomeState {
  HomeLoaded();

  @override
  List<Object> get props => [];
}

// تم إزالة HomeLoadedOffline لتبسيط تجربة المستخدم

class HomeError extends HomeState {
  final String message;

  HomeError({required this.message});

  @override
  List<Object> get props => [message];
}

// Home Bloc - محسن مع التخزين المؤقت
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  late final SupabaseService _supabaseService = SupabaseService();
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();
  Timer? _pollingTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData, transformer: _debounce());
    on<RefreshSensorDataEvent>(_onRefreshSensorData, transformer: _debounce());
    on<RefreshSensorReadingsOnlyEvent>(_onRefreshSensorReadingsOnly,
        transformer: _debounce(
            const Duration(milliseconds: 300))); // Reduced debounce for sensors
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);

    // Monitor network connectivity
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      if (_isConnected && state is HomeError) {
        // Retry loading data when connection is restored
        add(LoadHomeDataEvent());
      }
    });

    // الاستماع للتحديثات الخفية من خدمة التخزين المؤقت
    _cacheService.dataUpdates.listen((updateType) {
      if (updateType == 'silent_update_started' && _isConnected) {
        // تحديث خفي في الخلفية دون إشعار المستخدم
        _loadAndCacheHomeDataSilently();
      }
    });

    // Optimized sensor polling - only when connected and app is active
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      if (_isConnected && state is HomeLoaded) {
        add(RefreshSensorReadingsOnlyEvent());
      }
    });
  }

  // Optimized debounce transformer
  EventTransformer<E> _debounce<E>(
      [Duration duration = const Duration(milliseconds: 500)]) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _connectivitySubscription?.cancel();
    EasyDebounce.cancelAll(); // Cancel any pending debounced operations
    return super.close();
  }

  Future<void> _onLoadHomeData(
      LoadHomeDataEvent event, Emitter<HomeState> emit) async {
    // تحديث حالة الاتصال في الخدمة
    _cacheService.updateConnectionStatus(_isConnected);

    // أولاً، عرض البيانات المحفوظة إن وجدت (للاستجابة السريعة)
    final cachedWeather = _cacheService.getCachedWeatherData();
    final cachedProducts = _cacheService.getCachedProducts();

    // عرض البيانات المحفوظة فوراً إذا وجدت
    if (cachedWeather != null || cachedProducts.isNotEmpty) {
      emit(HomeLoaded());
    }

    // إذا لم يكن هناك اتصال، اكتفِ بالبيانات المحفوظة
    if (!_isConnected) {
      if (cachedWeather == null && cachedProducts.isEmpty) {
        // عرض شاشة فارغة بدلاً من رسالة خطأ
        emit(HomeLoaded());
      }
      return;
    }

    // التحديث الخفي في الخلفية (بدون إظهار loading للمستخدم)
    try {
      await _loadAndCacheHomeDataSilently();
      // إذا لم تكن هناك بيانات محفوظة من قبل، عرض البيانات الجديدة
      if (cachedWeather == null && cachedProducts.isEmpty) {
        if (!emit.isDone) emit(HomeLoaded());
      }
    } catch (e) {
      // في حالة الخطأ، إذا لم تكن هناك بيانات محفوظة، عرض شاشة فارغة
      if (cachedWeather == null && cachedProducts.isEmpty) {
        if (!emit.isDone) emit(HomeLoaded());
      }
      // تسجيل الخطأ فقط دون إظهاره للمستخدم
      debugPrint('خطأ في تحميل البيانات: $e');
    }
  }

  // دالة لتحميل البيانات وحفظها في التخزين المؤقت بشكل خفي
  Future<void> _loadAndCacheHomeDataSilently() async {
    try {
      // تحميل المنتجات الأعلى تقييماً وحفظها
      final topProducts = await _supabaseService.getTopRatedProducts(limit: 8);
      if (topProducts.isNotEmpty) {
        // حفظ المنتجات الأعلى تقييماً مباشرة كـ Map
        await _cacheService.cacheTopRatedProducts(topProducts);
      }

      // لا نحتاج لإضافة حدث جديد هنا لتجنب الحلقة اللا نهائية
      // البيانات محفوظة الآن ويمكن الوصول إليها من التخزين المؤقت
    } catch (e) {
      // في حالة فشل التحميل، لا نرمي خطأ بل نتجاهل
      debugPrint('خطأ في تحميل البيانات للتخزين المؤقت: $e');
      rethrow; // إعادة رمي الخطأ ليتم التعامل معه في المستوى الأعلى
    }
  }

  Future<void> _onRefreshSensorData(
      RefreshSensorDataEvent event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      add(LoadHomeDataEvent());
    }
  }

  Future<void> _onRefreshSensorReadingsOnly(
      RefreshSensorReadingsOnlyEvent event, Emitter<HomeState> emit) async {
    // لا حاجة لهذه الدالة في التصميم الجديد
  }

  Future<void> _onMarkNotificationAsRead(
      MarkNotificationAsReadEvent event, Emitter<HomeState> emit) async {
    // لا حاجة لهذه الدالة في التصميم الجديد
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, OfflineMixin {
  // تحسين الأداء: إضافة AnimationController للانتقالات السلسة
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // تهيئة الرسوم المتحركة
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // تحميل البيانات بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(LoadHomeDataEvent());
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          if (state is HomeLoaded) {
            return FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  // تحسين UX: إضافة التحديث بالسحب
                  onRefresh: () async {
                    // تحسين الأداء: استخدام EasyDebounce لمنع الطلبات السريعة المتتالية
                    EasyDebounce.debounce(
                      'home-refresh',
                      const Duration(milliseconds: 1000),
                      () => context
                          .read<HomeBloc>()
                          .add(RefreshSensorDataEvent()),
                    );
                  },
                  child: Column(
                    children: [
                      // تم إزالة مؤشر حالة الاتصال لتحسين تجربة المستخدم

                      Expanded(
                        child: SingleChildScrollView(
                          physics:
                              const AlwaysScrollableScrollPhysics(), // للسماح بالتحديث حتى لو كان المحتوى قصير
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // بطاقة الطقس الذكية
                              const RepaintBoundary(child: WeatherCard()),
                              const SizedBox(height: 16),
                              // شريط الأدوات الأفقي الجديد
                              RepaintBoundary(child: _buildToolsSection(context)),
                              const SizedBox(height: 16),
                              // قسم أفضل المنتجات تقييماً
                              RepaintBoundary(
                                  child: _buildTopRatedProductsSection()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
          }
          // عرض المحتوى دائماً حتى لو لم تكن هناك بيانات
          return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  EasyDebounce.debounce(
                    'home-refresh',
                    const Duration(milliseconds: 1000),
                    () =>
                        context.read<HomeBloc>().add(RefreshSensorDataEvent()),
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const RepaintBoundary(child: WeatherCard()),
                            const SizedBox(height: 16),
                            RepaintBoundary(child: _buildToolsSection(context)),
                            const SizedBox(height: 16),
                            RepaintBoundary(
                                child: _buildTopRatedProductsSection()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }
// شريط الأدوات الأفقي المعدل مع دعم التنقل
Widget _buildToolsSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.build, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text(
              'الأدوات الزراعية الذكية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  icon: Icons.calculate,
                  label: 'حاسبة الأسمدة',
                  iconColor: const Color(0xFF4CAF50),
                  onTap: () {
                    // التنقل إلى الصفحة الحالية (هذه الصفحة نفسها)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FertilizerCalculator()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  icon: Icons.support_agent,
                  label: 'استشارة خبير',
                  iconColor: const Color(0xFF2196F3),
                  onTap: () {
                    // التنقل إلى صفحة استشارة الخبراء
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExpertConsultationPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  icon: Icons.attach_money,
                  label: 'تسعير المنتج',
                  iconColor: const Color(0xFFFF9800),
                  onTap: () {
                    // التنقل إلى صفحة تسعير المنتج
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PricePredictionPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToolCard(
                  icon: Icons.eco,
                  label: 'اختر محصولك',
                  iconColor: const Color(0xFF9C27B0),
                  onTap: () => _showComingSoonDialog('اختيار المحصول المناسب'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: iconColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.15),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconColor.withOpacity(0.08),
                iconColor.withOpacity(0.12),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String serviceName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('قريباً'),
          content: Text('سيتم إضافة خدمة "$serviceName" قريباً'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  // قسم أفضل المنتجات تقييماً
  Widget _buildTopRatedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFF9800)),
              const SizedBox(width: 8),
              const Text(
                'أعلى المنتجات تقييماً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MarketScreen()),
                  );
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              // محاولة عرض البيانات المحفوظة أولاً
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getTopRatedProductsWithCache(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildTopRatedShimmer();
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount:
                          snapshot.data!.length > 8 ? 8 : snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final product = snapshot.data![index];
                        return _buildTopRatedProductCard(product);
                      },
                    );
                  } else {
                    return _buildEmptyTopRated();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // دوال مساعدة لقسم أفضل المنتجات تقييماً
  Future<List<Map<String, dynamic>>> _getTopRatedProductsWithCache() async {
    // أولاً، عرض البيانات المحفوظة إن وجدت
    final cachedTopRated =
        AgriculturalCacheService().getCachedTopRatedProducts();
    if (cachedTopRated.isNotEmpty) {
      // تحديث خفي في الخلفية
      _updateTopRatedProductsSilently();
      return cachedTopRated.take(8).toList();
    }

    try {
      // محاولة جلب البيانات من قاعدة البيانات
      final products = await SupabaseService().getTopRatedProducts(limit: 8);
      if (products.isNotEmpty) {
        // حفظ البيانات الجديدة
        await AgriculturalCacheService().cacheTopRatedProducts(products);
        return products;
      }

      // في حالة عدم وجود منتجات مقيمة، جلب المنتجات العادية
      final regularProducts =
          await SupabaseService().getMarketProducts(limit: 8);
      return regularProducts;
    } catch (e) {
      debugPrint('Error getting top rated products: $e');

      // في حالة الخطأ، محاولة استخدام المنتجات العادية المحفوظة
      final cachedProducts = AgriculturalCacheService().getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        return cachedProducts
            .take(8)
            .map((product) => product.toMap())
            .toList();
      }

      return [];
    }
  }

  // تحديث خفي للمنتجات الأعلى تقييماً
  Future<void> _updateTopRatedProductsSilently() async {
    try {
      final products = await SupabaseService().getTopRatedProducts(limit: 8);
      if (products.isNotEmpty) {
        await AgriculturalCacheService().cacheTopRatedProducts(products);
      }
    } catch (e) {
      debugPrint('خطأ في التحديث الخفي للمنتجات الأعلى تقييماً: $e');
    }
  }

  Widget _buildTopRatedShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(left: 12),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).dividerColor.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.2),
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor.withOpacity(0.8)
                : Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTopRated() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline,
              size: 32, color: Theme.of(context).disabledColor),
          const SizedBox(height: 8),
          Text(
            'لا توجد منتجات مقيمة بعد',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRatedProductCard(Map<String, dynamic> product) {
    final imageUrls = List<String>.from(product['image_urls'] ?? []);
    final averageRating = (product['average_rating'] ?? 0.0) as double;
    final ratingsCount = (product['ratings_count'] ?? 0) as int;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(productId: product['id']),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrls.isNotEmpty
                      ? Image.network(
                          imageUrls.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.3),
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                          child: const Icon(Icons.image, size: 32),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 12),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${averageRating.toStringAsFixed(1)} ($ratingsCount)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(product['price'] ?? 0).toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () => _showContactDialog(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'تواصل الآن',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(Map<String, dynamic> product) {
    final seller = product['profiles'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تواصل مع البائع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المنتج: ${product['name']}'),
              const SizedBox(height: 8),
              Text('البائع: ${seller?['full_name'] ?? 'غير محدد'}'),
              const SizedBox(height: 8),
              Text('الهاتف: ${seller?['phone_number'] ?? 'غير متوفر'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // يمكن إضافة منطق الاتصال هنا
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم إضافة ميزة الاتصال المباشر قريباً'),
                  ),
                );
              },
              child: const Text('اتصال'),
            ),
          ],
        );
      },
    );
  }
}
