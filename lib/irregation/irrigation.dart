// irrigation.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import '../services/supabaseservice.dart';
import '../services/agricultural_cache_service.dart';
import '../services/offline_manager.dart';

// Irrigation Models
class IrrigationSystem extends Equatable {
  final String id;
  final String name;
  final String deviceSerial;
  final String cropType;
  final double? areaSize;
  final String? location;
  final bool isActive;
  final bool autoIrrigationEnabled;
  final int waterLowThreshold;
  final DateTime createdAt;

  const IrrigationSystem({
    required this.id,
    required this.name,
    required this.deviceSerial,
    required this.cropType,
    this.areaSize,
    this.location,
    required this.isActive,
    required this.autoIrrigationEnabled,
    required this.waterLowThreshold,
    required this.createdAt,
  });

  factory IrrigationSystem.fromMap(Map<String, dynamic> map) {
    return IrrigationSystem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      deviceSerial: map['device_serial'] ?? map['esp32_serial'] ?? '',
      cropType: map['crop_type'] ?? '',
      areaSize: map['area_size']?.toDouble(),
      location: map['location'],
      isActive: map['is_active'] ?? false,
      autoIrrigationEnabled: map['auto_irrigation_enabled'] ?? false,
      waterLowThreshold: map['water_low_threshold'] ?? 30,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        deviceSerial,
        cropType,
        areaSize,
        location,
        isActive,
        autoIrrigationEnabled,
        waterLowThreshold,
        createdAt,
      ];

