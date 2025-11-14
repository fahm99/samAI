import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🔧 للتحقق من release mode
import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:sam/market/screens/add_product_screen.dart'; // سيتم استخدام market/market.dart
import 'market/market.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import "package:flutter_localizations/flutter_localizations.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io'; // 🔧 لتحسين إعدادات الشبكة

import 'auth/auth.dart';
import 'home/home.dart';
import 'irregation/irrigation.dart';
import 'plantdisease/plant_disease_api.dart';
import 'profile/profile.dart';
import 'setting/settings.dart';
import 'services/supabaseservice.dart';
import 'services/offline_manager.dart';
import 'theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utlits/responsive_utils.dart';

import 'services/connection_service.dart';
// import 'services/logger_service.dart';
// تم دمجه في market/market.dart

// 🚀 دالة تحسين إعدادات الذاكرة والأداء
Future<void> _optimizeMemorySettings() async {
  // تحسين إعدادات HTTP للشبكة
  HttpOverrides.global = _CustomHttpOverrides();

  // تحسين الأداء في release mode
  if (kReleaseMode) {
    // تقليل استهلاك الذاكرة عبر تعطيل debug prints
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}

// 🔧 تحسين إعدادات HTTP للأداء
class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // تحسين إعدادات الاتصال
    client.connectionTimeout = const Duration(seconds: 10);
    client.idleTimeout = const Duration(seconds: 15);
    // تفعيل ضغط البيانات
    client.autoUncompress = true;
    return client;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 تحسين الأداء: تعطيل debug في الإنتاج وتحسين الذاكرة
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // 🧹 تنظيف الذاكرة: تحسين Garbage Collection
  await _optimizeMemorySettings();

  // 📝 تهيئة خدمة التسجيل
  // logger.initialize(); // سيتم تفعيله لاحقاً

  try {
    // 💾 Session persistence محسن: تحقق من وجود جلسة مستخدم محفوظة
    final prefs = await SharedPreferences.getInstance();
    final savedSession = prefs.getString('user_session');

    // 🔗 Initialize Supabase مع إعدادات محسنة للأداء
    await Supabase.initialize(
      url: 'https://gwpwvhkcvkfmxodblnll.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3cHd2aGtjdmtmbXhvZGJsbmxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMDY1ODksImV4cCI6MjA2Njg4MjU4OX0.wFyQYDuaUDickuYpqTGHXSZvlOwLCpX2-QVuEgWWrNM',
      debug: kDebugMode,

      // 🔧 تهيئة مدير الوضع غير المتصل
      // OfflineManager().initialize(), // سيتم تهيئته بعد Supabase
      // 🔧 إعدادات محسنة للأداء
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );

    // تهيئة مدير الوضع غير المتصل
    OfflineManager().initialize();

    // تهيئة خدمة الاتصال
    ConnectionService().startMonitoring();

    // ErrorWidget محسن: عرض رسالة ودية مع إمكانية إعادة المحاولة
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red, // استخدام لون ثابت هنا لأن context غير متاح
              ),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ غير متوقع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى إعادة تشغيل التطبيق أو المحاولة لاحقاً',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // إعادة تشغيل التطبيق
                  runApp(MyApp(savedSession: savedSession));
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    };

    runApp(MyApp(savedSession: savedSession));
  } catch (e) {
    // معالجة أخطاء التهيئة
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'فشل في تهيئة التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('خطأ: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String? savedSession;
  const MyApp({super.key, this.savedSession});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // تحسين الأداء: إنشاء BLoCs بشكل lazy
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
          lazy: false, // AuthBloc يحتاج للتحميل فوراً
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(LoadThemeEvent()),
          lazy: false, // ThemeBloc يحتاج للتحميل فوراً
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(),
          lazy: true, // تحميل عند الحاجة
        ),
        BlocProvider<IrrigationBloc>(
          create: (context) => IrrigationBloc(),
          lazy: true, // تحميل عند الحاجة
        ),
        BlocProvider<PlantDiseaseApiBloc>(
          create: (context) => PlantDiseaseApiBloc(SupabaseService()),
          lazy: true, // تحميل عند الحاجة
        ),
        BlocProvider<MarketBloc>(
          create: (context) => MarketBloc(),
          lazy: true, // تحميل عند الحاجة
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(),
          lazy: true, // تحميل عند الحاجة
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
          lazy: true, // تحميل عند الحاجة
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return ScreenUtilInit(
            // تحديد أبعاد التصميم المرجعية (iPhone 14 Pro)
            designSize: const Size(393, 852),
            // دعم الاتجاهات المختلفة
            splitScreenMode: true,
            // الحد الأدنى لحجم النص
            minTextAdapt: true,
            builder: (context, child) {
              // إعداد مفتاح التنقل العام لخدمة الاتصال
              final navigatorKey = GlobalKey<NavigatorState>();
              ConnectionService.navigatorKey = navigatorKey;

              return MaterialApp(
                navigatorKey: navigatorKey,
                title: 'SamAI المزارع الذكي',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState is ThemeLoaded
                    ? (themeState).isDarkMode
                        ? ThemeMode.dark
                        : ThemeMode.light
                    : ThemeMode.light,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ar', ''),
                ],
                locale: const Locale('ar'),
                builder: (context, child) {
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  );
                },
                home: const AuthChecker(),
              );
            },
          );
        },
      ),
    );
  }
}

