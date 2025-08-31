// connectivity_service.dart - خدمة مراقبة الاتصال
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'agricultural_cache_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  // Stream للإشعار بتغييرات الاتصال
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  // بدء مراقبة الاتصال
  void startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );

    // فحص الحالة الأولية
    _checkInitialConnectivity();
  }

  // فحص الحالة الأولية للاتصال
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      print('خطأ في فحص الاتصال الأولي: $e');
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
        print('تم استعادة الاتصال بالإنترنت');
        _onConnectionRestored();
      } else {
        print('انقطع الاتصال بالإنترنت - التبديل للوضع غير المتصل');
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

  // فحص الاتصال مع خادم محدد
  Future<bool> checkInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      print('خطأ في فحص الاتصال: $e');
      return false;
    }
  }

  // إيقاف مراقبة الاتصال
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // تنظيف الموارد
  void dispose() {
    stopMonitoring();
    _connectionController.close();
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showOfflineIndicator;

  const ConnectivityWrapper({
    Key? key,
    required this.child,
    this.offlineWidget,
    this.showOfflineIndicator = true,
  }) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<bool> _connectionSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;
    _connectivityService.startMonitoring();

    _connectionSubscription = _connectivityService.connectionStream.listen(
      (isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.offlineWidget != null) {
      return widget.offlineWidget!;
    }

    return Column(
      children: [
        // مؤشر عدم الاتصال
        if (!_isConnected && widget.showOfflineIndicator)
          _buildOfflineIndicator(),

        // المحتوى الرئيسي
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'وضع عدم الاتصال - عرض البيانات المحفوظة',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.cached,
            color: Colors.orange.shade700,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// Mixin للاستخدام في الشاشات
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<bool> _connectionSubscription;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    isConnected = _connectivityService.isConnected;
    _connectivityService.startMonitoring();

    _connectionSubscription = _connectivityService.connectionStream.listen(
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
}
