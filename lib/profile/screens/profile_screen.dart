import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/agricultural_cache_service.dart';
import '../../services/offline_manager.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../models/user_profile.dart';
import '../widgets/profile_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/profile_shimmer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with OfflineMixin {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is ProfileSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).primaryColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoaded) {
              return _buildProfileView(state.profile);
            }

            final cacheService = AgriculturalCacheService();
            final cachedProfile = cacheService.getCachedUserProfile();

            if (cachedProfile != null) {
              return _buildProfileView(cachedProfile);
            }

            return FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 500)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final latestCachedProfile =
                      cacheService.getCachedUserProfile();
                  if (latestCachedProfile != null) {
                    return _buildProfileView(latestCachedProfile);
                  }
                  return _buildEmptyProfileView();
                }
                return const ProfileShimmer();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          flexibleSpace: ProfileHeader(profile: profile),
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                QuickActionsGrid(profile: profile),
                const SizedBox(height: 24),
                _buildAppVersionInfo(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProfileView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد بيانات متاحة',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersionInfo() {
    return Text(
      'إصدار التطبيق 2.1.0',
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[500]
            : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}