// محسن: Widget للتحقق من المصادقة مع شاشة تحميل
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // التحقق الفوري من حالة المصادقة بدون تأخير
    if (mounted) {
      context.read<AuthBloc>().add(CheckAuthEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // التوجيه الفوري حسب حالة المصادقة بدون شاشة تحميل
        if (authState is AuthAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  int _currentIndex = 0;

  // استخدم late final و PageStorageKey للاحتفاظ بالحالة
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _bottomNavItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      const HomeScreen(key: PageStorageKey('home')),
      const IrrigationScreen(), // إزالة key لأن الشاشة لا تدعمه
      const PlantDiseaseApiScreen(key: PageStorageKey('disease')),
      const MarketScreen(), // إزالة key
      const ProfileScreen(), // إزالة key
    ];
    _bottomNavItems = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'الرئيسية',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.water_drop),
        label: 'الري',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.eco),
        label: 'الأمراض',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store),
        label: 'السوق',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'الملف',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin

    return SafeArea(
      child: Scaffold(
        appBar: _buildResponsiveAppBar(context),
        body: _buildResponsiveBody(context),
        bottomNavigationBar: _buildResponsiveBottomNav(context),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// بناء AppBar متجاوب
  PreferredSizeWidget _buildResponsiveAppBar(BuildContext context) {
    return AppBar(
      // ارتفاع متجاوب للـ AppBar
      toolbarHeight: ResponsiveUtils.isMobile(context) ? 56.h : 64.h,
      title: Row(
        children: [
          // شعار التطبيق متجاوب
          Container(
            width: ResponsiveUtils.getIconSize(context, IconSizeType.large),
            height: ResponsiveUtils.getIconSize(context, IconSizeType.large),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(
                    context, BorderRadiusType.small),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(
                    context, BorderRadiusType.small),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(
                            context, BorderRadiusType.small),
                      ),
                    ),
                    child: Icon(
                      Icons.eco,
                      size: ResponsiveUtils.getIconSize(
                          context, IconSizeType.medium),
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
              width: ResponsiveUtils.getSpacing(context, SpacingType.small)),
          Expanded(
            child: Text(
              'المزارع الذكي SamAI',
              style: TextStyle(
                fontSize:
                    ResponsiveUtils.getFontSize(context, FontSizeType.title),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            // استخدم ValueListenableBuilder أو BlocBuilder لعدد الإشعارات
            Positioned(
              right: 8,
              top: 8,
              child: ValueListenableBuilder<int>(
                valueListenable: notificationCount,
                builder: (context, count, _) {
                  if (count == 0) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SettingsScreen()), // إزالة const
            );
          },
        ),
      ],
    );
  }

  /// بناء الجسم المتجاوب
  Widget _buildResponsiveBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // للأجهزة الكبيرة، استخدم تخطيط جانبي
        if (ResponsiveUtils.isDesktop(context)) {
          return Row(
            children: [
              // شريط التنقل الجانبي للأجهزة الكبيرة
              Container(
                width: 250.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: _buildSideNavigation(context),
              ),
              // المحتوى الرئيسي
              Expanded(
                child: _screens[_currentIndex],
              ),
            ],
          );
        } else {
          // للهواتف والتابلت، استخدم PageView
          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _screens,
          );
        }
      },
    );
  }

  /// بناء شريط التنقل السفلي المتجاوب
  Widget? _buildResponsiveBottomNav(BuildContext context) {
    // إخفاء شريط التنقل السفلي للأجهزة الكبيرة
    if (ResponsiveUtils.isDesktop(context)) {
      return null;
    }

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        _navigateToPage(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor:
          Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
      // حجم خط متجاوب
      selectedFontSize:
          ResponsiveUtils.getFontSize(context, FontSizeType.small),
      unselectedFontSize:
          ResponsiveUtils.getFontSize(context, FontSizeType.small),
      // ارتفاع متجاوب
      iconSize: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
      items: _bottomNavItems,
    );
  }

  /// بناء التنقل الجانبي للأجهزة الكبيرة
  Widget _buildSideNavigation(BuildContext context) {
    return Column(
      children: [
        // رأس التنقل الجانبي
        Container(
          padding: ResponsiveUtils.getPadding(context, PaddingType.medium),
          child: Column(
            children: [
              // شعار التطبيق
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getBorderRadius(
                        context, BorderRadiusType.medium),
                  ),
                ),
                child: Icon(
                  Icons.eco,
                  size:
                      ResponsiveUtils.getIconSize(context, IconSizeType.large),
                  color: Colors.white,
                ),
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.getSpacing(context, SpacingType.small)),
              Text(
                'حصاد',
                style: TextStyle(
                  fontSize:
                      ResponsiveUtils.getFontSize(context, FontSizeType.medium),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Divider(),
        // عناصر التنقل
        Expanded(
          child: ListView.builder(
            itemCount: _bottomNavItems.length,
            itemBuilder: (context, index) {
              final item = _bottomNavItems[index];
              final isSelected = _currentIndex == index;

              return Container(
                margin: ResponsiveUtils.getPadding(context, PaddingType.small),
                child: ListTile(
                  leading: Icon(
                    item.icon as IconData,
                    color:
                        isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                    size: ResponsiveUtils.getIconSize(
                        context, IconSizeType.medium),
                  ),
                  title: Text(
                    item.label!,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(
                          context, FontSizeType.medium),
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(
                          context, BorderRadiusType.medium),
                    ),
                  ),
                  onTap: () {
                    _navigateToPage(index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // دالة التنقل المحسنة بدون تحديث تلقائي
  void _navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
    });

    // التنقل للصفحة في PageView (للهواتف والتابلت)
    if (!ResponsiveUtils.isDesktop(context)) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 1:
        return null; // إزالة الزر العائم من شاشة الري
      case 2:
        return null;
      case 3:
        return FloatingActionButton(
          onPressed: () => _showAddProductDialog(),
          backgroundColor: const Color(0xFF2E7D32),
          child: const Icon(Icons.add),
        );
      case 4:
        return null;
      default:
        return null;
    }
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(), // إزالة const
      ),
    );
  }
}

// إشعار بعدد الإشعارات (يمكن ربطه مع Bloc أو Stream)
final ValueNotifier<int> notificationCount =
    ValueNotifier<int>(3); // مثال ثابت، اربطه مع Bloc لاحقًا

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: ListView(
        children: const [
          NotificationItem(
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'تم بدء الري التلقائي في حقل الطماطم',
            time: 'منذ 30 دقيقة',
          ),
          NotificationItem(
            icon: Icons.warning,
            iconColor: Colors.orange,
            title: 'انخفاض منسوب المياه في الخزان 2',
            time: 'منذ ساعتين',
          ),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(time),
    );
  }
}

// Placeholder dialog for adding products
class AddProductDialog extends StatelessWidget {
  const AddProductDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة منتج جديد'),
      content: const Text('سيتم فتح نموذج إضافة منتج جديد'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
