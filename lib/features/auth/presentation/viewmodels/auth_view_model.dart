import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/device_permission_service.dart';
import '../../../../core/storage/local_demo_storage.dart';
import '../../data/mock_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';
export '../../domain/auth_user.dart';

enum OtpPurpose { registration, recovery }

enum PendingAuthAction {
  signIn,
  register,
  forgotPassword,
  verifyOtp,
  resetPassword,
  resendOtp,
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);
final authClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
const _unchanged = Object();

class AuthState {
  const AuthState({
    this.user,
    this.initialized = false,
    this.permissionsRequired = false,
    this.busy = false,
    this.error,
    this.message,
    this.email = '',
    this.password = '',
    this.rememberMe = false,
    this.language = '',
    this.registration = const RegistrationDraft(),
    this.recoveryEmail = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.otp = '',
    this.flow,
    this.recoveryVerified = false,
    this.otpExpiresAt,
    this.resendAllowedAt,
    this.simulateOffline = false,
    this.pendingAction,
    this.pendingReturnRoute = '/sign-in',
    this.permissionStatus = const {},
  });
  final AuthUser? user;
  final bool initialized;
  final bool permissionsRequired;
  final bool busy;
  final String? error;
  final String? message;
  final String email;
  final String password;
  final bool rememberMe;
  final String language;
  final RegistrationDraft registration;
  final String recoveryEmail;
  final String newPassword;
  final String confirmPassword;
  final String otp;
  final OtpPurpose? flow;
  final bool recoveryVerified;
  final DateTime? otpExpiresAt;
  final DateTime? resendAllowedAt;
  final bool simulateOffline;
  final PendingAuthAction? pendingAction;
  final String pendingReturnRoute;
  final Map<String, String> permissionStatus;
  String get otpEmail =>
      flow == OtpPurpose.registration ? registration.email : recoveryEmail;

  AuthState copyWith({
    Object? user = _unchanged,
    bool? initialized,
    bool? permissionsRequired,
    bool? busy,
    Object? error = _unchanged,
    Object? message = _unchanged,
    String? email,
    String? password,
    bool? rememberMe,
    String? language,
    RegistrationDraft? registration,
    String? recoveryEmail,
    String? newPassword,
    String? confirmPassword,
    String? otp,
    Object? flow = _unchanged,
    bool? recoveryVerified,
    DateTime? otpExpiresAt,
    DateTime? resendAllowedAt,
    bool? simulateOffline,
    Object? pendingAction = _unchanged,
    String? pendingReturnRoute,
    Map<String, String>? permissionStatus,
  }) => AuthState(
    user: identical(user, _unchanged) ? this.user : user as AuthUser?,
    initialized: initialized ?? this.initialized,
    permissionsRequired: permissionsRequired ?? this.permissionsRequired,
    busy: busy ?? this.busy,
    error: identical(error, _unchanged) ? this.error : error as String?,
    message: identical(message, _unchanged) ? this.message : message as String?,
    email: email ?? this.email,
    password: password ?? this.password,
    rememberMe: rememberMe ?? this.rememberMe,
    language: language ?? this.language,
    registration: registration ?? this.registration,
    recoveryEmail: recoveryEmail ?? this.recoveryEmail,
    newPassword: newPassword ?? this.newPassword,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    otp: otp ?? this.otp,
    flow: identical(flow, _unchanged) ? this.flow : flow as OtpPurpose?,
    recoveryVerified: recoveryVerified ?? this.recoveryVerified,
    otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
    resendAllowedAt: resendAllowedAt ?? this.resendAllowedAt,
    simulateOffline: simulateOffline ?? this.simulateOffline,
    pendingAction: identical(pendingAction, _unchanged)
        ? this.pendingAction
        : pendingAction as PendingAuthAction?,
    pendingReturnRoute: pendingReturnRoute ?? this.pendingReturnRoute,
    permissionStatus: permissionStatus ?? this.permissionStatus,
  );
}

class AuthViewModel extends Notifier<AuthState> {
  Future<void>? _initialization;
  AuthRepository get repository => ref.read(authRepositoryProvider);
  LocalDemoStorage get _storage => ref.read(localDemoStorageProvider);
  DateTime get _now => ref.read(authClockProvider)();
  @override
  AuthState build() {
    Future.microtask(initialize);
    return AuthState(language: repository.languages.first);
  }

  Future<void> initialize() => _initialization ??= _loadPreferences();

  Future<void> _loadPreferences() async {
    if (state.initialized) return;
    final email = await _storage.readString('rememberedEmail');
    final language = await _storage.readString('loginLanguage');
    if (!ref.mounted) return;
    state = state.copyWith(
      initialized: true,
      email: state.email.isEmpty ? email ?? '' : state.email,
      rememberMe: email != null,
      language: repository.languages.contains(language)
          ? language
          : state.language,
    );
  }

