// connection_service.dart - خدمة إدارة الاتصال والإشعارات
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  // Stream للاستماع لحالة الاتصال
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // حالة الاتصال الحالية
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // تم إزالة متغيرات الإشعارات

  // مفتاح التطبيق العام للوصول للـ context
  static GlobalKey<NavigatorState>? navigatorKey;

  // بدء مراقبة الاتصال
  void startMonitoring() {
    // التحقق من الحالة الأولية
    _checkInitialConnection();

    // الاستماع للتغييرات
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _isConnected = !results.contains(ConnectivityResult.none);

      // إرسال التحديث فقط - بدون إشعارات
      _connectionStatusController.add(_isConnected);
    });
  }

  // التحقق من الحالة الأولية للاتصال
  Future<void> _checkInitialConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isConnected = !connectivityResult.contains(ConnectivityResult.none);
      _connectionStatusController.add(_isConnected);
    } catch (e) {
      debugPrint('خطأ في التحقق من الاتصال: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }

  // تم إزالة إشعارات فقدان الاتصال لتحسين تجربة المستخدم

  // تم إزالة إشعارات استعادة الاتصال لتحسين تجربة المستخدم

  // تم إزالة دالة إزالة الإشعارات

  // تنظيف الموارد
  void dispose() {
    _connectionStatusController.close();
  }
}
