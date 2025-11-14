import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateThemeEvent extends SettingsEvent {
  final bool isDarkMode;

  UpdateThemeEvent({required this.isDarkMode});

  @override
  List<Object> get props => [isDarkMode];
}

class UpdateLanguageEvent extends SettingsEvent {
  final String language;

  UpdateLanguageEvent({required this.language});

  @override
  List<Object> get props => [language];
}

class UpdateNotificationSettingsEvent extends SettingsEvent {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  UpdateNotificationSettingsEvent({
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  @override
  List<Object> get props =>
      [notificationsEnabled, soundEnabled, vibrationEnabled];
}

class UpdatePlantCareNotificationsEvent extends SettingsEvent {
  final bool enabled;

  UpdatePlantCareNotificationsEvent({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdateMarketNotificationsEvent extends SettingsEvent {
  final bool enabled;

  UpdateMarketNotificationsEvent({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdateSystemNotificationsEvent extends SettingsEvent {
  final bool enabled;

  UpdateSystemNotificationsEvent({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdatePrivacySettingsEvent extends SettingsEvent {
  final bool? showPersonalInfo;
  final bool? shareLocation;
  final bool? profileVisibility;

  UpdatePrivacySettingsEvent({
    this.showPersonalInfo,
    this.shareLocation,
    this.profileVisibility,
  });

  @override
  List<Object?> get props =>
      [showPersonalInfo, shareLocation, profileVisibility];
}

class UpdateBackupSettingsEvent extends SettingsEvent {
  final bool autoBackup;
  final String backupFrequency;

  UpdateBackupSettingsEvent({
    required this.autoBackup,
    required this.backupFrequency,
  });

  @override
  List<Object> get props => [autoBackup, backupFrequency];
}

class UpdateLocationSettingEvent extends SettingsEvent {
  final bool locationEnabled;

  UpdateLocationSettingEvent({required this.locationEnabled});

  @override
  List<Object> get props => [locationEnabled];
}

class UpdateDisplaySettingsEvent extends SettingsEvent {
  final String temperatureUnit;
  final String dateFormat;

  UpdateDisplaySettingsEvent({
    required this.temperatureUnit,
    required this.dateFormat,
  });

  @override
  List<Object> get props => [temperatureUnit, dateFormat];
}

class ResetSettingsEvent extends SettingsEvent {}

class ExportDataEvent extends SettingsEvent {}

class ImportDataEvent extends SettingsEvent {}

class ClearCacheEvent extends SettingsEvent {}

class CheckAppUpdateEvent extends SettingsEvent {}

class ShareAppEvent extends SettingsEvent {}

class RateAppEvent extends SettingsEvent {}

class ContactSupportEvent extends SettingsEvent {}
