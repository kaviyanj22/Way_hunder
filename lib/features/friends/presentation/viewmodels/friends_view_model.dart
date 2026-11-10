import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_demo_storage.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// Prototype social data. Accounts in another device are not contacted yet.
class FriendsState {
  const FriendsState({
    this.following = const {
      'demo-kaviyan',
      'demo-anusha',
      'demo-thuvarathan',
      'demo-explorer',
    },
    this.followers = const {
      'demo-kaviyan',
      'demo-anusha',
      'demo-thuvarathan',
      'demo-niroshan',
    },
    this.received = const {'demo-dilan', 'demo-ishara', 'demo-meena'},
    this.sent = const {'demo-ravindu'},
  });

  final Set<String> following;
  final Set<String> followers;
  final Set<String> received;
  final Set<String> sent;
  int get mutualFriendsCount => following.intersection(followers).length;

  FriendsState copyWith({
    Set<String>? following,
    Set<String>? followers,
    Set<String>? received,
    Set<String>? sent,
  }) => FriendsState(
    following: following ?? this.following,
    followers: followers ?? this.followers,
    received: received ?? this.received,
    sent: sent ?? this.sent,
  );
}

final friendsViewModelProvider =
    NotifierProvider<FriendsViewModel, FriendsState>(FriendsViewModel.new);

class FriendsViewModel extends Notifier<FriendsState> {
  int _revision = 0;
  String _key(String userId) => 'wayhunter-profile-friends-demo:$userId';

  @override
  FriendsState build() {
    final userId = ref.watch(authViewModelProvider.select((s) => s.user?.id));
    final revision = ++_revision;
    if (userId != null) {
      Future.microtask(() async {
        final raw = await ref
            .read(localDemoStorageProvider)
            .readString(_key(userId));
        if (!ref.mounted || revision != _revision || raw == null) return;
        try {
          final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          state = FriendsState(
            following: Set<String>.from(json['following'] as List? ?? const []),
            followers: Set<String>.from(json['followers'] as List? ?? const []),
            received: Set<String>.from(json['received'] as List? ?? const []),
            sent: Set<String>.from(json['sent'] as List? ?? const []),
          );
        } catch (_) {
          // Keep demo defaults if the local cache is invalid.
        }
      });
    }
    return const FriendsState();
  }

  void _store(FriendsState next) {
    state = next;
    ++_revision;
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null) return;
    final snapshot = jsonEncode({
      'following': state.following.toList(),
      'followers': state.followers.toList(),
      'received': state.received.toList(),
      'sent': state.sent.toList(),
    });
    Future.microtask(
      () => ref
          .read(localDemoStorageProvider)
          .writeString(_key(userId), snapshot),
    );
  }

  void request(String id) {
    if (state.following.contains(id) || state.sent.contains(id)) return;
    _store(state.copyWith(sent: {...state.sent, id}));
  }

  void accept(String id) {
    if (!state.received.contains(id)) return;
    _store(
      state.copyWith(
        received: {...state.received}..remove(id),
        following: {...state.following, id},
        followers: {...state.followers, id},
      ),
    );
  }

  void decline(String id) =>
      _store(state.copyWith(received: {...state.received}..remove(id)));
  void cancelSent(String id) =>
      _store(state.copyWith(sent: {...state.sent}..remove(id)));
  void unfollow(String id) =>
      _store(state.copyWith(following: {...state.following}..remove(id)));
}
