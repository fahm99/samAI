import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/supabaseservice.dart';
import '../../services/agricultural_cache_service.dart';
import '../../services/image_service.dart';
import '../models/user_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

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
