import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF43A047),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(context),
                const SizedBox(height: 20),
                Text(
                  profile.fullName.isNotEmpty ? profile.fullName : 'مرحباً بك',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (profile.location?.isNotEmpty == true)
                  _buildLocationChip(profile.location!),
                if (profile.bio?.isNotEmpty == true)
                  _buildBioChip(profile.bio!),
                if (profile.location?.isEmpty != false &&
                    profile.bio?.isEmpty != false)
                  _buildCompanyChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white,
            backgroundImage: profile.avatarUrl?.isNotEmpty == true
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl?.isEmpty != false
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey[400],
                  )
                : null,
          ),
        ),
        GestureDetector(
          onTap: () => _showAvatarOptions(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Color(0xFF4CAF50),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationChip(String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 4),
          Text(
            location,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioChip(String bio) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        bio,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.95),
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCompanyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business,
            size: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 6),
          Text(
            'All Design',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null && context.mounted) {
                  if (kIsWeb) {
                    final bytes = await image.readAsBytes();
                    context.read<ProfileBloc>().add(
                          UpdateAvatarWebEvent(
                            imageBytes: bytes,
                            fileName: image.name,
                          ),
                        );
                  } else {
                    context.read<ProfileBloc>().add(
                          UpdateAvatarEvent(imageFile: File(image.path)),
                        );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  if (kIsWeb) {
                    final bytes = await image.readAsBytes();
                    context.read<ProfileBloc>().add(
                          UpdateAvatarWebEvent(
                            imageBytes: bytes,
                            fileName: image.name,
                          ),
                        );
                  } else {
                    context.read<ProfileBloc>().add(
                          UpdateAvatarEvent(imageFile: File(image.path)),
                        );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
