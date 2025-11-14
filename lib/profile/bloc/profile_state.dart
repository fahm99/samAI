import 'package:equatable/equatable.dart';
import '../models/user_profile.dart';

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
