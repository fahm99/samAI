import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'profile_info_dialog.dart';
import 'edit_profile_dialog.dart';
import 'change_password_dialog.dart';
import 'logout_dialog.dart';

class QuickActionsGrid extends StatelessWidget {
  final UserProfile profile;

  const QuickActionsGrid({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.account_circle,
        'title': 'معلومات شخصية',
        'subtitle': 'عرض وتحديث البيانات الشخصية',
        'color': const Color(0xFF4CAF50),
        'onTap': () => _showProfileInfoDialog(context),
      },
      {
        'icon': Icons.edit,
        'title': 'تعديل الملف الشخصي',
        'subtitle': 'تحديث الصورة والبيانات',
        'color': const Color(0xFF2196F3),
        'onTap': () => _showEditProfileDialog(context),
      },
      {
        'icon': Icons.security,
        'title': 'تغيير كلمة المرور',
        'subtitle': 'تحديث كلمة المرور الخاصة بك',
        'color': const Color(0xFFFF9800),
        'onTap': () => _showChangePasswordDialog(context),
      },
      {
        'icon': Icons.exit_to_app,
        'title': 'تسجيل الخروج',
        'subtitle': 'الخروج من التطبيق',
        'color': const Color(0xFFE53935),
        'onTap': () => _showLogoutDialog(context),
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children:
          actions.map((action) => _buildActionCard(context, action)).toList(),
    );
  }

  Widget _buildActionCard(BuildContext context, Map<String, dynamic> action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action['onTap'] as VoidCallback,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                action['subtitle'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProfileInfoDialog(profile: profile),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(profile: profile),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoutDialog(),
    );
  }
}
