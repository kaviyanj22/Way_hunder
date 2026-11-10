import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_demo_storage.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../wallet/presentation/viewmodels/wallet_view_model.dart';
import '../../data/repositories/mock_game_repository.dart';
import '../../domain/entities/game_models.dart';
import '../../domain/repositories/game_repository.dart';

final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => MockGameRepository(),
);
final gameCurrentUserIdProvider = Provider<String>(
  (ref) =>
      ref.watch(authViewModelProvider.select((s) => s.user?.id)) ??
      ref.watch(gameRepositoryProvider).load().defaultUserId,
);
typedef GameRewardSink = bool Function({
  required String sourceId,
  required int hp,
  required int rc,
  required String title,
});
final gameRewardSinkProvider = Provider<GameRewardSink>(
  (ref) =>
      ({
        required String sourceId,
        required int hp,
        required int rc,
        required String title,
      }) => ref
          .read(walletViewModelProvider.notifier)
          .creditReward(sourceId: sourceId, hp: hp, rc: rc, title: title),
);
final gameViewModelProvider = NotifierProvider<GameViewModel, GameState>(
  GameViewModel.new,
);

class GameState {
  const GameState({
    required this.userId,
    required this.seed,
    required this.games,
    required this.draft,
    required this.district,
    this.selectedId,
    this.publishedId,
    this.joinedIds = const {},
    this.hintsShown = 1,
    this.proof,
    this.verificationPending = false,
    this.error,
    this.resultMessage,
    this.loading = false,
    this.revision = 0,
  });
  final String userId, district;
  final GameSeed seed;
  final List<GameChallenge> games;
  final GameDraft draft;
  final String? selectedId, publishedId, error, resultMessage;
  final Set<String> joinedIds;
  final int hintsShown, revision;
  final GameEvidence? proof;
  final bool verificationPending, loading;
  GameChallenge? get selected =>
      games.where((g) => g.id == selectedId).firstOrNull;
  GameChallenge? get published =>
      games.where((g) => g.id == publishedId).firstOrNull;
  List<GameChallenge> get districtGames =>
      games.where((g) => g.district == district).toList(growable: false);
  List<GameChallenge> get createdGames =>
      games.where((g) => g.creatorId == userId).toList(growable: false);
  List<GameChallenge> get joinedGames =>
      games.where((g) => joinedIds.contains(g.id)).toList(growable: false);
  List<GameChallenge> get completedGames => games
      .where(
        (g) =>
            g.finished && (g.creatorId == userId || joinedIds.contains(g.id)),
      )
      .toList(growable: false);
  bool get accepted => selectedId != null && joinedIds.contains(selectedId);
  bool get selectedWonByMe => selected?.winnerId == userId;
  GameState copyWith({
    List<GameChallenge>? games,
    GameDraft? draft,
    String? district,
    String? selectedId,
    String? publishedId,
    Set<String>? joinedIds,
    int? hintsShown,
    GameEvidence? proof,
    bool clearProof = false,
    bool? verificationPending,
    String? error,
    bool clearError = false,
    String? resultMessage,
    bool? loading,
    int? revision,
  }) => GameState(
    userId: userId,
    seed: seed,
    games: games ?? this.games,
    draft: draft ?? this.draft,
    district: district ?? this.district,
    selectedId: selectedId ?? this.selectedId,
    publishedId: publishedId ?? this.publishedId,
    joinedIds: joinedIds ?? this.joinedIds,
    hintsShown: hintsShown ?? this.hintsShown,
    proof: clearProof ? null : proof ?? this.proof,
    verificationPending: verificationPending ?? this.verificationPending,
    error: clearError ? null : error ?? this.error,
    resultMessage: resultMessage ?? this.resultMessage,
    loading: loading ?? this.loading,
    revision: revision ?? this.revision,
  );
}

