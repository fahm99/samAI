import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/supabaseservice.dart';
import '../services/agricultural_cache_service.dart';
import '../services/offline_manager.dart';
import '../services/image_service.dart';
import '../auth/auth.dart';
import '../auth/change_password_screen.dart';
import '../widgets/location_field.dart';
import '../widgets/phone_number_field.dart';

// Profile Models
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? location;
  final String? phoneNumber;
  final String? countryCode;
  final String? whatsappNumber;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.location,
    this.phoneNumber,
    this.countryCode,
    this.whatsappNumber,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      avatarUrl: map['avatar_url'],
      location: map['location'],
      phoneNumber: map['phone_number'],
      countryCode: map['country_code'],
      whatsappNumber: map['whatsapp_number'],
      bio: map['bio'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        location,
        phoneNumber,
        countryCode,
        whatsappNumber,
        bio,
        createdAt,
        updatedAt,
      ];

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? location,
    String? phoneNumber,
    String? countryCode,
    String? whatsappNumber,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Profile Events
abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final String fullName;
  final String? location;
  final String? phoneNumber;
  final String? countryCode;
  final String? whatsappNumber;
  final String? bio;

  UpdateProfileEvent({
    required this.fullName,
    this.location,
    this.phoneNumber,
    this.countryCode,
    this.whatsappNumber,
    this.bio,
  });

  @override
  List<Object?> get props => [
        fullName,
        location,
        phoneNumber,
        countryCode,
        whatsappNumber,
        bio,
      ];
}

class UpdateAvatarEvent extends ProfileEvent {
  final File imageFile;

  UpdateAvatarEvent({required this.imageFile});

  @override
  List<Object> get props => [imageFile];
}

class UpdateAvatarWebEvent extends ProfileEvent {
  final Uint8List imageBytes;
  final String fileName;

  UpdateAvatarWebEvent({
    required this.imageBytes,
    required this.fileName,
  });

  @override
  List<Object> get props => [imageBytes, fileName];
}

class DeleteAccountEvent extends ProfileEvent {}