  void updateSignIn({String? email, String? password, bool? rememberMe}) =>
      state = state.copyWith(
        email: email,
        password: password,
        rememberMe: rememberMe,
        error: null,
        message: null,
      );
  void updateRegistration(RegistrationDraft draft) =>
      state = state.copyWith(registration: draft, error: null, message: null);
  void updateRecoveryEmail(String value) =>
      state = state.copyWith(recoveryEmail: value, error: null, message: null);
  void updateReset({String? password, String? confirm}) =>
      state = state.copyWith(
        newPassword: password,
        confirmPassword: confirm,
        error: null,
        message: null,
      );
  void updateOtp(String value) =>
      state = state.copyWith(otp: value, error: null, message: null);
  void setOffline(bool value) => state = state.copyWith(simulateOffline: value);
  void clearFeedback() => state = state.copyWith(error: null, message: null);
  void useDemoCredentials() => updateSignIn(
    email: repository.demoEmail,
    password: repository.demoPassword,
  );
  Future<void> setLanguage(String value) async {
    if (!repository.languages.contains(value)) return;
    state = state.copyWith(
      language: value,
      message: 'Language preference saved. Prototype copy remains in English.',
    );
    await _storage.writeString('loginLanguage', value);
  }

  void attachPhoto(String path, Uint8List bytes) => updateRegistration(
    state.registration.copyWith(avatarPath: path, avatarBytes: bytes),
  );
  void reportPhotoUnavailable() => state = state.copyWith(
    message: 'Photo picker unavailable on this device. A profile photo is optional; continue without one.',
  );

  String? _queueOffline(PendingAuthAction action, String origin) {
    if (!state.simulateOffline) return null;
    state = state.copyWith(
      pendingAction: action,
      pendingReturnRoute: origin,
      error: null,
      message: null,
    );
    return '/offline';
  }

  String? _fail(String message) {
    state = state.copyWith(error: message, busy: false, message: null);
    return null;
  }

  void _issueOtp(OtpPurpose purpose) {
    state = state.copyWith(
      flow: purpose,
      otp: '',
      recoveryVerified: false,
      otpExpiresAt: _now.add(const Duration(minutes: 5)),
      resendAllowedAt: _now.add(const Duration(seconds: 30)),
      error: null,
      message: 'DEMO code is available below. No email or SMS was sent.',
    );
  }

  Future<String?> signIn() async {
    if (state.busy) return null;
    final error = AuthValidators.email(state.email);
    if (error != null) return _fail(error);
    if (state.password.isEmpty) return _fail('Enter your password.');
    final offline = _queueOffline(PendingAuthAction.signIn, '/sign-in');
    if (offline != null) return offline;
    try {
      final user = repository.signIn(state.email, state.password);
      state = state.copyWith(busy: true, error: null, message: null);
      final seen = await _storage.readBool('permissionsSeen:${user.email}');
      final savedName = await _storage.readString('profileName:${user.email}');
      final savedAvatar = await _storage.readString(
        'profileAvatar:${user.email}',
      );
      Uint8List? avatar;
      if (savedAvatar != null) {
        try {
          avatar = base64Decode(savedAvatar);
        } catch (_) {
          /* Optional photo. */
        }
      }
      final displayUser = user.copyWith(
        name: savedName?.trim().isNotEmpty == true
            ? savedName!.trim()
            : user.name,
        avatarBytes: avatar,
      );
      if (state.rememberMe) {
        await _storage.writeString('rememberedEmail', user.email);
      } else {
        await _storage.remove('rememberedEmail');
      }
      if (!ref.mounted) return null;
      final required = user.needsPermissions && seen != true;
      state = state.copyWith(
        user: displayUser,
        busy: false,
        permissionsRequired: required,
        pendingAction: null,
        password: '',
        flow: null,
        recoveryVerified: false,
        registration: const RegistrationDraft(),
      );
      return required ? '/permissions' : '/home';
    } on AuthFailure catch (error) {
      return _fail(error.message);
    }
  }

  Future<String?> register() async {
    if (state.busy) return null;
    try {
      repository.validateRegistration(state.registration);
    } on AuthFailure catch (error) {
      return _fail(error.message);
    }
    final offline = _queueOffline(PendingAuthAction.register, '/register');
    if (offline != null) return offline;
    _issueOtp(OtpPurpose.registration);
    return '/otp';
  }

  Future<String?> forgotPassword() async {
    final error = AuthValidators.email(state.recoveryEmail);
    if (error != null) return _fail(error);
    if (!repository.accountExists(state.recoveryEmail)) {
      return _fail('No local demo account uses this email.');
    }
    final offline = _queueOffline(
      PendingAuthAction.forgotPassword,
      '/forgot-password',
    );
    if (offline != null) return offline;
    _issueOtp(OtpPurpose.recovery);
    return '/otp';
  }

