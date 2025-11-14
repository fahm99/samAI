import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../services/supabaseservice.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late final SupabaseService _supabaseService = SupabaseService();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin, transformer: _debounce());
    on<SignUpEvent>(_onSignUp, transformer: _debounce());
    on<ForgotPasswordEvent>(_onForgotPassword, transformer: _debounce());
    on<ChangePasswordEvent>(_onChangePassword, transformer: _debounce());
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<SendEmailOTPEvent>(_onSendEmailOTP, transformer: _debounce());
    on<VerifyEmailOTPEvent>(_onVerifyEmailOTP, transformer: _debounce());
    on<ResendEmailOTPEvent>(_onResendEmailOTP, transformer: _debounce());
  }

  EventTransformer<E> _debounce<E>(
      {Duration duration = const Duration(milliseconds: 500)}) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(AuthError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      final response = await _supabaseService
          .signIn(event.email, event.password)
          .timeout(const Duration(seconds: 15));

      if (response != null && response.user != null) {
        await _secureStorage.write(
            key: 'access_token', value: response.session?.accessToken);
        await _secureStorage.write(
            key: 'refresh_token', value: response.session?.refreshToken);
        await _secureStorage.write(key: 'user_id', value: response.user!.id);
        await _secureStorage.write(
            key: 'user_email', value: response.user!.email!);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', response.user!.id);
        await prefs.setString('email', response.user!.email!);

        emit(AuthAuthenticated(
          userId: response.user!.id,
          email: response.user!.email!,
        ));
      } else {
        emit(AuthError(
            message:
                'تعذر تسجيل الدخول. يرجى التأكد من البيانات والمحاولة مجددًا.'));
      }
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مجددًا.';
    } else if (errorString.contains('network')) {
      return 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
    } else if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid email or password')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    } else if (errorString.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً.';
    } else {
      return 'حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مجددًا.';
    }
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(AuthError(message: 'لا يوجد اتصال بالإنترنت.'));
      return;
    }

    try {
      final emailExists = await _supabaseService.isEmailExists(event.email);
      if (emailExists) {
        emit(AuthError(message: 'البريد الإلكتروني مستخدم مسبقاً.'));
        return;
      }

      final success = await _supabaseService.sendEmailOTP(event.email);
      if (success) {
        emit(EmailOTPSent(
          email: event.email,
          message: 'تم إرسال رمز التحقق إلى ${event.email}.',
        ));
      } else {
        emit(AuthError(message: 'فشل في إرسال رمز التحقق.'));
      }
    } catch (e) {
      emit(AuthError(message: 'حدث خطأ أثناء إنشاء الحساب.'));
    }
  }

  Future<void> _onForgotPassword(
      ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final success = await _supabaseService.resetPassword(event.email);
      if (success) {
        emit(AuthSuccess(
            message: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.'));
      } else {
        emit(AuthError(message: 'تعذر إرسال رابط إعادة تعيين كلمة المرور.'));
      }
    } catch (e) {
      emit(AuthError(message: 'حدث خطأ. يرجى المحاولة مجددًا.'));
    }
  }

  Future<void> _onChangePassword(
      ChangePasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final success = await _supabaseService.changePassword(
        event.currentPassword,
        event.newPassword,
      );

      if (success) {
        emit(AuthSuccess(message: 'تم تغيير كلمة المرور بنجاح'));
      } else {
        emit(AuthError(message: 'فشل في تغيير كلمة المرور.'));
      }
    } catch (e) {
      emit(AuthError(message: 'حدث خطأ أثناء تغيير كلمة المرور.'));
    }
  }

  Future<void> _onSendEmailOTP(
      SendEmailOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final emailExists = await _supabaseService.isEmailExists(event.email);
      if (emailExists) {
        emit(EmailOTPError(message: 'هذا البريد الإلكتروني مسجل مسبقاً.'));
        return;
      }

      final success = await _supabaseService.sendEmailOTP(event.email);
      if (success) {
        emit(EmailOTPSent(
          email: event.email,
          message: 'تم إرسال رمز التحقق إلى ${event.email}.',
        ));
      } else {
        emit(EmailOTPError(message: 'فشل في إرسال رمز التحقق.'));
      }
    } catch (e) {
      emit(EmailOTPError(message: e.toString()));
    }
  }

  Future<void> _onVerifyEmailOTP(
      VerifyEmailOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final response = await _supabaseService.verifyEmailOTPAndSignUp(
        event.email,
        event.otp,
        event.password,
        fullName: event.fullName,
        location: event.location,
        phoneNumber: event.phoneNumber,
        countryCode: event.countryCode,
      );

      if (response != null && response.user != null) {
        await _updateLocalStorage(response.user!);

        emit(EmailOTPVerified(
          userId: response.user!.id,
          email: response.user!.email!,
          message: 'تم التحقق بنجاح! مرحباً بك.',
        ));
      } else {
        emit(EmailOTPError(message: 'فشل في التحقق من رمز التحقق.'));
      }
    } catch (e) {
      emit(EmailOTPError(message: e.toString()));
    }
  }

  Future<void> _onResendEmailOTP(
      ResendEmailOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final success = await _supabaseService.resendEmailOTP(event.email);
      if (success) {
        emit(EmailOTPSent(
          email: event.email,
          message: 'تم إعادة إرسال رمز التحقق.',
        ));
      } else {
        emit(EmailOTPError(message: 'فشل في إعادة إرسال رمز التحقق.'));
      }
    } catch (e) {
      emit(EmailOTPError(message: e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _supabaseService.signOut();
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      emit(AuthUnauthenticated());
    } catch (e) {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onCheckAuth(
      CheckAuthEvent event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final prefUserId = prefs.getString('userId');
      final prefEmail = prefs.getString('email');

      if (isLoggedIn && prefUserId != null && prefEmail != null) {
        emit(AuthAuthenticated(userId: prefUserId, email: prefEmail));
        _validateSessionInBackground();
        return;
      }

      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        await _updateLocalStorage(currentUser);
        emit(AuthAuthenticated(
            userId: currentUser.id, email: currentUser.email!));
        return;
      }

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  void _validateSessionInBackground() async {
    try {
      final isSessionValid = await _supabaseService.isSessionValid();
      if (!isSessionValid) {
        await _clearAllStoredData();
        add(LogoutEvent());
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _updateLocalStorage(supabase.User user) async {
    try {
      final session = _supabaseService.client.auth.currentSession;

      await _secureStorage.write(
          key: 'access_token', value: session?.accessToken);
      await _secureStorage.write(
          key: 'refresh_token', value: session?.refreshToken);
      await _secureStorage.write(key: 'user_id', value: user.id);
      await _secureStorage.write(key: 'user_email', value: user.email!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', user.id);
      await prefs.setString('email', user.email!);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _clearAllStoredData() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Silent fail
    }
  }
}
