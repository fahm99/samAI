// auth.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sam/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../services/supabaseservice.dart';
import '../widgets/phone_number_field.dart';
import '../utlits/safe_context_utils.dart';
import '../widgets/location_field.dart';

// Auth Events
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

// Auth States
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

// Auth Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late final SupabaseService _supabaseService = SupabaseService();

  // Secure storage for sensitive data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin, transformer: _debounce());
    on<SignUpEvent>(_onSignUp, transformer: _debounce());
    on<ForgotPasswordEvent>(_onForgotPassword, transformer: _debounce());
    on<ChangePasswordEvent>(_onChangePassword, transformer: _debounce());
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);

    // OTP Events
    on<SendEmailOTPEvent>(_onSendEmailOTP, transformer: _debounce());
    on<VerifyEmailOTPEvent>(_onVerifyEmailOTP, transformer: _debounce());
    on<ResendEmailOTPEvent>(_onResendEmailOTP, transformer: _debounce());
  }

  // Optimized debounce using EasyDebounce for better performance
  EventTransformer<E> _debounce<E>(
      {Duration duration = const Duration(milliseconds: 500)}) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // Check network connectivity first
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
          .timeout(const Duration(seconds: 15)); // Add timeout for better UX

      if (response != null && response.user != null) {
        // Store sensitive data in secure storage
        await _secureStorage.write(
            key: 'access_token', value: response.session?.accessToken);
        await _secureStorage.write(
            key: 'refresh_token', value: response.session?.refreshToken);
        await _secureStorage.write(key: 'user_id', value: response.user!.id);
        await _secureStorage.write(
            key: 'user_email', value: response.user!.email!);

        // Store non-sensitive data in SharedPreferences for quick access
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
      String errorMessage = _getErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  // Helper method for better error handling
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مجددًا.';
    } else if (errorString.contains('network')) {
      return 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
    } else if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid email or password')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة. يرجى التحقق من البيانات.';
    } else if (errorString.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً من خلال الرابط المرسل إليك.';
    } else if (errorString.contains('too many requests') ||
        errorString.contains('rate limit')) {
      return 'محاولات كثيرة جداً. يرجى الانتظار قليلاً ثم المحاولة مجددًا.';
    } else if (errorString.contains('user not found')) {
      return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
    } else if (errorString.contains('account disabled')) {
      return 'تم تعطيل هذا الحساب. يرجى التواصل مع الدعم الفني.';
    } else if (errorString.contains('weak password')) {
      return 'كلمة المرور ضعيفة. يرجى اختيار كلمة مرور أقوى.';
    } else {
      return 'حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مجددًا.';
    }
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // Check network connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(AuthError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      // التحقق من تكرار البريد الإلكتروني
      final emailExists = await _supabaseService.isEmailExists(event.email);
      if (emailExists) {
        emit(AuthError(
            message:
                'البريد الإلكتروني مستخدم مسبقاً. يرجى استخدام بريد آخر.'));
        return;
      }

      // التحقق من تكرار رقم الهاتف إذا تم إدخاله
      if (event.phoneNumber != null && event.phoneNumber!.isNotEmpty) {
        final phoneExists = await _supabaseService.isPhoneExists(
            event.phoneNumber!, event.countryCode ?? '+967');
        if (phoneExists) {
          emit(AuthError(
              message: 'رقم الهاتف مستخدم مسبقاً. يرجى استخدام رقم آخر.'));
          return;
        }
      }

      // إرسال رمز التحقق بدلاً من إنشاء الحساب مباشرة
      final success = await _supabaseService.sendEmailOTP(event.email);
      if (success) {
        emit(EmailOTPSent(
          email: event.email,
          message:
              'تم إرسال رمز التحقق إلى ${event.email}. يرجى التحقق من صندوق الوارد والبريد المهمل.',
        ));
      } else {
        emit(AuthError(
            message: 'فشل في إرسال رمز التحقق. يرجى المحاولة مرة أخرى.'));
      }
    } catch (e) {
      String errorMessage = _getSignUpErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  // Helper method for better sign up error handling
  String _getSignUpErrorMessage(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مجددًا.';
    } else if (error.toString().contains('network')) {
      return 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
    } else if (error.toString().contains('User already registered')) {
      return 'البريد الإلكتروني مستخدم مسبقاً. يرجى استخدام بريد آخر.';
    } else if (error
        .toString()
        .contains('Password should be at least 6 characters')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
    } else if (error.toString().contains('Invalid email')) {
      return 'البريد الإلكتروني غير صحيح. يرجى التحقق من صيغة البريد.';
    } else {
      return 'حدث خطأ أثناء إنشاء الحساب. يرجى المحاولة مجددًا.';
    }
  }

  Future<void> _onForgotPassword(
      ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // Check network connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(AuthError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      final success = await _supabaseService.resetPassword(event.email);
      if (success) {
        emit(AuthSuccess(
            message:
                'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني. يرجى التحقق من صندوق الوارد والبريد المهمل.'));
      } else {
        emit(AuthError(
            message:
                'تعذر إرسال رابط إعادة تعيين كلمة المرور. يرجى التأكد من صحة البريد الإلكتروني.'));
      }
    } catch (e) {
      String errorMessage = _getForgotPasswordErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onChangePassword(
      ChangePasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // Check network connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(AuthError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      final success = await _supabaseService.changePassword(
        event.currentPassword,
        event.newPassword,
      );

      if (success) {
        emit(AuthSuccess(message: 'تم تغيير كلمة المرور بنجاح'));
      } else {
        emit(AuthError(
            message: 'فشل في تغيير كلمة المرور. تأكد من كلمة المرور الحالية.'));
      }
    } catch (e) {
      String errorMessage = _getChangePasswordErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  // Helper method for forgot password error handling
  String _getForgotPasswordErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مجددًا.';
    } else if (errorString.contains('network')) {
      return 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
    } else if (errorString.contains('user not found') ||
        errorString.contains('email not found')) {
      return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
    } else if (errorString.contains('too many requests') ||
        errorString.contains('rate limit')) {
      return 'محاولات كثيرة جداً. يرجى الانتظار قليلاً ثم المحاولة مجددًا.';
    } else if (errorString.contains('invalid email')) {
      return 'البريد الإلكتروني غير صحيح. يرجى التحقق من صيغة البريد.';
    } else {
      return 'حدث خطأ أثناء إعادة تعيين كلمة المرور. يرجى المحاولة مجددًا.';
    }
  }

  // Helper method for change password error handling
  String _getChangePasswordErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid_credentials') ||
        errorString.contains('wrong password')) {
      return 'كلمة المرور الحالية غير صحيحة.';
    } else if (errorString.contains('weak_password')) {
      return 'كلمة المرور الجديدة ضعيفة. يجب أن تحتوي على 8 أحرف على الأقل.';
    } else if (errorString.contains('same_password')) {
      return 'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية.';
    } else if (errorString.contains('network')) {
      return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.';
    } else {
      return 'حدث خطأ أثناء تغيير كلمة المرور. يرجى المحاولة مجددًا.';
    }
  }

  // ===== OTP Event Handlers =====

  // إرسال رمز التحقق عبر البريد الإلكتروني
  Future<void> _onSendEmailOTP(
      SendEmailOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // التحقق من الاتصال بالإنترنت
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(EmailOTPError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      // التحقق من تكرار البريد الإلكتروني أولاً
      final emailExists = await _supabaseService.isEmailExists(event.email);
      if (emailExists) {
        emit(EmailOTPError(
            message:
                'هذا البريد الإلكتروني مسجل مسبقاً. يرجى استخدام بريد آخر أو تسجيل الدخول.'));
        return;
      }

      // إرسال رمز التحقق
      final success = await _supabaseService.sendEmailOTP(event.email);
      if (success) {
        emit(EmailOTPSent(
          email: event.email,
          message:
              'تم إرسال رمز التحقق إلى ${event.email}. يرجى التحقق من صندوق الوارد والبريد المهمل.',
        ));
      } else {
        emit(EmailOTPError(
            message: 'فشل في إرسال رمز التحقق. يرجى المحاولة مرة أخرى.'));
      }
    } catch (e) {
      emit(EmailOTPError(message: e.toString()));
    }
  }

  // التحقق من رمز OTP وإنشاء الحساب
  Future<void> _onVerifyEmailOTP(
      VerifyEmailOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // التحقق من الاتصال بالإنترنت
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(EmailOTPError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      // التحقق من رمز OTP وإنشاء الحساب
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
        // حفظ البيانات محلياً
        await _updateLocalStorage(response.user!);

        emit(EmailOTPVerified(
          userId: response.user!.id,
          email: response.user!.email!,
          message:
              'تم التحقق من البريد الإلكتروني بنجاح! مرحباً بك في التطبيق.',
        ));
      } else {
        emit(EmailOTPError(
            message: 'فشل في التحقق من رمز التحقق. يرجى المحاولة مرة أخرى.'));
      }
    } catch (e) {
      emit(EmailOTPError(message: e.toString()));
    }
  }

  // إعادة إرسال رمز التحقق
  Future<void> _onResendEmailOTP(
      ResendEmailOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // التحقق من الاتصال بالإنترنت
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(EmailOTPError(
          message:
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مجددًا.'));
      return;
    }

    try {
      final success = await _supabaseService.resendEmailOTP(event.email);
      if (success) {
        emit(EmailOTPSent(
          email: event.email,
          message:
              'تم إعادة إرسال رمز التحقق إلى ${event.email}. يرجى التحقق من صندوق الوارد.',
        ));
      } else {
        emit(EmailOTPError(
            message: 'فشل في إعادة إرسال رمز التحقق. يرجى المحاولة بعد قليل.'));
      }
    } catch (e) {
      emit(EmailOTPError(message: e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _supabaseService.signOut();

      // Clear both secure storage and shared preferences
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails, clear local data and emit unauthenticated state
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onCheckAuth(
      CheckAuthEvent event, Emitter<AuthState> emit) async {
    try {
      // التحقق السريع من SharedPreferences أولاً (أسرع)
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final prefUserId = prefs.getString('userId');
      final prefEmail = prefs.getString('email');

      if (isLoggedIn && prefUserId != null && prefEmail != null) {
        // إرسال حالة المصادقة فوراً
        emit(AuthAuthenticated(userId: prefUserId, email: prefEmail));

        // التحقق من صحة الجلسة في الخلفية (بدون انتظار)
        _validateSessionInBackground();
        return;
      }

      // إذا لم توجد بيانات في SharedPreferences، التحقق من Supabase
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        await _updateLocalStorage(currentUser);
        emit(AuthAuthenticated(
            userId: currentUser.id, email: currentUser.email!));
        return;
      }

      // لا توجد جلسة صالحة
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // التحقق من صحة الجلسة في الخلفية
  void _validateSessionInBackground() async {
    try {
      final isSessionValid = await _supabaseService.isSessionValid();
      if (!isSessionValid) {
        // إذا كانت الجلسة غير صالحة، مسح البيانات وتسجيل الخروج
        await _clearAllStoredData();
        add(LogoutEvent());
      }
    } catch (e) {
      // في حالة الخطأ، لا نفعل شيئاً لتجنب إزعاج المستخدم
    }
  }

  // دالة مساعدة لتحديث البيانات المحفوظة محلياً
  Future<void> _updateLocalStorage(supabase.User user) async {
    try {
      final session = _supabaseService.client.auth.currentSession;

      // حفظ البيانات في التخزين الآمن
      await _secureStorage.write(
          key: 'access_token', value: session?.accessToken);
      await _secureStorage.write(
          key: 'refresh_token', value: session?.refreshToken);
      await _secureStorage.write(key: 'user_id', value: user.id);
      await _secureStorage.write(key: 'user_email', value: user.email!);

      // حفظ البيانات في SharedPreferences للوصول السريع
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', user.id);
      await prefs.setString('email', user.email!);
    } catch (e) {
      print('Error updating local storage: $e');
    }
  }

  // دالة مساعدة لمسح جميع البيانات المحفوظة
  Future<void> _clearAllStoredData() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing stored data: $e');
    }
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe && savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = rememberMe;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('remember_me');
    }
  }

  void _onLoginPressed(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      _saveCredentials();

      // Use EasyDebounce to prevent rapid button presses
      EasyDebounce.debounce(
        'login-button',
        const Duration(milliseconds: 500),
        () {
          context.read<AuthBloc>().add(LoginEvent(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              ));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSafeError(state.message);
          } else if (state is AuthSuccess) {
            context.showSafeSuccess(state.message);
          } else if (state is AuthAuthenticated) {
            // التوجيه إلى الشاشة الرئيسية بعد نجاح تسجيل الدخول
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // شعار التطبيق
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.eco,
                              size: 60,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'المساعد الزراعي الذكي',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الرجاء تسجيل الدخول للمتابعة',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      // تحسين regex للبريد الإلكتروني
                      if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                          .hasMatch(value.trim())) {
                        return 'يرجى إدخال بريد إلكتروني صحيح (مثال: user@example.com)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      if (value.length > 128) {
                        return 'كلمة المرور طويلة جداً (الحد الأقصى 128 حرف)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text('تذكرني'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          context.safePush(const ForgotPasswordScreen());
                        },
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BlocSelector<AuthBloc, AuthState, bool>(
                    selector: (state) => state is AuthLoading,
                    builder: (context, isLoading) {
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : () => _onLoginPressed(context),
                          style: ElevatedButton.styleFrom(),
                          child: isLoading
                              ? const CircularProgressIndicator.adaptive()
                              : const Text('تسجيل الدخول'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ليس لديك حساب؟'),
                      TextButton(
                        onPressed: () {
                          context.safePush(const SignUpScreen());
                        },
                        child: const Text('إنشاء حساب جديد'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Sign Up Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // متغيرات رقم الهاتف ورمز الدولة
  String _selectedCountryCode = '+967'; // اليمن كافتراضي
  String _selectedCountryFlag = '🇾🇪';
  String _selectedCountryName = 'Yemen';

  // دالة لبناء حقل الهاتف مع اختيار رمز الدولة
  Widget _buildPhoneField() {
    return PhoneNumberField(
      controller: _phoneController,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSafeError(state.message);
          } else if (state is AuthSuccess) {
            context.showSafeSuccess(state.message);
            // العودة إلى شاشة تسجيل الدخول
            context.safePop();
          } else if (state is EmailOTPSent) {
            context.showSafeSuccess(state.message);
            // الانتقال لشاشة التحقق من OTP
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: state.email,
                  password: _passwordController.text,
                  fullName: _fullNameController.text.trim(),
                  location: _locationController.text.trim().isNotEmpty
                      ? _locationController.text.trim()
                      : null,
                  phoneNumber: _phoneController.text.trim().isNotEmpty
                      ? _phoneController.text.trim()
                      : null,
                  countryCode: _selectedCountryCode,
                ),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        // شعار التطبيق
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.person_add,
                                    size: 40,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'المساعد الزراعي الذكي',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'انضم إلى مجتمع الزراعة الذكية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أنشئ حسابك للاستفادة من جميع الميزات',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _fullNameController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال الاسم الكامل';
                      }
                      if (value.trim().length < 2) {
                        return 'الاسم يجب أن يكون حرفين على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPhoneField(),
                  const SizedBox(height: 16),
                  LocationField(
                    controller: _locationController,
                    labelText: 'الموقع/المدينة',
                    hintText: 'اختر موقعك أو احصل على الموقع الحالي',
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      if (value.length > 128) {
                        return 'كلمة المرور طويلة جداً (الحد الأقصى 128 حرف)';
                      }
                      // تحسين التحقق من قوة كلمة المرور
                      if (!RegExp(r'^(?=.*[a-zA-Z])').hasMatch(value)) {
                        return 'كلمة المرور يجب أن تحتوي على حرف واحد على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'أوافق على شروط الاستخدام وسياسة الخصوصية',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading || !_acceptTerms
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                          SignUpEvent(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                            fullName:
                                                _fullNameController.text.trim(),
                                            location: _locationController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : _locationController.text
                                                    .trim(),
                                            phoneNumber: _phoneController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : _phoneController.text.trim(),
                                            countryCode: _selectedCountryCode,
                                          ),
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state is AuthLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  'إنشاء الحساب',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب بالفعل؟'),
                      TextButton(
                        onPressed: () {
                          context.safePop();
                        },
                        child: const Text('تسجيل الدخول'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نسيت كلمة المرور'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            context.safePop();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار التطبيق
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'المساعد الزراعي الذكي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'إعادة تعيين كلمة المرور',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'يرجى إدخال بريد إلكتروني صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthBloc>().add(
                                              ForgotPasswordEvent(
                                                email: _emailController.text
                                                    .trim(),
                                              ),
                                            );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      'إرسال رابط الإعادة',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context.safePop();
                        },
                        child: const Text('العودة إلى تسجيل الدخول'),
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// شاشة التحقق من رمز OTP
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String? fullName;
  final String? location;
  final String? phoneNumber;
  final String? countryCode;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.password,
    this.fullName,
    this.location,
    this.phoneNumber,
    this.countryCode,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _resendCountdown = 0;
  Timer? _timer;
  int _attemptCount = 0;
  final int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _verifyOTP() {
    final otpCode = _getOTPCode();
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رمز التحقق كاملاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_attemptCount >= _maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تجاوز عدد المحاولات المسموح. يرجى طلب رمز جديد.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _attemptCount++;

    context.read<AuthBloc>().add(
          VerifyEmailOTPEvent(
            email: widget.email,
            otp: otpCode,
            password: widget.password,
            fullName: widget.fullName,
            location: widget.location,
            phoneNumber: widget.phoneNumber,
            countryCode: widget.countryCode,
          ),
        );
  }

  void _resendOTP() {
    if (_resendCountdown > 0) return;

    _attemptCount = 0; // إعادة تعيين عداد المحاولات
    _clearOTP();
    _startResendCountdown();

    context.read<AuthBloc>().add(
          ResendEmailOTPEvent(email: widget.email),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحقق من البريد الإلكتروني'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailOTPError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is EmailOTPSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is EmailOTPVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // الانتقال للشاشة الرئيسية
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة البريد الإلكتروني
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 40,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 32),

                // العنوان
                const Text(
                  'تحقق من بريدك الإلكتروني',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // الوصف
                Text(
                  'أدخل رمز التحقق المكون من 6 أرقام المرسل إلى:\n${widget.email}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // حقول إدخال OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 55,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2E7D32),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }

                          // التحقق التلقائي عند إدخال 6 أرقام
                          if (index == 5 && value.isNotEmpty) {
                            _verifyOTP();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // زر التحقق
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'تحقق من الرمز',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // إعادة الإرسال
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لم تستلم الرمز؟ '),
                    TextButton(
                      onPressed: _resendCountdown > 0 ? null : _resendOTP,
                      child: Text(
                        _resendCountdown > 0
                            ? 'إعادة الإرسال ($_resendCountdown)'
                            : 'إعادة الإرسال',
                        style: TextStyle(
                          color: _resendCountdown > 0
                              ? Colors.grey
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // تغيير البريد الإلكتروني
                TextButton(
                  onPressed: () {
                    context.safePop();
                  },
                  child: const Text('تغيير البريد الإلكتروني'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