  Future<String?> verifyOtp() async {
    if (state.flow == null) return _fail('Request a new demo code first.');
    if (!RegExp(r'^\d{6}$').hasMatch(state.otp)) {
      return _fail('Enter all six digits.');
    }
    if (state.otpExpiresAt == null || !_now.isBefore(state.otpExpiresAt!)) {
      return _fail('This demo code has expired. Resend OTP.');
    }
    if (state.otp != repository.demoOtp) {
      return _fail('Incorrect code. Use the displayed DEMO OTP.');
    }
    final offline = _queueOffline(PendingAuthAction.verifyOtp, '/otp');
    if (offline != null) return offline;
    if (state.flow == OtpPurpose.registration) {
      try {
        repository.registerVerified(state.registration);
      } on AuthFailure catch (error) {
        return _fail(error.message);
      }
      state = state.copyWith(
        email: state.registration.email.trim(),
        password: '',
        flow: null,
        otp: '',
        message: 'Demo account verified. Sign in to continue.',
        error: null,
      );
      return '/sign-in';
    }
    state = state.copyWith(
      recoveryVerified: true,
      otp: '',
      error: null,
      message: null,
    );
    return '/reset-password';
  }

  int get resendSeconds => state.resendAllowedAt == null
      ? 0
      : state.resendAllowedAt!.difference(_now).inSeconds.clamp(0, 30);
  Future<String?> resendOtp() async {
    if (state.flow == null) return _fail('Request a new demo code first.');
    if (_now.isBefore(state.resendAllowedAt ?? _now)) {
      return _fail('Wait ${resendSeconds + 1} seconds before resending.');
    }
    final offline = _queueOffline(PendingAuthAction.resendOtp, '/otp');
    if (offline != null) return offline;
    _issueOtp(state.flow!);
    return '/otp';
  }

  Future<String?> resetPassword() async {
    if (!state.recoveryVerified || state.flow != OtpPurpose.recovery) {
      return _fail('Verify your recovery code first.');
    }
    final error = AuthValidators.password(state.newPassword);
    if (error != null) return _fail(error);
    if (state.newPassword != state.confirmPassword) {
      return _fail('Passwords do not match.');
    }
    final offline = _queueOffline(
      PendingAuthAction.resetPassword,
      '/reset-password',
    );
    if (offline != null) return offline;
    try {
      repository.resetPassword(state.recoveryEmail, state.newPassword);
    } on AuthFailure catch (error) {
      return _fail(error.message);
    }
    state = state.copyWith(
      flow: null,
      recoveryVerified: false,
      email: state.recoveryEmail.trim(),
      password: '',
      newPassword: '',
      confirmPassword: '',
      error: null,
      message: 'Demo password updated. Sign in with your new password.',
    );
    return '/sign-in';
  }

  void restoreConnection() =>
      state = state.copyWith(simulateOffline: false, error: null);
  Future<String?> resumePending() async {
    final action = state.pendingAction;
    final origin = state.pendingReturnRoute;
    state = state.copyWith(pendingAction: null, simulateOffline: false);
    return switch (action) {
      PendingAuthAction.signIn => await signIn(),
      PendingAuthAction.register => await register(),
      PendingAuthAction.forgotPassword => await forgotPassword(),
      PendingAuthAction.verifyOtp => await verifyOtp(),
      PendingAuthAction.resetPassword => await resetPassword(),
      PendingAuthAction.resendOtp => await resendOtp(),
      null => origin,
    };
  }

  String cancelPending() {
    final route = state.pendingReturnRoute;
    state = state.copyWith(
      pendingAction: null,
      simulateOffline: false,
      error: null,
      message: 'Action cancelled. Your form is still here.',
    );
    return route;
  }

  void abandonOtp() => state = state.copyWith(
    flow: null,
    recoveryVerified: false,
    error: null,
    message: null,
  );
  Future<void> requestPermission(String permission) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    final service = ref.read(devicePermissionServiceProvider);
    final result = await switch (permission) {
      'location' => service.requestLocation(),
      'camera' => service.requestCamera(),
      _ => service.requestNotifications(),
    };
    if (!ref.mounted) return;
    state = state.copyWith(
      busy: false,
      permissionStatus: {...state.permissionStatus, permission: result},
    );
  }

  Future<void> completePermissions() async {
    final user = state.user;
    if (user == null || state.busy) return;
    state = state.copyWith(busy: true);
    await _storage.writeBool('permissionsSeen:${user.email}', true);
    if (!ref.mounted) return;
    state = state.copyWith(permissionsRequired: false, busy: false);
  }

  Future<void> saveDemoProfile({
    required String name,
    Uint8List? avatarBytes,
  }) async {
    final user = state.user;
    if (user == null || name.trim().length < 2) return;
    state = state.copyWith(
      user: user.copyWith(name: name.trim(), avatarBytes: avatarBytes),
    );
    await _storage.writeString('profileName:${user.email}', name.trim());
    if (avatarBytes != null && avatarBytes.lengthInBytes < 1024 * 1024) {
      await _storage.writeString(
        'profileAvatar:${user.email}',
        base64Encode(avatarBytes),
      );
    }
  }

  void signOut() => state = state.copyWith(
    user: null,
    permissionsRequired: false,
    password: '',
    registration: const RegistrationDraft(),
    flow: null,
    recoveryVerified: false,
    pendingAction: null,
    simulateOffline: false,
    newPassword: '',
    confirmPassword: '',
    error: null,
    message: 'Signed out of the local demo.',
  );
}
