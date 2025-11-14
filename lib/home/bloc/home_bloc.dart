import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:rxdart/rxdart.dart';

import '../../services/supabaseservice.dart';
import '../../services/agricultural_cache_service.dart';
import 'home_event.dart';
import 'home_state.dart';

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
        transformer: _debounce(const Duration(milliseconds: 300)));
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      if (_isConnected && state is HomeError) {
        add(LoadHomeDataEvent());
      }
    });

    _cacheService.dataUpdates.listen((updateType) {
      if (updateType == 'silent_update_started' && _isConnected) {
        _loadAndCacheHomeDataSilently();
      }
    });

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

  EventTransformer<E> _debounce<E>(
      [Duration duration = const Duration(milliseconds: 500)]) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _connectivitySubscription?.cancel();
    EasyDebounce.cancelAll();
    return super.close();
  }

  Future<void> _onLoadHomeData(
      LoadHomeDataEvent event, Emitter<HomeState> emit) async {
    _cacheService.updateConnectionStatus(_isConnected);

    final cachedWeather = _cacheService.getCachedWeatherData();
    final cachedProducts = _cacheService.getCachedProducts();

    if (cachedWeather != null || cachedProducts.isNotEmpty) {
      emit(HomeLoaded());
    }

    if (!_isConnected) {
      if (cachedWeather == null && cachedProducts.isEmpty) {
        emit(HomeLoaded());
      }
      return;
    }

    try {
      await _loadAndCacheHomeDataSilently();
      if (cachedWeather == null && cachedProducts.isEmpty) {
        if (!emit.isDone) emit(HomeLoaded());
      }
    } catch (e) {
      if (cachedWeather == null && cachedProducts.isEmpty) {
        if (!emit.isDone) emit(HomeLoaded());
      }
      debugPrint('خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> _loadAndCacheHomeDataSilently() async {
    try {
      final topProducts = await _supabaseService.getTopRatedProducts(limit: 8);
      if (topProducts.isNotEmpty) {
        await _cacheService.cacheTopRatedProducts(topProducts);
      }
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات للتخزين المؤقت: $e');
      rethrow;
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