class GameViewModel extends Notifier<GameState> {
  int _generation = 0;
  Future<void> _saveQueue = Future.value();
  @override
  GameState build() {
    final seed = ref.watch(gameRepositoryProvider).load();
    final userId = ref.watch(gameCurrentUserIdProvider);
    final generation = ++_generation;
    Future.microtask(() => _restore(userId, generation));
    return GameState(
      userId: userId,
      seed: seed,
      games: seed.games,
      draft: _blank(seed),
      district: seed.games.firstOrNull?.district ?? seed.districts.first,
      loading: true,
    );
  }

  GameDraft _blank(GameSeed seed) => GameDraft(
    district: seed.districts.first,
    type: seed.types.first,
    rewardHp: seed.defaultRewardHp,
    rewardRc: seed.defaultRewardRc,
    instructions: seed.defaultInstructions,
  );
  Future<void> _restore(String userId, int generation) async {
    try {
      final saved = await ref
          .read(localDemoStorageProvider)
          .readString('games:$userId');
      if (!ref.mounted || generation != _generation) return;
      if (saved != null && state.revision == 0) {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        final games = (json['games'] as List)
            .map(
              (g) =>
                  GameChallenge.fromJson(Map<String, dynamic>.from(g as Map)),
            )
            .toList();
        final joined = (json['joined'] as List).cast<String>().toSet();
        state = state.copyWith(
          games: List.unmodifiable(games),
          joinedIds: Set.unmodifiable(joined),
        );
      }
    } catch (_) {
      // Invalid or unavailable device preferences leave the centralized seed usable.
    }
    if (ref.mounted && generation == _generation) {
      state = state.copyWith(loading: false);
    }
  }

  void _persist() {
    final data = jsonEncode({
      'games': state.games.map((g) => g.toJson()).toList(),
      'joined': state.joinedIds.toList(),
    });
    final key = 'games:${state.userId}';
    final storage = ref.read(localDemoStorageProvider);
    _saveQueue = _saveQueue
        .then((_) => storage.writeString(key, data))
        .catchError((Object _) {});
  }

  void _change(GameState next, {bool persist = false}) {
    state = next.copyWith(revision: state.revision + 1);
    if (persist) _persist();
  }

  bool _fail(String error) {
    state = state.copyWith(error: error);
    return false;
  }

  void clearFeedback() => state = state.copyWith(clearError: true);
  void startCreate() {
    _change(state.copyWith(draft: _blank(state.seed), clearError: true));
  }

  void updateDraft(GameDraft draft) =>
      _change(state.copyWith(draft: draft, clearError: true));
  void attachCreationPhoto(GameEvidence photo) =>
      updateDraft(state.draft.copyWith(photo: photo));
  void retakeCreationPhoto() =>
      updateDraft(state.draft.copyWith(clearPhoto: true));
  bool validateSetup() {
    final error = GameRules.setupError(state.draft, state.seed);
    return error == null ? true : _fail(error);
  }

  bool validatePhoto() => state.draft.photo != null
      ? true
      : _fail('Capture a location photo with the camera first.');
  bool validateRules() {
    final error = GameRules.rulesError(state.draft);
    return error == null ? true : _fail(error);
  }

  bool publish() {
    if (!validateSetup() || !validatePhoto() || !validateRules()) return false;
    final draft = state.draft;
    final game = GameChallenge(
      id: 'local-game-${DateTime.now().microsecondsSinceEpoch}',
      title: draft.title.trim(),
      district: draft.district,
      creatorId: state.userId,
      hint: draft.hint.trim(),
      instructions: draft.instructions.trim(),
      type: draft.type,
      rewardHp: draft.rewardsEnabled ? draft.rewardHp : 0,
      rewardRc: draft.rewardsEnabled ? draft.rewardRc : 0,
      photo: draft.photo,
    );
    _change(
      state.copyWith(
        games: List.unmodifiable([...state.games, game]),
        publishedId: game.id,
        selectedId: game.id,
        clearError: true,
      ),
      persist: true,
    );
    return true;
  }