  IrrigationSystem copyWith({
    String? id,
    String? name,
    String? deviceSerial,
    String? cropType,
    double? areaSize,
    String? location,
    bool? isActive,
    bool? autoIrrigationEnabled,
    int? waterLowThreshold,
    DateTime? createdAt,
  }) {
    return IrrigationSystem(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceSerial: deviceSerial ?? this.deviceSerial,
      cropType: cropType ?? this.cropType,
      areaSize: areaSize ?? this.areaSize,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      autoIrrigationEnabled:
          autoIrrigationEnabled ?? this.autoIrrigationEnabled,
      waterLowThreshold: waterLowThreshold ?? this.waterLowThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SensorData extends Equatable {
  final String id;
  final String systemId;
  final double? soilMoisture;
  final double? temperature;
  final double? humidity;
  final double? waterLevel;
  final double? lightIntensity;
  final double? phLevel;
  final bool? rainDetected; // أضف هذا السطر
  final DateTime timestamp;

  const SensorData({
    required this.id,
    required this.systemId,
    this.soilMoisture,
    this.temperature,
    this.humidity,
    this.waterLevel,
    this.lightIntensity,
    this.phLevel,
    this.rainDetected, // أضف هذا السطر
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id'] ?? '',
      systemId: map['system_id'] ?? '',
      soilMoisture: map['soil_moisture']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      humidity: map['humidity']?.toDouble(),
      waterLevel: map['water_level']?.toDouble(),
      lightIntensity: map['light_intensity']?.toDouble(),
      phLevel: map['ph_level']?.toDouble(),
      rainDetected: map['rain_detected'] == null
          ? null
          : map['rain_detected'] == true, // أضف هذا السطر
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
        id,
        systemId,
        soilMoisture,
        temperature,
        humidity,
        waterLevel,
        lightIntensity,
        phLevel,
        rainDetected, // أضف هذا السطر
        timestamp,
      ];
}

class IrrigationLog extends Equatable {
  final String id;
  final String systemId;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? waterUsedLiters;
  final double? soilMoistureBefore;
  final double? soilMoistureAfter;
  final String? triggeredBy;
  final String? notes;

  const IrrigationLog({
    required this.id,
    required this.systemId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.waterUsedLiters,
    this.soilMoistureBefore,
    this.soilMoistureAfter,
    this.triggeredBy,
    this.notes,
  });

  factory IrrigationLog.fromMap(Map<String, dynamic> map) {
    return IrrigationLog(
      id: map['id'] ?? '',
      systemId: map['system_id'] ?? '',
      type: map['type'] ?? 'manual',
      startTime:
          DateTime.parse(map['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      durationMinutes: map['duration_minutes'],
      waterUsedLiters: map['water_used_liters']?.toDouble(),
      soilMoistureBefore: map['soil_moisture_before']?.toDouble(),
      soilMoistureAfter: map['soil_moisture_after']?.toDouble(),
      triggeredBy: map['triggered_by'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        systemId,
        type,
        startTime,
        endTime,
        durationMinutes,
        waterUsedLiters,
        soilMoistureBefore,
        soilMoistureAfter,
        triggeredBy,
        notes,
      ];
}

// Irrigation Events
abstract class IrrigationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadIrrigationSystemsEvent extends IrrigationEvent {}

class LoadSystemDetailsEvent extends IrrigationEvent {
  final String systemId;

  LoadSystemDetailsEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class ToggleSystemEvent extends IrrigationEvent {
  final String systemId;
  final bool isActive;

  ToggleSystemEvent({required this.systemId, required this.isActive});

  @override
  List<Object> get props => [systemId, isActive];
}

class StartManualIrrigationEvent extends IrrigationEvent {
  final String systemId;
  final String? notes;

  StartManualIrrigationEvent({required this.systemId, this.notes});

  @override
  List<Object?> get props => [systemId, notes];
}

class StopIrrigationEvent extends IrrigationEvent {
  final String systemId;
  final String logId;

  StopIrrigationEvent({required this.systemId, required this.logId});

  @override
  List<Object> get props => [systemId, logId];
}

class AddSystemEvent extends IrrigationEvent {
  final String name;
  final String deviceSerial;
  final String cropType;
  final double? areaSize;
  final String? location;

  AddSystemEvent({
    required this.name,
    required this.deviceSerial,
    required this.cropType,
    this.areaSize,
    this.location,
  });

  @override
  List<Object?> get props => [name, deviceSerial, cropType, areaSize, location];
}

class LinkDeviceEvent extends IrrigationEvent {
  final String deviceSerial;
  final String systemName;

  LinkDeviceEvent({required this.deviceSerial, required this.systemName});

  @override
  List<Object> get props => [deviceSerial, systemName];
}

class DeleteSystemEvent extends IrrigationEvent {
  final String systemId;

  DeleteSystemEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class ClearIrrigationLogsEvent extends IrrigationEvent {
  final String systemId;

  ClearIrrigationLogsEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class RefreshSensorDataEvent extends IrrigationEvent {
  final String systemId;

  RefreshSensorDataEvent({required this.systemId});

  @override
  List<Object> get props => [systemId];
}

class SetAutoIrrigationEvent extends IrrigationEvent {
  final String systemId;
  final bool enabled;
  SetAutoIrrigationEvent({required this.systemId, required this.enabled});
  @override
  List<Object> get props => [systemId, enabled];
}

class UpdateAutoIrrigationSettingsEvent extends IrrigationEvent {
  final String systemId;
  final double? startThreshold;
  final double? stopThreshold;
  UpdateAutoIrrigationSettingsEvent({
    required this.systemId,
    this.startThreshold,
    this.stopThreshold,
  });
  @override
  List<Object?> get props => [systemId, startThreshold, stopThreshold];
}

// Irrigation States
abstract class IrrigationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IrrigationInitial extends IrrigationState {}

class IrrigationLoading extends IrrigationState {}

class IrrigationSystemsLoaded extends IrrigationState {
  final List<IrrigationSystem> systems;

  IrrigationSystemsLoaded({required this.systems});

  @override
  List<Object> get props => [systems];

  IrrigationSystemsLoaded copyWith({
    List<IrrigationSystem>? systems,
  }) {
    return IrrigationSystemsLoaded(
      systems: systems ?? this.systems,
    );
  }
}

// تم إزالة IrrigationSystemsLoadedOffline لتبسيط تجربة المستخدم

class SystemDetailsLoaded extends IrrigationState {
  final IrrigationSystem system;
  final List<SensorData> sensorData;
  final List<IrrigationLog> irrigationLogs;

  SystemDetailsLoaded({
    required this.system,
    required this.sensorData,
    required this.irrigationLogs,
  });

  @override
  List<Object> get props => [system, sensorData, irrigationLogs];

  SystemDetailsLoaded copyWith({
    IrrigationSystem? system,
    List<SensorData>? sensorData,
    List<IrrigationLog>? irrigationLogs,
  }) {
    return SystemDetailsLoaded(
      system: system ?? this.system,
      sensorData: sensorData ?? this.sensorData,
      irrigationLogs: irrigationLogs ?? this.irrigationLogs,
    );
  }
}

// تم إزالة SystemDetailsLoadedOffline لتبسيط تجربة المستخدم

class IrrigationError extends IrrigationState {
  final String message;

  IrrigationError({required this.message});

  @override
  List<Object> get props => [message];
}

class IrrigationSuccess extends IrrigationState {
  final String message;

  IrrigationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// Irrigation Bloc - محسن مع التخزين المؤقت
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
        // Retry loading data when connection is restored
        add(LoadIrrigationSystemsEvent());
      }
    });

    // Start periodic sensor updates
    _startSensorUpdates();
  }

  // Debounce transformer to prevent rapid event firing
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
        // Refresh sensor data for all active systems
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
    // تحديث حالة الاتصال في الخدمة
    _cacheService.updateConnectionStatus(_isConnected);

    // إذا لم يكن هناك اتصال، استخدم البيانات المحفوظة
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

      // حفظ البيانات في التخزين المؤقت
      if (systemsData.isNotEmpty) {
        _cacheService.cacheIrrigationSystems(systemsData);
      }

      final systems =
          systemsData.map((data) => IrrigationSystem.fromMap(data)).toList();
      emit(IrrigationSystemsLoaded(systems: systems));
    } catch (e) {
      // في حالة الخطأ، جرب استخدام البيانات المحفوظة
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

  // Helper method for better error handling
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
    // إذا لم يكن هناك اتصال، استخدم البيانات المحفوظة
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
          irrigationLogs: const [], // لا نحفظ سجلات الري في التخزين المؤقت
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

      // Get system details
      final systemsData =
          await _supabaseService.getIrrigationSystems(currentUser.id);
      final systemData = systemsData.firstWhere(
        (s) => s['id'] == event.systemId,
        orElse: () => throw Exception('النظام غير موجود'),
      );
      final system = IrrigationSystem.fromMap(systemData);

      // حفظ بيانات النظام
      _cacheService.cacheIrrigationSystem(systemData);

      // Get sensor data
      final sensorDataList =
          await _supabaseService.getSensorData(event.systemId, limit: 50);
      final sensorData =
          sensorDataList.map((data) => SensorData.fromMap(data)).toList();

      // حفظ بيانات الاستشعار
      if (sensorDataList.isNotEmpty) {
        _cacheService.cacheSensorData(event.systemId, sensorDataList);
      }

      // Get irrigation logs
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
      // في حالة الخطأ، جرب استخدام البيانات المحفوظة
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
        // تحديث الحالة مباشرة دون إظهار رسالة نجاح
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
        // إعادة تحميل التفاصيل أو القائمة حسب الحالة بعد تأخير
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
        // إعادة تحميل التفاصيل أو القائمة حسب الحالة بعد تأخير
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

        // Reload systems
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

      // التحقق من وجود الجهاز أولاً
      final deviceInfo =
          await _supabaseService.verifyDeviceSerial(event.deviceSerial);

      if (deviceInfo == null) {
        emit(IrrigationError(message: 'رقم الجهاز غير موجود في النظام'));
        return;
      }

      // ربط الجهاز بالمستخدم
      await _supabaseService.linkDeviceToUser(
          currentUser.id, event.deviceSerial, event.systemName);

      emit(IrrigationSuccess(message: 'تم ربط الجهاز بنجاح'));

      // إعادة تحميل الأنظمة
      add(LoadIrrigationSystemsEvent());
    } catch (e) {
      emit(IrrigationError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSystem(
      DeleteSystemEvent event, Emitter<IrrigationState> emit) async {
    // منع حذف أنظمة الري - هذه العملية غير مسموحة للمستخدمين
    emit(IrrigationError(
        message:
            'عذراً، لا يمكن حذف أنظمة الري. يرجى التواصل مع الإدارة إذا كنت بحاجة لإزالة نظام ري.'));
  }

  Future<void> _onRefreshSensorData(
      RefreshSensorDataEvent event, Emitter<IrrigationState> emit) async {
    if (state is SystemDetailsLoaded && !_isRefreshing) {
      _isRefreshing = true;
      // Reload system details بعد تأخير 5 ثوان
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
        // تحديث الحالة مباشرة دون إظهار رسالة نجاح
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

  // معالج حدث مسح سجلات الري
  Future<void> _onClearIrrigationLogs(
      ClearIrrigationLogsEvent event, Emitter<IrrigationState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(IrrigationError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      // مسح جميع سجلات الري للنظام المحدد
      await _supabaseService.client
          .from('irrigation_logs')
          .delete()
          .eq('system_id', event.systemId);

      emit(IrrigationSuccess(message: 'تم مسح سجلات الري بنجاح'));

      // إعادة تحميل تفاصيل النظام لتحديث الواجهة
      add(LoadSystemDetailsEvent(systemId: event.systemId));
    } catch (e) {
      emit(IrrigationError(message: 'خطأ في مسح سجلات الري: ${e.toString()}'));
    }
  }
}

// Irrigation Screen
class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> with OfflineMixin {
  @override
  void initState() {
    super.initState();
    context.read<IrrigationBloc>().add(LoadIrrigationSystemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<IrrigationBloc, IrrigationState>(
        listener: (context, state) {
          if (state is IrrigationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is IrrigationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocConsumer<IrrigationBloc, IrrigationState>(
          listener: (context, state) {
            if (state is IrrigationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // تم إزالة مؤشر الوضع غير المتصل لتحسين تجربة المستخدم

                Expanded(
                  child: _buildContent(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(IrrigationState state) {
    if (state is IrrigationLoading) {
      return _buildShimmerLoading();
    } else if (state is IrrigationSystemsLoaded) {
      return _buildSystemsList(state.systems);
    } else if (state is SystemDetailsLoaded) {
      return _buildSystemDetails(state);
    } else if (state is IrrigationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<IrrigationBloc>()
                    .add(LoadIrrigationSystemsEvent());
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    return Container();
  }

  Widget _buildSystemsList(List<IrrigationSystem> systems) {
    if (systems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'لا توجد أنظمة ري',
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد أنظمة ري مضافة حالياً',
              style: TextStyle(color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // حساب الإحصائيات
    final activeSystems = systems.where((s) => s.isActive).length;
    final autoSystems = systems.where((s) => s.autoIrrigationEnabled).length;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<IrrigationBloc>().add(LoadIrrigationSystemsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: systems.length + 1, // +1 لبطاقة الملخص
        itemBuilder: (context, index) {
          if (index == 0) {
            // بطاقة ملخص أنظمة الري
            return _buildIrrigationSummaryCard(
                systems, activeSystems, autoSystems);
          }
          final system = systems[index - 1];
          return _buildSystemCard(system);
        },
      ),
    );
  }

  // بطاقة ملخص أنظمة الري
  Widget _buildIrrigationSummaryCard(
      List<IrrigationSystem> systems, int activeSystems, int autoSystems) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'ملخص أنظمة الري',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activeSystems > 0 ? 'نشط' : 'متوقف',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryStatCard(
                      '${systems.length}',
                      'إجمالي الأنظمة',
                      Icons.dashboard,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryStatCard(
                      '$activeSystems',
                      'أنظمة نشطة',
                      Icons.play_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryStatCard(
                      '$autoSystems',
                      'ري تلقائي',
                      Icons.smart_toy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(IrrigationSystem system) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: system.isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    system.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // عرض رطوبة التربة مع إشعار الحالة
                _buildSoilMoistureIndicator(system.id),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: system.isActive
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Theme.of(context).disabledColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    system.isActive ? 'نشط' : 'متوقف',
                    style: TextStyle(
                      color: system.isActive
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.memory, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'رقم الجهاز: ${system.deviceSerial}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.agriculture, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'نوع المحصول: ${system.cropType}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (system.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'الموقع: ${system.location}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (system.areaSize != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.square_foot, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'المساحة: ${system.areaSize} متر مربع',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<IrrigationBloc>().add(
                            LoadSystemDetailsEvent(systemId: system.id),
                          );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض التفاصيل'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: system.isActive,
                  onChanged: (value) {
                    context.read<IrrigationBloc>().add(
                          ToggleSystemEvent(
                              systemId: system.id, isActive: value),
                        );
                  },
                  activeColor: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemDetails(SystemDetailsLoaded state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.system.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // العودة إلى شاشة الري الرئيسية
            context.read<IrrigationBloc>().add(LoadIrrigationSystemsEvent());
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<IrrigationBloc>().add(
                    RefreshSensorDataEvent(systemId: state.system.id),
                  );
            },
          ),
          // تم إزالة زر الحذف لمنع المستخدم من حذف أنظمة الري
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات النظام
            _buildSystemInfoCard(state.system),
            const SizedBox(height: 16),

            // أزرار التحكم
            _buildControlButtonsCard(state.system),
            const SizedBox(height: 16),

            // بيانات الحساسات
            _buildSensorDataCard(state.sensorData,
                pumpStatus: state.system.isActive),
            const SizedBox(height: 16),

            // سجل الري
            _buildIrrigationLogsCard(state.irrigationLogs),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(IrrigationSystem system) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'معلومات النظام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow('الاسم', system.name),
                  _buildInfoRow('رقم الجهاز', system.deviceSerial),
                  _buildInfoRow('نوع المحصول', system.cropType),
                  if (system.areaSize != null)
                    _buildInfoRow('المساحة', '${system.areaSize} متر مربع'),
                  if (system.location != null)
                    _buildInfoRow('الموقع', system.location!),
                  _buildInfoRow(
                      'عتبة انخفاض المياه', '${system.waterLowThreshold}%'),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          'الحالة:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: system.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: system.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        child: Text(
                          system.isActive ? 'نشط' : 'متوقف',
                          style: TextStyle(
                            color: system.isActive ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // كارت أزرار التحكم المنفصل
  Widget _buildControlButtonsCard(IrrigationSystem system) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.control_camera, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'أزرار التحكم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // أزرار التحكم اليدوي والتلقائي
            Row(
              children: [
                // زر التحكم اليدوي
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: system.isActive && !system.autoIrrigationEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: system.isActive && !system.autoIrrigationEnabled
                            ? Colors.green
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color:
                              system.isActive && !system.autoIrrigationEnabled
                                  ? Colors.green
                                  : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ري يدوي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                system.isActive && !system.autoIrrigationEnabled
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Switch.adaptive(
                          value:
                              system.isActive && !system.autoIrrigationEnabled,
                          onChanged: (value) {
                            if (value) {
                              // تفعيل الري اليدوي وإيقاف التلقائي
                              if (system.autoIrrigationEnabled) {
                                context.read<IrrigationBloc>().add(
                                      SetAutoIrrigationEvent(
                                        systemId: system.id,
                                        enabled: false,
                                      ),
                                    );
                              }
                              context.read<IrrigationBloc>().add(
                                    ToggleSystemEvent(
                                      systemId: system.id,
                                      isActive: true,
                                    ),
                                  );
                            } else {
                              // إيقاف الري اليدوي
                              context.read<IrrigationBloc>().add(
                                    ToggleSystemEvent(
                                      systemId: system.id,
                                      isActive: false,
                                    ),
                                  );
                            }
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // زر التحكم التلقائي
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: system.autoIrrigationEnabled
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: system.autoIrrigationEnabled
                            ? Colors.blue
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: system.autoIrrigationEnabled
                              ? Colors.blue
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ري تلقائي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: system.autoIrrigationEnabled
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Switch.adaptive(
                          value: system.autoIrrigationEnabled,
                          onChanged: (value) {
                            if (value) {
                              // تفعيل الري التلقائي وإيقاف اليدوي
                              if (system.isActive) {
                                context.read<IrrigationBloc>().add(
                                      ToggleSystemEvent(
                                        systemId: system.id,
                                        isActive: false,
                                      ),
                                    );
                              }
                              context.read<IrrigationBloc>().add(
                                    SetAutoIrrigationEvent(
                                      systemId: system.id,
                                      enabled: true,
                                    ),
                                  );
                            } else {
                              // إيقاف الري التلقائي
                              context.read<IrrigationBloc>().add(
                                    SetAutoIrrigationEvent(
                                      systemId: system.id,
                                      enabled: false,
                                    ),
                                  );
                            }
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // زر إعدادات الري التلقائي
            if (system.autoIrrigationEnabled)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAutoIrrigationSettingsDialog(system.id);
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('إعدادات الري التلقائي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataCard(List<SensorData> sensorData,
      {bool pumpStatus = false}) {
    if (sensorData.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'بيانات الحساسات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                child: const Center(
                  child: Text(
                    'لا توجد بيانات حساسات متاحة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latest = sensorData.first;
    final sensors = [
      {
        'label': 'رطوبة التربة',
        'value': latest.soilMoisture != null
            ? '${latest.soilMoisture!.toStringAsFixed(1)}%'
            : '--',
        'icon': Icons.water_drop,
        'color': _getSoilMoistureColor(latest.soilMoisture),
        'unit': '%'
      },
      {
        'label': 'درجة الحرارة',
        'value': latest.temperature != null
            ? '${latest.temperature!.toStringAsFixed(1)}°C'
            : '--',
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'unit': '°C'
      },
      {
        'label': 'الرطوبة الجوية',
        'value': latest.humidity != null
            ? '${latest.humidity!.toStringAsFixed(1)}%'
            : '--',
        'icon': Icons.opacity,
        'color': Colors.cyan,
        'unit': '%'
      },
      {
        'label': 'منسوب المياه',
        'value': latest.waterLevel != null
            ? '${latest.waterLevel!.toStringAsFixed(1)}%'
            : '--',
        'icon': Icons.water,
        'color': Colors.blue[700]!,
        'unit': '%'
      },
      {
        'label': 'هطول المطر',
        'value': latest.rainDetected == true ? 'يوجد مطر' : 'لا يوجد',
        'icon': Icons.umbrella,
        'color': latest.rainDetected == true ? Colors.blue : Colors.grey,
        'unit': ''
      },
      {
        'label': 'حالة المضخة',
        'value': pumpStatus ? 'تشغيل' : 'إيقاف',
        'icon': pumpStatus ? Icons.power : Icons.power_off,
        'color': pumpStatus ? Colors.green : Colors.red,
        'unit': ''
      },
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'بيانات الحساسات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                Text(
                  'آخر تحديث: ${_formatTime(latest.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (sensor['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (sensor['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sensor['icon'] as IconData,
                        color: sensor['color'] as Color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sensor['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sensor['value'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sensor['color'] as Color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة لتحديد لون رطوبة التربة حسب القيمة
  Color _getSoilMoistureColor(double? moisture) {
    if (moisture == null) return Colors.grey;
    if (moisture < 30) return Colors.red;
    if (moisture < 60) return Colors.orange;
    return Colors.green;
  }

  // دالة لتنسيق الوقت
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildIrrigationLogsCard(List<IrrigationLog> logs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل الري',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // زر مسح السجلات
                if (logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showClearLogsConfirmation(),
                    icon: const Icon(Icons.delete_sweep,
                        size: 18, color: Colors.red),
                    label: const Text(
                      'مسح السجلات',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (logs.isEmpty)
              const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'لا توجد سجلات ري متاحة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...logs.take(5).map((log) => _buildLogItem(log)),
            if (logs.length > 5)
              TextButton(
                onPressed: () {
                  // Show all logs
                },
                child: const Text('عرض جميع السجلات'),
              ),
          ],
        ),
      ),
    );
  }

  // وظيفة عرض مؤشر رطوبة التربة مع الإشعارات
  Widget _buildSoilMoistureIndicator(String systemId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService().sensorDataPollingStream(systemId, limit: 1),
      builder: (context, snapshot) {
        double? soilMoisture;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final latestData = snapshot.data!.first;
          soilMoisture = latestData['soil_moisture']?.toDouble();
        }

        if (soilMoisture == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('--', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        // تحديد اللون والحالة بناءً على رطوبة التربة
        Color backgroundColor;
        Color textColor;
        IconData icon;

        if (soilMoisture < 30) {
          // تحتاج ري - أحمر فاتح
          backgroundColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red[700]!;
          icon = Icons.warning;
        } else if (soilMoisture >= 70) {
          // مروية - أخضر فاتح
          backgroundColor = Colors.green.withOpacity(0.2);
          textColor = Colors.green[700]!;
          icon = Icons.check_circle;
        } else {
          // متوسطة - أزرق فاتح
          backgroundColor = Colors.blue.withOpacity(0.2);
          textColor = Colors.blue[700]!;
          icon = Icons.water_drop;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                '${soilMoisture.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogItem(IrrigationLog log) {
    final isOngoing = log.endTime == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.type == 'manual' ? Icons.touch_app : Icons.schedule,
                size: 16,
                color: isOngoing ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                log.type == 'manual' ? 'ري يدوي' : 'ري تلقائي',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOngoing ? 'جاري' : 'مكتمل',
                  style: TextStyle(
                    color: isOngoing ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'بدء: ${_formatDateTime(log.startTime)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (log.endTime != null)
            Text(
              'انتهاء: ${_formatDateTime(log.endTime!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (log.durationMinutes != null)
            Text(
              'المدة: ${log.durationMinutes} دقيقة',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (log.notes != null && log.notes!.isNotEmpty)
            Text(
              'ملاحظات: ${log.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAutoIrrigationSettingsDialog(String systemId) {
    final startController = TextEditingController();
    final stopController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات الري التلقائي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: 'عتبة بدء الري (%)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stopController,
              decoration:
                  const InputDecoration(labelText: 'عتبة إيقاف الري (%)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IrrigationBloc>().add(
                    UpdateAutoIrrigationSettingsEvent(
                      systemId: systemId,
                      startThreshold: double.tryParse(startController.text),
                      stopThreshold: double.tryParse(stopController.text),
                    ),
                  );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // وظيفة عرض تأكيد مسح السجلات
  void _showClearLogsConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح سجلات الري'),
        content: const Text(
            'هل أنت متأكد من مسح جميع سجلات الري؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // إضافة حدث مسح السجلات
              final state = context.read<IrrigationBloc>().state;
              if (state is SystemDetailsLoaded) {
                context.read<IrrigationBloc>().add(
                      ClearIrrigationLogsEvent(systemId: state.system.id),
                    );
              }
            },
            child: const Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Shimmer loading widget for better UX
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Link Device Dialog
class LinkDeviceDialog extends StatefulWidget {
  const LinkDeviceDialog({super.key});

  @override
  State<LinkDeviceDialog> createState() => _LinkDeviceDialogState();
}

class _LinkDeviceDialogState extends State<LinkDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceSerialController = TextEditingController();
  final _systemNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ربط جهاز موجود'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل رقم الجهاز واسم النظام لربطه بحسابك',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deviceSerialController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'رقم الجهاز (ESP32/ESP8266) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.memory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الجهاز';
                  }
                  if (value.length < 6) {
                    return 'رقم الجهاز قصير جداً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _systemNameController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'اسم النظام *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم النظام';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);

              context.read<IrrigationBloc>().add(
                    LinkDeviceEvent(
                      deviceSerial: _deviceSerialController.text.trim(),
                      systemName: _systemNameController.text.trim(),
                    ),
                  );
            }
          },
          child: const Text('ربط الجهاز'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _deviceSerialController.dispose();
    _systemNameController.dispose();
    super.dispose();
  }
}

// Add System Dialog
class AddSystemDialog extends StatefulWidget {
  const AddSystemDialog({super.key});

  @override
  State<AddSystemDialog> createState() => _AddSystemDialogState();
}

class _AddSystemDialogState extends State<AddSystemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deviceSerialController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة نظام ري جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'اسم النظام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم النظام';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deviceSerialController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'رقم الجهاز *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الجهاز';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cropTypeController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'نوع المحصول *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال نوع المحصول';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaSizeController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'المساحة (متر مربع)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);

              final areaSize = _areaSizeController.text.trim().isEmpty
                  ? null
                  : double.tryParse(_areaSizeController.text.trim());

              context.read<IrrigationBloc>().add(
                    AddSystemEvent(
                      name: _nameController.text.trim(),
                      deviceSerial: _deviceSerialController.text.trim(),
                      cropType: _cropTypeController.text.trim(),
                      areaSize: areaSize,
                      location: _locationController.text.trim().isEmpty
                          ? null
                          : _locationController.text.trim(),
                    ),
                  );
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceSerialController.dispose();
    _cropTypeController.dispose();
    _areaSizeController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
