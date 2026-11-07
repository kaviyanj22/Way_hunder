import 'auth_user.dart';

abstract interface class AuthRepository {
  String get demoEmail;
  String get demoPassword;
  String get demoOtp;
  List<String> get languages;
  AuthUser signIn(String email, String password);
  bool accountExists(String email);
  void validateRegistration(RegistrationDraft draft);
  void registerVerified(RegistrationDraft draft);
  void resetPassword(String email, String password);
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract final class AuthValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email.';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address.';
  }

  static String? password(String? value) =>
      value == null || value.length < 8 ? 'Use at least 8 characters.' : null;
  static String? name(String? value) =>
      value == null || value.trim().length < 2 ? 'Enter your full name.' : null;
  static String? phone(String? value) =>
      value == null || value.replaceAll(RegExp(r'\D'), '').length < 9
      ? 'Enter a valid phone number.'
      : null;
}
