import 'package:equatable/equatable.dart';
import '../models/app_settings.dart';

abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  SettingsLoaded({required this.settings});

  @override
  List<Object> get props => [settings];

  SettingsLoaded copyWith({
    AppSettings? settings,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError({required this.message});

  @override
  List<Object> get props => [message];
}

class SettingsSuccess extends SettingsState {
  final String message;

  SettingsSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
