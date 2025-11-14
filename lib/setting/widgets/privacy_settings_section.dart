import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class PrivacySettingsSection extends StatelessWidget {
  final AppSettings settings;

  const PrivacySettingsSection({super.key, required this.settings});

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
                Icon(Icons.privacy_tip_outlined, color: Color(0xFF9C27B0)),
                SizedBox(width: 12),
                Text(
                  'الخصوصية والأمان',
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
            secondary:
                const Icon(Icons.person_outline, color: Color(0xFF9C27B0)),
            title: const Text('إظهار المعلومات الشخصية'),
            subtitle: const Text('السماح للآخرين برؤية معلوماتك'),
            value: settings.showPersonalInfo,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdatePrivacySettingsEvent(showPersonalInfo: value),
                  );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined,
                color: Color(0xFF9C27B0)),
            title: const Text('مشاركة الموقع'),
            subtitle: const Text('السماح بمشاركة موقعك الجغرافي'),
            value: settings.shareLocation,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdatePrivacySettingsEvent(shareLocation: value),
                  );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary:
                const Icon(Icons.visibility_outlined, color: Color(0xFF9C27B0)),
            title: const Text('ظهور الملف الشخصي'),
            subtitle: const Text('إظهار ملفك الشخصي للمستخدمين الآخرين'),
            value: settings.profileVisibility,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdatePrivacySettingsEvent(profileVisibility: value),
                  );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary:
                const Icon(Icons.location_searching, color: Color(0xFF9C27B0)),
            title: const Text('خدمات الموقع'),
            subtitle: const Text('تفعيل خدمات تحديد الموقع'),
            value: settings.locationEnabled,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdateLocationSettingEvent(locationEnabled: value),
                  );
            },
          ),
        ],
      ),
    );
  }
}