  void selectDistrict(String district) {
    if (state.seed.districts.contains(district)) {
      _change(state.copyWith(district: district, clearError: true));
    }
  }

  void selectGame(String id) {
    if (!state.games.any((g) => g.id == id)) return;
    _change(
      state.copyWith(
        selectedId: id,
        hintsShown: 1,
        clearProof: true,
        verificationPending: false,
        clearError: true,
      ),
    );
  }

  String acceptSelected() {
    final game = state.selected;
    if (game == null) {
      _fail('Choose a challenge first.');
      return '/game/challenges';
    }
    if (game.winnerId == state.userId) {
      return '/game/victory';
    }
    final error = GameRules.joinError(game, state.userId);
    if (error != null) {
      state = state.copyWith(resultMessage: error, verificationPending: false);
      return '/game/over';
    }
    _change(
      state.copyWith(
        joinedIds: Set.unmodifiable({...state.joinedIds, game.id}),
        clearError: true,
      ),
      persist: true,
    );
    return '/game/find';
  }

  void revealHint() =>
      state = state.copyWith(hintsShown: (state.hintsShown + 1).clamp(1, 3));
  void captureProof(GameEvidence evidence) => _change(
    state.copyWith(
      proof: evidence,
      verificationPending: false,
      clearError: true,
    ),
  );
  void retakeProof() => _change(
    state.copyWith(
      clearProof: true,
      verificationPending: false,
      clearError: true,
    ),
  );
  bool submitProof() {
    final game = state.selected;
    if (game == null || !state.accepted) {
      return _fail('Accept a challenge before submitting evidence.');
    }
    if (game.finished) {
      return _fail('The challenge has ended. Open its result.');
    }
    if (state.proof == null) {
      return _fail(
        'Capture proof with the live camera, or choose the clearly labeled unavailable-device demo.',
      );
    }
    state = state.copyWith(verificationPending: true, clearError: true);
    return true;
  }

  String simulateVerification(GameVerificationOutcome outcome) {
    final game = state.selected;
    if (game == null) return '/game/play';
    if (game.winnerId == state.userId) return '/game/victory';
    if (game.finished) {
      state = state.copyWith(
        resultMessage: 'Another participant already won this challenge.',
        verificationPending: false,
      );
      return '/game/over';
    }
    final joinError = GameRules.joinError(game, state.userId);
    if (joinError != null ||
        !state.accepted ||
        state.proof == null ||
        !state.verificationPending) {
      _fail(
        joinError ??
            'Submit your proof before running the verification demonstration.',
      );
      return '/game/submit';
    }
    if (outcome == GameVerificationOutcome.invalid) {
      state = state.copyWith(
        resultMessage: 'The proof was rejected by the local demonstration. No HP or RC was awarded.',
        verificationPending: false,
      );
      return '/game/over';
    }
    final winner = outcome == GameVerificationOutcome.valid
        ? state.userId
        : state.seed.participantIds.firstWhere(
            (id) => id != state.userId && id != game.creatorId,
          );
    final updated = game.withWinner(winner);
    _change(
      state.copyWith(
        games: List.unmodifiable(
          state.games.map((g) => g.id == game.id ? updated : g),
        ),
        verificationPending: false,
        resultMessage: outcome == GameVerificationOutcome.valid
            ? 'You are the first winner in this local simulation.'
            : 'Another participant won first in this local simulation. No reward was added to your wallet.',
        clearError: true,
      ),
      persist: true,
    );
    if (outcome == GameVerificationOutcome.valid) {
      ref.read(gameRewardSinkProvider)(
        sourceId: 'game-win:${game.id}:${state.userId}',
        hp: game.rewardHp,
        rc: game.rewardRc,
        title: 'Demo game reward: ${game.title}',
      );
      return '/game/victory';
    }
    return '/game/over';
  }
}
