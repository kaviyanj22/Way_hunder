import 'dart:typed_data';

/// A local prototype identity. This is never a production security principal.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.level = 1,
    this.hp = 0,
    this.rc = 0,
    this.avatarPath,
    this.avatarBytes,
    this.needsPermissions = false,
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  final int level;
  final int hp;
  final int rc;
  final String? avatarPath;
  final Uint8List? avatarBytes;
  final bool needsPermissions;

  AuthUser copyWith({String? name, Uint8List? avatarBytes}) => AuthUser(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone,
    level: level,
    hp: hp,
    rc: rc,
    avatarPath: avatarPath,
    avatarBytes: avatarBytes ?? this.avatarBytes,
    needsPermissions: needsPermissions,
  );
}

class RegistrationDraft {
  const RegistrationDraft({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirm = '',
    this.acceptedTerms = false,
    this.avatarPath,
    this.avatarBytes,
  });
  final String name;
  final String email;
  final String phone;
  final String password;
  final String confirm;
  final bool acceptedTerms;
  final String? avatarPath;
  final Uint8List? avatarBytes;

  RegistrationDraft copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
    String? confirm,
    bool? acceptedTerms,
    String? avatarPath,
    Uint8List? avatarBytes,
  }) => RegistrationDraft(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    password: password ?? this.password,
    confirm: confirm ?? this.confirm,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    avatarPath: avatarPath ?? this.avatarPath,
    avatarBytes: avatarBytes ?? this.avatarBytes,
  );
}
