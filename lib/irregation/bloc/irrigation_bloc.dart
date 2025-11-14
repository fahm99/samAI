import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:rxdart/rxdart.dart';

import '../../services/supabaseservice.dart';
import '../../services/agricultural_cache_service.dart';
import '../models/irrigation_system.dart';
import '../models/sensor_data.dart';
import '../models/irrigation_log.dart';
import 'irrigation_event.dart';
import 'irrigation_state.dart';

class IrrigationBloc extends Bloc<IrrigationEvent, IrrigationState> {
  final SupabaseService _supabaseService = SupabaseService();
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();
  bool _isRefreshing = false;
  Timer? _sensorUpdateTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  IrrigationBloc() : super(IrrigationInitial()) {
    on<LoadIrrigationSystemsEvent>(_onLoadIrrigationSystems);
    on<LoadSystemDetailsEvent>(_onLoadSystemDetails);
    on<ToggleSystemEvent>(_onToggleSystem, transformer: _debounceTransformer());
    on<StartManualIrrigationEvent>(_onStartManualIrrigation,
        transformer: _debounceTransformer());
    on<StopIrrigationEvent>(_onStopIrrigation,
        transformer: _debounceTransformer());
    on<AddSystemEvent>(_onAddSystem);
    on<LinkDeviceEvent>(_onLinkDevice);
    on<DeleteSystemEvent>(_onDeleteSystem);
    on<RefreshSensorDataEvent>(_onRefreshSensorData,
        transformer: _debounceTransformer());
    on<SetAutoIrrigationEvent>(_onSetAutoIrrigation);
    on<UpdateAutoIrrigationSettingsEvent>(_onUpdateAutoIrrigationSettings);
    on<ClearIrrigationLogsEvent>(_onClearIrrigationLogs);

    // Monitor network connectivity
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      if (_isConnected && state is IrrigationError) {
        add(LoadIrrigationSystemsEvent());
      }
    });

    _startSensorUpdates();
  }

  EventTransformer<T> _debounceTransformer<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 500))
        .asyncExpand(mapper);
  }

  void _startSensorUpdates() {
    _sensorUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      if (_isConnected && state is IrrigationSystemsLoaded) {
        final currentState = state as IrrigationSystemsLoaded;
        for (final system in currentState.systems) {
          if (system.isActive) {
            add(RefreshSensorDataEvent(systemId: system.id));
          }
        }
      }
    });
  }

  @override
  Future<void> close() {
    _sensorUpdateTimer?.cancel();
    _connectivitySubscription?.cancel();
    EasyDebounce.cancelAll();
    return super.close();
  }

  Future<void> _onLoadIrrigationSystems(
      LoadIrrigationSystemsEvent event, Emitter<IrrigationState> emit) async {
    _cacheService.updateConnectionStatus(_isConnected);

    if (!_isConnected) {
      final cachedSystems = _cacheService.getCachedIrrigationSystems();
      if (cachedSystems.isNotEmpty) {
        final systems = cachedSystems
            .map((data) => IrrigationSystem.fromMap(data))
            .toList();
        emit(IrrigationSystemsLoaded(systems: systems));
        return;
      } else {
        emit(IrrigationError(
            message:
                'لا يوجد اتصال بالإنترنت ولا توجد أنظمة ري محفوظة مسبقاً'));
        return;
      }
    }

    emit(IrrigationLoading());

    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(IrrigationError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final systemsData = await _supabaseService
          .getIrrigationSystems(currentUser.id)
          .timeout(const Duration(seconds: 15));

      if (systemsData.isNotEmpty) {
        _cacheService.cacheIrrigationSystems(systemsData);
      }

      final systems =
          systemsData.map((data) => IrrigationSystem.fromMap(data)).toList();
      emit(IrrigationSystemsLoaded(systems: systems));
    } catch (e) {
      final cachedSystems = _cacheService.getCachedIrrigationSystems();
      if (cachedSystems.isNotEmpty) {
        final systems = cachedSystems
            .map((data) => IrrigationSystem.fromMap(data))
            .toList();
        emit(IrrigationSystemsLoaded(systems: systems));
      } else {
        emit(IrrigationError(message: _getErrorMessage(e)));
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مجددًا.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
    } else if (error.toString().contains('unauthorized') ||
        error.toString().contains('401')) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.';
    } else {
      return 'خطأ في تحميل أنظمة الري. يرجى المحاولة مجددًا.';
    }
  }

  Future<void> _onLoadSystemDetails(
      LoadSystemDetailsEvent event, Emitter<IrrigationState> emit) async {
    if (!_isConnected) {
      final cachedSystem =
          _cacheService.getCachedIrrigationSystem(event.systemId);
      final cachedSensorData =
          _cacheService.getCachedSensorData(event.systemId);

      if (cachedSystem != null) {
        final system = IrrigationSystem.fromMap(cachedSystem);
        final sensorData =
            cachedSensorData.map((data) => SensorData.fromMap(data)).toList();

        emit(SystemDetailsLoaded(
          system: system,
          sensorData: sensorData,
          irrigationLogs: const [],
        ));
        return;
      } else {
        emit(IrrigationError(
            message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة للنظام'));
        return;
      }
    }

    emit(IrrigationLoading());
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(IrrigationError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final systemsData =
          await _supabaseService.getIrrigationSystems(currentUser.id);
      final systemData = systemsData.firstWhere(
        (s) => s['id'] == event.systemId,
        orElse: () => throw Exception('النظام غير موجود'),
      );
      final system = IrrigationSystem.fromMap(systemData);

      _cacheService.cacheIrrigationSystem(systemData);

      final sensorDataList =
          await _supabaseService.getSensorData(event.systemId, limit: 50);
      final sensorData =
          sensorDataList.map((data) => SensorData.fromMap(data)).toList();

      if (sensorDataList.isNotEmpty) {
        _cacheService.cacheSensorData(event.systemId, sensorDataList);
      }

      final logsData =
          await _supabaseService.getIrrigationLogs(event.systemId, limit: 20);
      final irrigationLogs =
          logsData.map((data) => IrrigationLog.fromMap(data)).toList();

      emit(SystemDetailsLoaded(
        system: system,
        sensorData: sensorData,
        irrigationLogs: irrigationLogs,
      ));
    } catch (e) {
      final cachedSystem =
          _cacheService.getCachedIrrigationSystem(event.systemId);
      final cachedSensorData =
          _cacheService.getCachedSensorData(event.systemId);

      if (cachedSystem != null) {
        final system = IrrigationSystem.fromMap(cachedSystem);
        final sensorData =
            cachedSensorData.map((data) => SensorData.fromMap(data)).toList();

        emit(SystemDetailsLoaded(
          system: system,
          sensorData: sensorData,
          irrigationLogs: const [],
        ));
      } else {
        emit(IrrigationError(
            message: 'خطأ في تحميل تفاصيل النظام: ${e.toString()}'));
      }
    }
  }

  Future<void> _onToggleSystem(
      ToggleSystemEvent event, Emitter<IrrigationState> emit) async {
    try {
      final success = await _supabaseService.toggleIrrigationSystem(
          event.systemId, event.isActive);
      if (success) {
        if (state is SystemDetailsLoaded) {
          final currentState = state as SystemDetailsLoaded;
          final updatedSystem = currentState.system.copyWith(
            isActive: event.isActive,
            autoIrrigationEnabled: event.isActive
                ? false
                : currentState.system.autoIrrigationEnabled,
          );
          emit(SystemDetailsLoaded(
            system: updatedSystem,
            sensorData: currentState.sensorData,
            irrigationLogs: currentState.irrigationLogs,
          ));
        } else {
          add(LoadIrrigationSystemsEvent());
        }
      } else {
        emit(IrrigationError(message: 'فشل في تغيير حالة النظام'));
      }
    } catch (e) {
      emit(IrrigationError(
          message: 'خطأ في تغيير حالة النظام: ${e.toString()}'));
    }
  }

  Future<void> _onStartManualIrrigation(
      StartManualIrrigationEvent event, Emitter<IrrigationState> emit) async {
    try {
      final success = await _supabaseService.startManualIrrigation(
        event.systemId,
        notes: event.notes,
      );

      if (success) {
        emit(IrrigationSuccess(message: 'تم بدء الري اليدوي بنجاح'));
        await Future.delayed(const Duration(seconds: 2));
        if (state is SystemDetailsLoaded) {
          add(LoadSystemDetailsEvent(systemId: event.systemId));
        } else {
          add(LoadIrrigationSystemsEvent());
        }
      } else {
        emit(IrrigationError(message: 'فشل في بدء الري اليدوي'));
      }
    } catch (e) {
      emit(IrrigationError(message: 'خطأ في بدء الري اليدوي: ${e.toString()}'));
    }
  }

  Future<void> _onStopIrrigation(
      StopIrrigationEvent event, Emitter<IrrigationState> emit) async {
    try {
      final success =
          await _supabaseService.stopIrrigation(event.systemId, event.logId);

      if (success) {
        emit(IrrigationSuccess(message: 'تم إيقاف الري بنجاح'));
        await Future.delayed(const Duration(seconds: 2));
        if (state is SystemDetailsLoaded) {
          add(LoadSystemDetailsEvent(systemId: event.systemId));
        } else {
          add(LoadIrrigationSystemsEvent());
        }
      } else {
        emit(IrrigationError(message: 'فشل في إيقاف الري'));
      }
    } catch (e) {
      emit(IrrigationError(message: 'خطأ في إيقاف الري: ${e.toString()}'));
    }
  }

  Future<void> _onAddSystem(
      AddSystemEvent event, Emitter<IrrigationState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(IrrigationError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final systemData = {
        'user_id': currentUser.id,
        'name': event.name,
        'device_serial': event.deviceSerial,
        'crop_type': event.cropType,
        'area_size': event.areaSize,
        'location': event.location,
        'is_active': true,
        'auto_irrigation_enabled': false,
        'water_low_threshold': 30,
      };

      final success = await _supabaseService.addIrrigationSystem(systemData);

      if (success) {
        emit(IrrigationSuccess(message: 'تم إضافة النظام بنجاح'));
        add(LoadIrrigationSystemsEvent());
      } else {
        emit(IrrigationError(message: 'فشل في إضافة النظام'));
      }
    } catch (e) {
      emit(IrrigationError(message: 'خطأ في إضافة النظام: ${e.toString()}'));
    }
  }

  Future<void> _onLinkDevice(
      LinkDeviceEvent event, Emitter<IrrigationState> emit) async {
    emit(IrrigationLoading());
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(IrrigationError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final deviceInfo =
          await _supabaseService.verifyDeviceSerial(event.deviceSerial);

      if (deviceInfo == null) {
        emit(IrrigationError(message: 'رقم الجهاز غير موجود في النظام'));
        return;
      }

      await _supabaseService.linkDeviceToUser(
          currentUser.id, event.deviceSerial, event.systemName);

      emit(IrrigationSuccess(message: 'تم ربط الجهاز بنجاح'));
      add(LoadIrrigationSystemsEvent());
    } catch (e) {
      emit(IrrigationError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSystem(
      DeleteSystemEvent event, Emitter<IrrigationState> emit) async {
    emit(IrrigationError(
        message:
            'عذراً، لا يمكن حذف أنظمة الري. يرجى التواصل مع الإدارة إذا كنت بحاجة لإزالة نظام ري.'));
  }

  Future<void> _onRefreshSensorData(
      RefreshSensorDataEvent event, Emitter<IrrigationState> emit) async {
    if (state is SystemDetailsLoaded && !_isRefreshing) {
      _isRefreshing = true;
      await Future.delayed(const Duration(seconds: 5));
      add(LoadSystemDetailsEvent(systemId: event.systemId));
      _isRefreshing = false;
    }
  }

  Future<void> _onSetAutoIrrigation(
      SetAutoIrrigationEvent event, Emitter<IrrigationState> emit) async {
    try {
      final success = await _supabaseService.setAutoIrrigation(
          event.systemId, event.enabled);
      if (success) {
        if (state is SystemDetailsLoaded) {
          final currentState = state as SystemDetailsLoaded;
          final updatedSystem = currentState.system.copyWith(
            autoIrrigationEnabled: event.enabled,
            isActive: event.enabled ? false : currentState.system.isActive,
          );
          emit(SystemDetailsLoaded(
            system: updatedSystem,
            sensorData: currentState.sensorData,
            irrigationLogs: currentState.irrigationLogs,
          ));
        } else {
          add(LoadIrrigationSystemsEvent());
        }
      } else {
        emit(IrrigationError(message: 'فشل في تغيير وضع الري التلقائي'));
      }
    } catch (e) {
      emit(IrrigationError(
          message: 'خطأ في تغيير وضع الري التلقائي: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAutoIrrigationSettings(
      UpdateAutoIrrigationSettingsEvent event,
      Emitter<IrrigationState> emit) async {
    try {
      final success = await _supabaseService.updateAutoIrrigationSettings(
        event.systemId,
        startThreshold: event.startThreshold,
        stopThreshold: event.stopThreshold,
      );
      if (success) {
        emit(IrrigationSuccess(message: 'تم تحديث إعدادات الري التلقائي'));
        if (state is SystemDetailsLoaded) {
          await Future.delayed(const Duration(seconds: 2));
          add(LoadSystemDetailsEvent(systemId: event.systemId));
        }
      } else {
        emit(IrrigationError(message: 'فشل في تحديث إعدادات الري التلقائي'));
      }
    } catch (e) {
      emit(IrrigationError(
          message: 'خطأ في تحديث إعدادات الري التلقائي: ${e.toString()}'));
    }
  }

  Future<void> _onClearIrrigationLogs(
      ClearIrrigationLogsEvent event, Emitter<IrrigationState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(IrrigationError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      await _supabaseService.client
          .from('irrigation_logs')
          .delete()
          .eq('system_id', event.systemId);

      emit(IrrigationSuccess(message: 'تم مسح سجلات الري بنجاح'));
      add(LoadSystemDetailsEvent(systemId: event.systemId));
    } catch (e) {
      emit(IrrigationError(message: 'خطأ في مسح سجلات الري: ${e.toString()}'));
    }
  }
}
