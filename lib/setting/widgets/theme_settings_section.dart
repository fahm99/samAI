import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class ThemeSettingsSection extends StatelessWidget {
  final AppSettings settings;

  const ThemeSettingsSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, color: Color(0xFF2E7D32)),
                SizedBox(width: 12),
                Text(
                  'المظهر واللغة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: const Color(0xFF2E7D32),
            ),
            title: const Text('الوضع الداكن'),
            subtitle: Text(
              settings.isDarkMode ? 'مفعّل' : 'معطّل',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            value: settings.isDarkMode,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdateThemeEvent(isDarkMode: value),
                  );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF2E7D32)),
            title: const Text('اللغة'),
            subtitle: Text(
              settings.language == 'ar' ? 'العربية' : 'English',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.thermostat, color: Color(0xFF2E7D32)),
            title: const Text('وحدة الحرارة'),
            subtitle: Text(
              settings.temperatureUnit == 'celsius'
                  ? 'مئوية (°C)'
                  : 'فهرنهايت (°F)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showTemperatureUnitDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: settings.language,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateLanguageEvent(language: value),
                      );
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: settings.language,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateLanguageEvent(language: value),
                      );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('وحدة الحرارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('مئوية (°C)'),
              value: 'celsius',
              groupValue: settings.temperatureUnit,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: value,
                          dateFormat: settings.dateFormat,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('فهرنهايت (°F)'),
              value: 'fahrenheit',
              groupValue: settings.temperatureUnit,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateDisplaySettingsEvent(
                          temperatureUnit: value,
                          dateFormat: settings.dateFormat,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
