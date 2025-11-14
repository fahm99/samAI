import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class DataManagementSection extends StatelessWidget {
  final AppSettings settings;

  const DataManagementSection({super.key, required this.settings});

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
                Icon(Icons.storage_outlined, color: Color(0xFFFF9800)),
                SizedBox(width: 12),
                Text(
                  'إدارة البيانات',
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
            secondary: const Icon(Icons.backup, color: Color(0xFFFF9800)),
            title: const Text('النسخ الاحتياطي التلقائي'),
            subtitle: Text(
              'تكرار النسخ: ${_getBackupFrequencyText(settings.backupFrequency)}',
            ),
            value: settings.autoBackup,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    UpdateBackupSettingsEvent(
                      autoBackup: value,
                      backupFrequency: settings.backupFrequency,
                    ),
                  );
            },
          ),
          if (settings.autoBackup) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFFFF9800)),
              title: const Text('تكرار النسخ الاحتياطي'),
              subtitle: Text(_getBackupFrequencyText(settings.backupFrequency)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showBackupFrequencyDialog(context);
              },
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Color(0xFFFF9800)),
            title: const Text('تصدير البيانات'),
            subtitle: const Text('حفظ نسخة من بياناتك'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showExportConfirmDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download, color: Color(0xFFFF9800)),
            title: const Text('استيراد البيانات'),
            subtitle: const Text('استعادة بياناتك من ملف'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showImportConfirmDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.cleaning_services, color: Color(0xFFFF9800)),
            title: const Text('مسح ذاكرة التخزين المؤقت'),
            subtitle: const Text('حذف الملفات المؤقتة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.red),
            title: const Text(
              'إعادة تعيين الإعدادات',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('استعادة الإعدادات الافتراضية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showResetDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _getBackupFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'يومياً';
      case 'weekly':
        return 'أسبوعياً';
      case 'monthly':
        return 'شهرياً';
      default:
        return 'يومياً';
    }
  }

  void _showBackupFrequencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تكرار النسخ الاحتياطي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('يومياً'),
              value: 'daily',
              groupValue: settings.backupFrequency,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateBackupSettingsEvent(
                          autoBackup: settings.autoBackup,
                          backupFrequency: value,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('أسبوعياً'),
              value: 'weekly',
              groupValue: settings.backupFrequency,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateBackupSettingsEvent(
                          autoBackup: settings.autoBackup,
                          backupFrequency: value,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('شهرياً'),
              value: 'monthly',
              groupValue: settings.backupFrequency,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                        UpdateBackupSettingsEvent(
                          autoBackup: settings.autoBackup,
                          backupFrequency: value,
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

  void _showExportConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content:
            const Text('سيتم تصدير جميع بياناتك إلى ملف. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(ExportDataEvent());
            },
            child: const Text('تصدير'),
          ),
        ],
      ),
    );
  }

  void _showImportConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد البيانات'),
        content: const Text(
            'سيتم استبدال بياناتك الحالية بالبيانات المستوردة. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(ImportDataEvent());
            },
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح ذاكرة التخزين المؤقت'),
        content: const Text('سيتم حذف جميع الملفات المؤقتة. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(ClearCacheEvent());
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text(
            'سيتم استعادة جميع الإعدادات إلى القيم الافتراضية. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(ResetSettingsEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
}
