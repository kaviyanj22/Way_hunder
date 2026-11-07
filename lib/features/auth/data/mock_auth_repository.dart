import '../../../core/mock/mock_data.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Only MockData seeds the local account store. User edits live in memory.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    final data = MockData.currentUser;
    final user = AuthUser(
      id: data['id']! as String,
      name: data['name']! as String,
      email: data['email']! as String,
      phone: data['phone']! as String,
      level: data['level']! as int,
      hp: data['hp']! as int,
      rc: data['rc']! as int,
    );
    _accounts[_key(user.email)] = (user: user, password: MockData.demoPassword);
  }
  final _accounts = <String, ({AuthUser user, String password})>{};
  String _key(String email) => email.trim().toLowerCase();
  @override
  String get demoEmail => MockData.demoEmail;
  @override
  String get demoPassword => MockData.demoPassword;
  @override
  String get demoOtp => MockData.demoOtp;
  @override
  List<String> get languages => MockData.languageOptions;
  @override
  bool accountExists(String email) => _accounts.containsKey(_key(email));
  @override
  AuthUser signIn(String email, String password) {
    final account = _accounts[_key(email)];
    if (account == null || account.password != password) {
      throw const AuthFailure('Email or password is incorrect. Try again.');
    }
    return account.user;
  }

  @override
  void validateRegistration(RegistrationDraft draft) {
    final error =
        AuthValidators.name(draft.name) ??
        AuthValidators.email(draft.email) ??
        AuthValidators.phone(draft.phone) ??
        AuthValidators.password(draft.password);
    if (error != null) throw AuthFailure(error);
    if (draft.password != draft.confirm) {
      throw const AuthFailure('Passwords do not match.');
    }
    if (!draft.acceptedTerms) {
      throw const AuthFailure(
        'Agree to the demo Terms & Conditions to continue.',
      );
    }
    if (accountExists(draft.email)) {
      throw const AuthFailure(
        'This email already has a demo account. Sign in instead.',
      );
    }
  }

  @override
  void registerVerified(RegistrationDraft draft) {
    validateRegistration(draft);
    final user = AuthUser(
      id: 'local-${_key(draft.email)}',
      name: draft.name.trim(),
      email: _key(draft.email),
      phone: draft.phone.trim(),
      avatarPath: draft.avatarPath,
      avatarBytes: draft.avatarBytes,
      needsPermissions: true,
    );
    _accounts[_key(draft.email)] = (user: user, password: draft.password);
  }

  @override
  void resetPassword(String email, String password) {
    final account = _accounts[_key(email)];
    if (account == null) {
      throw const AuthFailure('No local demo account uses this email.');
    }
    final error = AuthValidators.password(password);
    if (error != null) throw AuthFailure(error);
    _accounts[_key(email)] = (user: account.user, password: password);
  }
}
