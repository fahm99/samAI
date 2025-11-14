import 'package:flutter/material.dart';
import '../models/user_profile.dart';

// Placeholder - يحتاج إلى تنفيذ كامل
class EditProfileDialog extends StatelessWidget {
  final UserProfile profile;

  const EditProfileDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الملف الشخصي'),
      content: const Text('هذه الميزة قيد التطوير'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
