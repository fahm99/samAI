import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;

  AuthAuthenticated({required this.userId, required this.email});

  @override
  List<Object> get props => [userId, email];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthSuccess extends AuthState {
  final String message;

  AuthSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// OTP States
class EmailOTPSent extends AuthState {
  final String email;
  final String message;

  EmailOTPSent({required this.email, required this.message});

  @override
  List<Object> get props => [email, message];
}

class EmailOTPVerified extends AuthState {
  final String userId;
  final String email;
  final String message;

  EmailOTPVerified(
      {required this.userId, required this.email, required this.message});

  @override
  List<Object> get props => [userId, email, message];
}

class EmailOTPError extends AuthState {
  final String message;

  EmailOTPError({required this.message});

  @override
  List<Object> get props => [message];
}
