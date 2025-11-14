import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/theme_settings_section.dart';
import '../widgets/notification_settings_section.dart';
import '../widgets/privacy_settings_section.dart';
import '../widgets/data_management_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        elevation: 0,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is SettingsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SettingsLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemeSettingsSection(settings: state.settings),
                    const SizedBox(height: 16),
                    NotificationSettingsSection(settings: state.settings),
                    const SizedBox(height: 16),
                    PrivacySettingsSection(settings: state.settings),
                    const SizedBox(height: 16),
                    DataManagementSection(settings: state.settings),
                    const SizedBox(height: 16),
                    _buildAboutSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }
            return const Center(
              child: Text('لا توجد إعدادات متاحة'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('حول التطبيق'),
            subtitle: const Text('الإصدار 2.1.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'حصاد',
                applicationVersion: '2.1.0',
                applicationIcon: const Icon(Icons.eco, size: 48),
                children: [
                  const Text('تطبيق زراعي ذكي لإدارة المزارع'),
                ],
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('مشاركة التطبيق'),
            onTap: () {
              context.read<SettingsBloc>().add(ShareAppEvent());
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('تقييم التطبيق'),
            onTap: () {
              context.read<SettingsBloc>().add(RateAppEvent());
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('الدعم الفني'),
            onTap: () {
              context.read<SettingsBloc>().add(ContactSupportEvent());
            },
          ),
        ],
      ),
    );
  }
}