// Profile States
abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  ProfileLoaded({required this.profile});

  @override
  List<Object> get props => [profile];

  ProfileLoaded copyWith({
    UserProfile? profile,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}

class ProfileSuccess extends ProfileState {
  final String message;

  ProfileSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// Profile Bloc
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final SupabaseService _supabaseService = SupabaseService();
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateAvatarEvent>(_onUpdateAvatar);
    on<UpdateAvatarWebEvent>(_onUpdateAvatarWeb);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onLoadProfile(
      LoadProfileEvent event, Emitter<ProfileState> emit) async {
    final cachedProfile = _cacheService.getCachedUserProfile();
    if (cachedProfile != null) {
      emit(ProfileLoaded(profile: cachedProfile));
      _loadAndCacheProfile(emit);
      return;
    }

    emit(ProfileLoading());
    await _loadAndCacheProfile(emit);
  }

  Future<void> _loadAndCacheProfile(Emitter<ProfileState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(ProfileError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final profileData = await _supabaseService.getUserProfile(currentUser.id);

      if (profileData != null) {
        profileData['email'] = currentUser.email;
        final profile = UserProfile.fromMap(profileData);
        _cacheService.cacheUserProfile(profile);
        emit(ProfileLoaded(profile: profile));
      } else {
        final newProfileData = {
          'full_name': currentUser.userMetadata?['full_name'] ?? '',
          'location': currentUser.userMetadata?['location'],
          'phone_number': currentUser.userMetadata?['phone_number'],
        };

        final success = await _supabaseService.createUserProfile(
          currentUser.id,
          newProfileData,
        );

        if (success) {
          add(LoadProfileEvent());
        } else {
          emit(ProfileError(message: 'فشل في إنشاء الملف الشخصي'));
        }
      }
    } catch (e) {
      emit(ProfileError(message: 'خطأ في تحميل الملف الشخصي: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(ProfileError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final updateData = {
        'full_name': event.fullName,
        'location': event.location,
        'phone_number': event.phoneNumber,
        'country_code': event.countryCode,
        'whatsapp_number': event.whatsappNumber,
        'bio': event.bio,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final success = await _supabaseService.updateUserProfile(
        currentUser.id,
        updateData,
      );

      if (success) {
        final cachedProfile = _cacheService.getCachedUserProfile();
        if (cachedProfile != null) {
          final updatedProfile = UserProfile(
            id: cachedProfile.id,
            email: cachedProfile.email,
            fullName: event.fullName,
            avatarUrl: cachedProfile.avatarUrl,
            location: event.location,
            phoneNumber: event.phoneNumber,
            countryCode: event.countryCode,
            whatsappNumber: event.whatsappNumber,
            bio: event.bio,
            createdAt: cachedProfile.createdAt,
            updatedAt: DateTime.now(),
          );
          _cacheService.cacheUserProfile(updatedProfile);
          emit(ProfileLoaded(profile: updatedProfile));
        } else {
          add(LoadProfileEvent());
        }
        emit(ProfileSuccess(message: 'تم تحديث الملف الشخصي بنجاح'));
      } else {
        emit(ProfileError(message: 'فشل في تحديث الملف الشخصي'));
      }
    } catch (e) {
      emit(ProfileError(message: 'خطأ في تحديث الملف الشخصي: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvatar(
      UpdateAvatarEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(ProfileError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final currentProfile =
          await _supabaseService.getUserProfile(currentUser.id);
      final oldAvatarUrl = currentProfile?['avatar_url'] as String?;

      final compressedImage =
          await ImageService.compressProfileImage(event.imageFile);
      if (compressedImage == null) {
        emit(ProfileError(message: 'فشل في معالجة الصورة'));
        return;
      }

      final avatarUrl = await _supabaseService.uploadProfileAvatar(
        compressedImage,
        oldAvatarUrl: oldAvatarUrl,
      );

      if (avatarUrl != null) {
        final success = await _supabaseService.updateUserProfile(
          currentUser.id,
          {
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        if (success) {
          emit(ProfileSuccess(message: 'تم تحديث الصورة الشخصية بنجاح'));
          add(LoadProfileEvent());
        } else {
          emit(ProfileError(message: 'فشل في تحديث الصورة الشخصية'));
        }
      } else {
        emit(ProfileError(message: 'فشل في رفع الصورة'));
      }
    } catch (e) {
      emit(ProfileError(
          message: 'خطأ في تحديث الصورة الشخصية: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvatarWeb(
      UpdateAvatarWebEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(ProfileError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final currentProfile =
          await _supabaseService.getUserProfile(currentUser.id);
      final oldAvatarUrl = currentProfile?['avatar_url'] as String?;

      final compressedBytes =
          await ImageService.compressProfileImageForWeb(event.imageBytes);
      if (compressedBytes == null) {
        emit(ProfileError(message: 'فشل في معالجة الصورة'));
        return;
      }

      final avatarUrl = await _supabaseService.uploadProfileAvatarWeb(
        compressedBytes,
        oldAvatarUrl: oldAvatarUrl,
      );

      if (avatarUrl != null) {
        final success = await _supabaseService.updateUserProfile(
          currentUser.id,
          {
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        if (success) {
          emit(ProfileSuccess(message: 'تم تحديث الصورة الشخصية بنجاح'));
          add(LoadProfileEvent());
        } else {
          emit(ProfileError(message: 'فشل في تحديث الصورة الشخصية'));
        }
      } else {
        emit(ProfileError(message: 'فشل في رفع الصورة'));
      }
    } catch (e) {
      emit(ProfileError(
          message: 'خطأ في تحديث الصورة الشخصية: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAccount(
      DeleteAccountEvent event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileError(message: 'ميزة حذف الحساب غير متاحة حالياً'));
    } catch (e) {
      emit(ProfileError(message: 'خطأ في حذف الحساب: ${e.toString()}'));
    }
  }
}

// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with OfflineMixin {
  String _selectedCountryCode = '+967';
  String _selectedCountryFlag = '🇾🇪';
  String _selectedCountryName = 'Yemen';

  void _updateCountryFromCode(String countryCode) {
    final countryMap = {
      '+967': {'flag': '🇾🇪', 'name': 'Yemen'},
      '+966': {'flag': '🇸🇦', 'name': 'Saudi Arabia'},
      '+971': {'flag': '🇦🇪', 'name': 'UAE'},
      '+965': {'flag': '🇰🇼', 'name': 'Kuwait'},
      '+974': {'flag': '🇶🇦', 'name': 'Qatar'},
      '+973': {'flag': '🇧🇭', 'name': 'Bahrain'},
      '+968': {'flag': '🇴🇲', 'name': 'Oman'},
      '+962': {'flag': '🇯🇴', 'name': 'Jordan'},
      '+961': {'flag': '🇱🇧', 'name': 'Lebanon'},
      '+963': {'flag': '🇸🇾', 'name': 'Syria'},
      '+964': {'flag': '🇮🇶', 'name': 'Iraq'},
      '+20': {'flag': '🇪🇬', 'name': 'Egypt'},
      '+1': {'flag': '🇺🇸', 'name': 'USA'},
      '+44': {'flag': '🇬🇧', 'name': 'UK'},
    };

    if (countryMap.containsKey(countryCode)) {
      _selectedCountryFlag = countryMap[countryCode]!['flag']!;
      _selectedCountryName = countryMap[countryCode]!['name']!;
    }
  }

  Widget _buildPhoneFieldForProfile(TextEditingController controller) {
    return PhoneNumberField(
      controller: controller,
      initialCountryCode: _selectedCountryCode,
      initialCountryFlag: _selectedCountryFlag,
      initialCountryName: _selectedCountryName,
      labelText: 'رقم الهاتف',
      hintText: 'أدخل رقم الهاتف',
      isRequired: false,
      onCountryChanged: (countryCode, countryFlag, countryName) {
        setState(() {
          _selectedCountryCode = countryCode;
          _selectedCountryFlag = countryFlag;
          _selectedCountryName = countryName;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  Future<UserProfile?> _loadProfileDirectly() async {
    try {
      final currentUser = SupabaseService().currentUser;
      if (currentUser == null) return null;

      final profileData =
          await SupabaseService().getUserProfile(currentUser.id);
      if (profileData == null) return null;

      return UserProfile.fromMap(profileData);
    } catch (e) {
      return null;
    }
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

            // فحص البيانات المحفوظة أولاً
            final cacheService = AgriculturalCacheService();
            final cachedProfile = cacheService.getCachedUserProfile();

            if (cachedProfile != null) {
              // عرض البيانات المحفوظة فوراً
              return _buildProfileView(cachedProfile);
            }

            // عرض Shimmer فقط إذا لم تكن هناك بيانات محفوظة
            return FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 500)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // بعد 500ms، تحقق مرة أخرى من البيانات المحفوظة
                  final latestCachedProfile =
                      cacheService.getCachedUserProfile();
                  if (latestCachedProfile != null) {
                    return _buildProfileView(latestCachedProfile);
                  }
                  // إذا لم تكن هناك بيانات، عرض شاشة فارغة
                  return _buildEmptyProfileView();
                }
                // عرض Shimmer لمدة قصيرة فقط
                return _buildProfileShimmer();
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
          flexibleSpace: _buildProfileHeader(profile),
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
                _buildQuickActionsGrid(profile),
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

  Widget _buildProfileHeader(UserProfile profile) {
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
                Stack(
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
                      onTap: _showAvatarOptions,
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
                ),
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
                  Container(
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
                          profile.location!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (profile.bio?.isNotEmpty == true)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      profile.bio!,
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
                  ),
                if (profile.location?.isEmpty != false &&
                    profile.bio?.isEmpty != false)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  ),
              ],
            ),
          ),
        ),
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

  Widget _buildModernInfoTile({
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

  Widget _buildQuickActionsGrid(UserProfile profile) {
    final actions = [
      {
        'icon': Icons.account_circle,
        'title': 'معلومات شخصية',
        'subtitle': 'عرض وتحديث البيانات الشخصية',
        'color': const Color(0xFF4CAF50),
        'onTap': () => _showProfileInfoDialog(profile),
      },
      {
        'icon': Icons.edit,
        'title': 'تعديل الملف الشخصي',
        'subtitle': 'تحديث الصورة والبيانات',
        'color': const Color(0xFF2196F3),
        'onTap': () => _showEditProfileDialog(profile),
      },
      {
        'icon': Icons.security,
        'title': 'تغيير كلمة المرور',
        'subtitle': 'تحديث كلمة المرور الخاصة بك',
        'color': const Color(0xFFFF9800),
        'onTap': () => _showChangePasswordDialog(),
      },
      {
        'icon': Icons.exit_to_app,
        'title': 'تسجيل الخروج',
        'subtitle': 'الخروج من التطبيق',
        'color': const Color(0xFFE53935),
        'onTap': () => _showLogoutDialog(),
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: actions.map((action) => _buildActionCard(action)).toList(),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
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

  void _showProfileInfoDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildModernInfoTile(
                      icon: Icons.person,
                      label: 'الاسم الكامل',
                      value: profile.fullName.isNotEmpty
                          ? profile.fullName
                          : 'غير محدد',
                    ),
                    _buildModernInfoTile(
                      icon: Icons.email_outlined,
                      label: 'البريد الإلكتروني',
                      value: profile.email,
                    ),
                    _buildModernInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'رقم الهاتف',
                      value: profile.phoneNumber?.isNotEmpty == true
                          ? '${profile.countryCode ?? '+967'} ${profile.phoneNumber!}'
                          : 'غير محدد',
                    ),
                    _buildModernInfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'الموقع',
                      value: profile.location ?? 'غير محدد',
                    ),
                    if (profile.bio?.isNotEmpty == true)
                      _buildModernInfoTile(
                        icon: Icons.info_outline,
                        label: 'نبذة شخصية',
                        value: profile.bio!,
                        maxLines: 3,
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProfileDialog(profile);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل المعلومات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else if (state is AuthError) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              });
            }
          },
          child: AlertDialog(
            title: const Text(
              'تأكيد تسجيل الخروج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            content: const Text(
              'هل أنت متأكد من تسجيل الخروج؟\nسيتم مسح جميع البيانات المحفوظة محلياً.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(LogoutEvent());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state is AuthLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تغيير الصورة الشخصية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        final fileSize = await image.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'حجم الصورة كبير جداً. يرجى اختيار صورة أصغر من 10 ميجابايت'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final fileName = image.name.toLowerCase();
        if (!fileName.endsWith('.jpg') &&
            !fileName.endsWith('.jpeg') &&
            !fileName.endsWith('.png')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يرجى اختيار صورة بصيغة JPG أو PNG فقط'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) {
            context.read<ProfileBloc>().add(UpdateAvatarWebEvent(
                  imageBytes: bytes,
                  fileName: image.name,
                ));
          }
        } else {
          final File imageFile = File(image.path);
          if (mounted) {
            context
                .read<ProfileBloc>()
                .add(UpdateAvatarEvent(imageFile: imageFile));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'خطأ في اختيار الصورة';

        if (e.toString().contains('permission')) {
          errorMessage = 'يرجى السماح بالوصول إلى الكاميرا أو المعرض';
        } else if (e.toString().contains('camera')) {
          errorMessage = 'خطأ في الوصول إلى الكاميرا';
        } else if (e.toString().contains('gallery')) {
          errorMessage = 'خطأ في الوصول إلى المعرض';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog(UserProfile profile) {
    final fullNameController = TextEditingController(text: profile.fullName);
    final locationController =
        TextEditingController(text: profile.location ?? '');
    final phoneController =
        TextEditingController(text: profile.phoneNumber ?? '');
    final whatsappController =
        TextEditingController(text: profile.whatsappNumber ?? '');
    final bioController = TextEditingController(text: profile.bio ?? '');

    if (profile.countryCode != null) {
      _selectedCountryCode = profile.countryCode!;
      _updateCountryFromCode(profile.countryCode!);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملف الشخصي'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              LocationField(
                controller: locationController,
                labelText: 'الموقع',
                hintText: 'اختر موقعك أو احصل على الموقع الحالي',
                isRequired: false,
              ),
              const SizedBox(height: 16),
              _buildPhoneFieldForProfile(phoneController),
              const SizedBox(height: 16),
              TextField(
                controller: whatsappController,
                decoration: const InputDecoration(
                  labelText: 'رقم WhatsApp',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.chat, color: Colors.green),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'نبذة شخصية',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileBloc>().add(
                    UpdateProfileEvent(
                      fullName: fullNameController.text.trim(),
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      phoneNumber: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      countryCode: _selectedCountryCode,
                      whatsappNumber: whatsappController.text.trim().isEmpty
                          ? null
                          : whatsappController.text.trim(),
                      bio: bioController.text.trim().isEmpty
                          ? null
                          : bioController.text.trim(),
                    ),
                  );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  // تأثير Shimmer لتحميل الملف الشخصي
  Widget _buildProfileShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // صورة الملف الشخصي
          Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[300]!,
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[100]!,
            period: const Duration(milliseconds: 1000),
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // معلومات الملف الشخصي
          ...List.generate(
              6,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Shimmer.fromColors(
                      baseColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[100]!,
                      period: const Duration(milliseconds: 1000),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  )),

          const SizedBox(height: 24),

          // أزرار الإعدادات
          ...List.generate(
              4,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Shimmer.fromColors(
                      baseColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[100]!,
                      period: const Duration(milliseconds: 1000),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  )),
        ],
      ),
    );
  }

  // شاشة فارغة للملف الشخصي
  Widget _buildEmptyProfileView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا يمكن تحميل الملف الشخصي',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
