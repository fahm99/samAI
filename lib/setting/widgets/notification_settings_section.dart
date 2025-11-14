import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class NotificationSettingsSection extends StatelessWidget {
  final AppSettings settings;

  const NotificationSettingsSection({super.key, required this.settings});

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
                Icon(Icons.notifications_outlined, color: Color(0xFF2196F3)),
                SizedBox(width: 12),
                Text(
                  'الإشعارات',
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
            secondary: const Icon(Icons.notifications_active,
                color: Color(0xFF2196F3)),
            title: const Text('تفعيل الإشعارات'),
            subtitle: const Text('تلقي جميع الإشعارات'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdateNotificationSettingsEvent(
                      notificationsEnabled: value,
                      soundEnabled: settings.soundEnabled,
                      vibrationEnabled: settings.vibrationEnabled,
                    ),
                  );
            },
          ),
          if (settings.notificationsEnabled) ...[
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: Color(0xFF2196F3)),
              title: const Text('الصوت'),
              subtitle: const Text('تشغيل صوت الإشعارات'),
              value: settings.soundEnabled,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateNotificationSettingsEvent(
                        notificationsEnabled: settings.notificationsEnabled,
                        soundEnabled: value,
                        vibrationEnabled: settings.vibrationEnabled,
                      ),
                    );
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.vibration, color: Color(0xFF2196F3)),
              title: const Text('الاهتزاز'),
              subtitle: const Text('اهتزاز عند وصول الإشعارات'),
              value: settings.vibrationEnabled,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateNotificationSettingsEvent(
                        notificationsEnabled: settings.notificationsEnabled,
                        soundEnabled: settings.soundEnabled,
                        vibrationEnabled: value,
                      ),
                    );
              },
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'أنواع الإشعارات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.eco, color: Color(0xFF4CAF50)),
              title: const Text('العناية بالنباتات'),
              subtitle: const Text('إشعارات الري والتسميد'),
              value: settings.plantCareNotifications,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdatePlantCareNotificationsEvent(enabled: value),
                    );
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary:
                  const Icon(Icons.shopping_cart, color: Color(0xFFFF9800)),
              title: const Text('السوق'),
              subtitle: const Text('إشعارات المنتجات والعروض'),
              value: settings.marketNotifications,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateMarketNotificationsEvent(enabled: value),
                    );
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.settings, color: Color(0xFF9C27B0)),
              title: const Text('النظام'),
              subtitle: const Text('تحديثات وإشعارات النظام'),
              value: settings.systemNotifications,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateSystemNotificationsEvent(enabled: value),
                    );
              },
            ),
          ],
        ],
      ),
    );
  }
}
