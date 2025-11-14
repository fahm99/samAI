import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileInfoDialog extends StatelessWidget {
  final UserProfile profile;

  const ProfileInfoDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoTile(
                    context,
                    icon: Icons.person,
                    label: 'الاسم الكامل',
                    value: profile.fullName.isNotEmpty
                        ? profile.fullName
                        : 'غير محدد',
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني',
                    value: profile.email,
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.phone_outlined,
                    label: 'رقم الهاتف',
                    value: profile.phoneNumber?.isNotEmpty == true
                        ? '${profile.countryCode ?? '+967'} ${profile.phoneNumber!}'
                        : 'غير محدد',
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'الموقع',
                    value: profile.location ?? 'غير محدد',
                  ),
                  if (profile.bio?.isNotEmpty == true)
                    _buildInfoTile(
                      context,
                      icon: Icons.info_outline,
                      label: 'نبذة شخصية',
                      value: profile.bio!,
                      maxLines: 3,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
