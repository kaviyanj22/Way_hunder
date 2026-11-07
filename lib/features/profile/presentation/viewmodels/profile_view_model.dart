import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_demo_storage.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// Editable profile fields that live only on the user's device.
class LocalProfileDetails {
  const LocalProfileDetails({
    this.bio = 'Traveller | Explorer | Nature Lover',
    this.location = 'Jaffna, Sri Lanka',
    this.language = 'English',
    this.publicProfile = true,
    this.notifications = MockData.notificationPreferences,
  });

  final String bio, location, language;
  final bool publicProfile;
  final Map<String, bool> notifications;

  LocalProfileDetails copyWith({
    String? bio,
    String? location,
    String? language,
    bool? publicProfile,
    Map<String, bool>? notifications,
  }) => LocalProfileDetails(
    bio: bio ?? this.bio,
    location: location ?? this.location,
    language: language ?? this.language,
    publicProfile: publicProfile ?? this.publicProfile,
    notifications: notifications ?? this.notifications,
  );
}

final profileDetailsProvider =
    NotifierProvider<ProfileDetailsViewModel, LocalProfileDetails>(
      ProfileDetailsViewModel.new,
    );

class ProfileDetailsViewModel extends Notifier<LocalProfileDetails> {
  int _revision = 0;

  String _key(String userId) => 'wayhunter-profile-details:$userId';

  @override
  LocalProfileDetails build() {
    final userId = ref.watch(authViewModelProvider.select((s) => s.user?.id));
    final revision = ++_revision;
    if (userId != null) {
      Future.microtask(() async {
        final value = await ref
            .read(localDemoStorageProvider)
            .readString(_key(userId));
        if (!ref.mounted || revision != _revision || value == null) return;
        try {
          final raw = Map<String, dynamic>.from(jsonDecode(value) as Map);
          state = LocalProfileDetails(
            bio: raw['bio'] as String? ?? state.bio,
            location: raw['location'] as String? ?? state.location,
            language: raw['language'] as String? ?? state.language,
            publicProfile: raw['public'] as bool? ?? state.publicProfile,
            notifications: {
              ...state.notifications,
              ...Map<String, bool>.from(raw['notifications'] as Map? ?? {}),
            },
          );
        } catch (_) {
          /* Ignore malformed local preferences. */
        }
      });
    }
    return const LocalProfileDetails();
  }

  Future<void> update({
    String? bio,
    String? location,
    String? language,
    bool? publicProfile,
    Map<String, bool>? notifications,
  }) async {
    state = state.copyWith(
      bio: bio,
      location: location,
      language: language,
      publicProfile: publicProfile,
      notifications: notifications,
    );
    _revision++;
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null) return;
    await ref
        .read(localDemoStorageProvider)
        .writeString(
          _key(userId),
          jsonEncode({
            'bio': state.bio,
            'location': state.location,
            'language': state.language,
            'public': state.publicProfile,
            'notifications': state.notifications,
          }),
        );
  }
}
