import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoBackup;
  final String backupFrequency;
  final bool locationEnabled;
  final String temperatureUnit;
  final String dateFormat;

  // إعدادات الإشعارات المفصلة
  final bool plantCareNotifications;
  final bool marketNotifications;
  final bool systemNotifications;

  // إعدادات الخصوصية
  final bool showPersonalInfo;
  final bool shareLocation;
  final bool profileVisibility;

  const AppSettings({
    required this.isDarkMode,
    required this.language,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.autoBackup,
    required this.backupFrequency,
    required this.locationEnabled,
    required this.temperatureUnit,
    required this.dateFormat,
    required this.plantCareNotifications,
    required this.marketNotifications,
    required this.systemNotifications,
    required this.showPersonalInfo,
    required this.shareLocation,
    required this.profileVisibility,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      isDarkMode: false,
      language: 'ar',
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      autoBackup: true,
      backupFrequency: 'daily',
      locationEnabled: true,
      temperatureUnit: 'celsius',
      dateFormat: 'dd/MM/yyyy',
      plantCareNotifications: true,
      marketNotifications: true,
      systemNotifications: true,
      showPersonalInfo: true,
      shareLocation: false,
      profileVisibility: true,
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      language: map['language'] ?? 'ar',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      autoBackup: map['autoBackup'] ?? true,
      backupFrequency: map['backupFrequency'] ?? 'daily',
      locationEnabled: map['locationEnabled'] ?? true,
      temperatureUnit: map['temperatureUnit'] ?? 'celsius',
      dateFormat: map['dateFormat'] ?? 'dd/MM/yyyy',
      plantCareNotifications: map['plantCareNotifications'] ?? true,
      marketNotifications: map['marketNotifications'] ?? true,
      systemNotifications: map['systemNotifications'] ?? true,
      showPersonalInfo: map['showPersonalInfo'] ?? true,
      shareLocation: map['shareLocation'] ?? false,
      profileVisibility: map['profileVisibility'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency,
      'locationEnabled': locationEnabled,
      'temperatureUnit': temperatureUnit,
      'dateFormat': dateFormat,
      'plantCareNotifications': plantCareNotifications,
      'marketNotifications': marketNotifications,
      'systemNotifications': systemNotifications,
      'showPersonalInfo': showPersonalInfo,
      'shareLocation': shareLocation,
      'profileVisibility': profileVisibility,
    };
  }

  @override
  List<Object> get props => [
        isDarkMode,
        language,
        notificationsEnabled,
        soundEnabled,
        vibrationEnabled,
        autoBackup,
        backupFrequency,
        locationEnabled,
        temperatureUnit,
        dateFormat,
        plantCareNotifications,
        marketNotifications,
        systemNotifications,
        showPersonalInfo,
        shareLocation,
        profileVisibility,
      ];

  AppSettings copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoBackup,
    String? backupFrequency,
    bool? locationEnabled,
    String? temperatureUnit,
    String? dateFormat,
    bool? plantCareNotifications,
    bool? marketNotifications,
    bool? systemNotifications,
    bool? showPersonalInfo,
    bool? shareLocation,
    bool? profileVisibility,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      dateFormat: dateFormat ?? this.dateFormat,
      plantCareNotifications:
          plantCareNotifications ?? this.plantCareNotifications,
      marketNotifications: marketNotifications ?? this.marketNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      showPersonalInfo: showPersonalInfo ?? this.showPersonalInfo,
      shareLocation: shareLocation ?? this.shareLocation,
      profileVisibility: profileVisibility ?? this.profileVisibility,
    );
  }
}
