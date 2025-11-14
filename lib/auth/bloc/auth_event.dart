import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? location;
  final String? phoneNumber;
  final String? countryCode;

  SignUpEvent({
    required this.email,
    required this.password,
    required this.fullName,
    this.location,
    this.phoneNumber,
    this.countryCode,
  });

  @override
  List<Object> get props => [email, password, fullName];
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class ChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

// OTP Events
class SendEmailOTPEvent extends AuthEvent {
  final String email;

  SendEmailOTPEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class VerifyEmailOTPEvent extends AuthEvent {
  final String email;
  final String otp;
  final String password;
  final String? fullName;
  final String? location;
  final String? phoneNumber;
  final String? countryCode;

  VerifyEmailOTPEvent({
    required this.email,
    required this.otp,
    required this.password,
    this.fullName,
    this.location,
    this.phoneNumber,
    this.countryCode,
  });

  @override
  List<Object> get props => [
        email,
        otp,
        password,
        fullName ?? '',
        location ?? '',
        phoneNumber ?? '',
        countryCode ?? ''
      ];
}

class ResendEmailOTPEvent extends AuthEvent {
  final String email;

  ResendEmailOTPEvent({required this.email});

  @override
  List<Object> get props => [email];
}
