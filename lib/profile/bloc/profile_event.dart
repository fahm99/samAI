import 'package:equatable/equatable.dart';
import 'dart:io';
import 'dart:typed_data';

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
