import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/game_models.dart';
import '../viewmodels/game_view_model.dart';
import 'game_ui.dart';

GameViewModel _vm(WidgetRef ref) => ref.read(gameViewModelProvider.notifier);
void _error(BuildContext context, WidgetRef ref) => showGameMessage(
  context,
  ref.read(gameViewModelProvider).error ?? 'Please check these details.',
);

class GameSetupScreen extends ConsumerWidget {
  const GameSetupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    final draft = state.draft;
    return GameShell(
      title: 'Create Game',
      subtitle: 'Step 1 of 5 · Game Setup',
      child: Column(
        children: [
          GamePageSection(
            title: 'Challenge Details',
            child: Column(
              children: [
                TextFormField(
                  initialValue: draft.title,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Title',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  onChanged: (v) => _vm(ref).updateDraft(
                    ref.read(gameViewModelProvider).draft.copyWith(title: v),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: draft.district,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  isExpanded: true,
                  items: state.seed.districts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      _vm(ref).updateDraft(
                        ref
                            .read(gameViewModelProvider)
                            .draft
                            .copyWith(district: v),
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: draft.type,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Type',
                    prefixIcon: Icon(Icons.games_outlined),
                  ),
                  items: state.seed.types
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      _vm(ref).updateDraft(
                        ref.read(gameViewModelProvider).draft.copyWith(type: v),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          GamePageSection(
            title: 'Winner Reward · Local DEMO',
            child: Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFFFCF45)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '+${draft.rewardHp} HP   +${draft.rewardRc} RC',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GameAction(
            text: 'Continue · Add Location Photo',
            color: gameGreen,
            onTap: () {
              if (_vm(ref).validateSetup()) {
                context.push('/game/create/photo');
              } else {
                _error(context, ref);
              }
            },
          ),
        ],
      ),
    );
  }
}

class GamePhotoScreen extends ConsumerWidget {
  const GamePhotoScreen({super.key});
  Future<void> _take(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1300,
        imageQuality: 83,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      _vm(ref).attachCreationPhoto(GameEvidence(bytes: bytes, path: file.path));
    } catch (e) {
      if (context.mounted) {
        showGameMessage(context, 'Could not access camera/gallery: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(gameViewModelProvider).draft.photo;
    return GameShell(
      title: 'Add Location Photo',
      subtitle: 'Step 2 of 5 · Visual clue',
      child: Column(
        children: [
          GamePageSection(
            title: 'Your challenge photo',
            color: gamePurple,
            child: Column(
              children: [
                Container(
                  height: 195,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black38,
                  ),
                  child: photo?.bytes != null
                      ? Image.memory(photo!.bytes!, fit: BoxFit.cover)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                photo?.demo == true
                                    ? Icons.photo_camera
                                    : Icons.add_photo_alternate_outlined,
                                size: 62,
                                color: gamePurple,
                              ),
                              Text(
                                photo?.demo == true
                                    ? 'DEMO photo attached'
                                    : 'Capture a location picture',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GameAction(
                        text: 'Camera',
                        icon: Icons.camera_alt,
                        color: gameGreen,
                        onTap: () => _take(context, ref, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GameAction(
                        text: 'Gallery',
                        icon: Icons.photo_library_outlined,
                        color: gamePurple,
                        outline: true,
                        onTap: () => _take(context, ref, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      _vm(ref)
                          .attachCreationPhoto(const GameEvidence(demo: true)),
                  icon: const Icon(Icons.smartphone_outlined),
                  label: const Text(
                    'Use clearly labelled DEMO photo (emulator only)',
                  ),
                ),
                if (photo != null)
                  TextButton(
                    onPressed: _vm(ref).retakeCreationPhoto,
                    child: const Text('Retake / Clear photo'),
                  ),
              ],
            ),
          ),
          GameAction(
            text: 'Use This Photo',
            color: gameGreen,
            onTap: () {
              if (_vm(ref).validatePhoto()) {
                context.push('/game/create/hints');
              } else {
                _error(context, ref);
              }
            },
          ),
        ],
      ),
    );
  }
}

class GameHintsScreen extends ConsumerWidget {
  const GameHintsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(gameViewModelProvider).draft;
    return GameShell(
      title: 'Hint & Rules',
      subtitle: 'Step 3 of 5 · Help players search',
      child: Column(
        children: [
          GamePageSection(
            title: 'Challenge clues',
            child: Column(
              children: [
                TextFormField(
                  initialValue: draft.hint,
                  maxLines: 3,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Short Hint',
                    hintText: 'Near the historic fort...',
                  ),
                  onChanged: (s) => _vm(ref).updateDraft(
                    ref.read(gameViewModelProvider).draft.copyWith(hint: s),
                  ),
                ),
                TextFormField(
                  initialValue: draft.instructions,
                  maxLines: 3,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Instructions',
                  ),
                  onChanged: (s) => _vm(ref).updateDraft(
                    ref
                        .read(gameViewModelProvider)
                        .draft
                        .copyWith(instructions: s),
                  ),
                ),
                SwitchListTile(
                  value: draft.rewardsEnabled,
                  title: const Text('Winner Reward'),
                  subtitle: Text(
                    '+${draft.rewardHp} HP / +${draft.rewardRc} RC · DEMO',
                  ),
                  onChanged: (v) => _vm(ref).updateDraft(
                    ref
                        .read(gameViewModelProvider)
                        .draft
                        .copyWith(rewardsEnabled: v),
                  ),
                ),
              ],
            ),
          ),
          GamePageSection(
            title: 'Rules',
            color: gameGreen,
            child: const Text(
              'Creator cannot play their own challenge. First verified participant wins. Live proof is checked using local demo logic. Exact secret coordinates are not revealed.',
            ),
          ),
          GameAction(
            text: 'Continue',
            color: gameGreen,
            onTap: () {
              if (_vm(ref).validateRules()) {
                context.push('/game/create/review');
              } else {
                _error(context, ref);
              }
            },
          ),
        ],
      ),
    );
  }
}

class GameReviewScreen extends ConsumerWidget {
  const GameReviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(gameViewModelProvider).draft;
    return GameShell(
      title: 'Review & Publish',
      subtitle: 'Step 4 of 5 · Confirm challenge',
      child: Column(
        children: [
          GamePageSection(
            title: 'Challenge Summary',
            child: Column(
              children: [
                _detail('Name', draft.title),
                _detail('District', draft.district),
                _detail('Type', draft.type),
                _detail('Hint', draft.hint),
                _detail('Instructions', draft.instructions),
                _detail(
                  'Reward',
                  draft.rewardsEnabled
                      ? '+${draft.rewardHp} HP   +${draft.rewardRc} RC'
                      : 'No reward',
                ),
                _detail(
                  'Photo',
                  draft.photo == null
                      ? 'Missing'
                      : draft.photo!.demo
                      ? 'DEMO photo'
                      : 'Captured photo',
                ),
              ],
            ),
          ),
          GameAction(
            text: 'Edit Details',
            outline: true,
            onTap: () => context.push('/game/create/setup'),
          ),
          const SizedBox(height: 12),
          GameAction(
            text: 'Publish Game · DEMO',
            color: gameGreen,
            onTap: () {
              if (_vm(ref).publish()) {
                context.push('/game/create/published');
              } else {
                _error(context, ref);
              }
            },
          ),
        ],
      ),
    );
  }
}

class GamePublishedScreen extends ConsumerWidget {
  const GamePublishedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameViewModelProvider).published;
    return GameShell(
      title: 'Game Published!',
      subtitle: 'Step 5 of 5',
      child: Column(
        children: [
          GamePageSection(
            title: 'Success · Local DEMO',
            color: gameGreen,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: gameGreen,
                  size: 84,
                ),
                const SizedBox(height: 10),
                Text(
                  game?.title ?? 'Your new challenge',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  game?.district ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your game is stored locally. You cannot play your own game.',
                ),
              ],
            ),
          ),
          GameAction(
            text: 'View My Games',
            color: gameGreen,
            onTap: () => context.go('/game/my-games'),
          ),
          const SizedBox(height: 9),
          GameAction(
            text: 'Back to Game Zone',
            outline: true,
            onTap: () => context.go('/game'),
          ),
        ],
      ),
    );
  }
}

class GamePlayScreen extends ConsumerWidget {
  const GamePlayScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'Play Game',
      subtitle: 'Real location treasure hunt · DEMO',
      child: Column(
        children: [
          GamePageSection(
            title: 'Leaderboard',
            child: Column(
              children: [
                for (final rank in state.seed.rankings.take(3))
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(child: Text('${rank.rank}')),
                    title: Text(rank.name),
                    trailing: Text('${rank.hp} HP'),
                  ),
              ],
            ),
          ),
          GamePageSection(
            title: 'How the challenge works',
            color: gamePurple,
            child: const Text(
              'Choose a district, select an open challenge, follow the clues and submit live photo evidence. First verified winner receives the configured points.',
            ),
          ),
          GameAction(
            text: 'Start Hunt',
            color: gameGreen,
            onTap: () => context.push('/game/district'),
          ),
          const SizedBox(height: 9),
          GameAction(
            text: 'How It Works',
            outline: true,
            onTap: () => context.push('/game/how-to-play'),
          ),
        ],
      ),
    );
  }
}

/// District selection is the first place the Game workflow displays a map.
class GameDistrictScreen extends ConsumerWidget {
  const GameDistrictScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'Select District',
      subtitle: 'Step 2 of 8 · Select a challenge district',
      child: Column(
        children: [
          GamePageSection(
            title: 'Sri Lanka Map',
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 230,
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(7.8700, 80.7700),
                        zoom: 6.8,
                      ),
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      markers: {
                        Marker(
                          markerId: MarkerId('jaffna'),
                          position: LatLng(9.6615, 80.0255),
                          infoWindow: InfoWindow(title: 'Jaffna'),
                        ),
                        Marker(
                          markerId: MarkerId('mannar'),
                          position: LatLng(8.9800, 79.9000),
                          infoWindow: InfoWindow(title: 'Mannar'),
                        ),
                        Marker(
                          markerId: MarkerId('kandy'),
                          position: LatLng(7.2906, 80.6337),
                          infoWindow: InfoWindow(title: 'Kandy'),
                        ),
                        Marker(
                          markerId: MarkerId('colombo'),
                          position: LatLng(6.9271, 79.8612),
                          infoWindow: InfoWindow(title: 'Colombo'),
                        ),
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Map pins are examples, not exact hidden game locations.',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          GamePageSection(
            title: 'Choose District',
            color: gamePurple,
            child: Wrap(
              spacing: 7,
              runSpacing: 4,
              children: [
                for (final district in state.seed.districts)
                  ChoiceChip(
                    label: Text(district),
                    selected: state.district == district,
                    onSelected: (_) => _vm(ref).selectDistrict(district),
                  ),
              ],
            ),
          ),
          GameAction(
            text: 'View District Challenges',
            color: gameGreen,
            onTap: () => context.push('/game/challenges'),
          ),
        ],
      ),
    );
  }
}

class GameChallengesScreen extends ConsumerWidget {
  const GameChallengesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'District Challenges',
      subtitle: state.district,
      child: Column(
        children: [
          for (final game in state.districtGames)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GamePanel(
                color: gamePurple,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${game.district} · +${game.rewardHp} HP · +${game.rewardRc} RC',
                    ),
                    if (game.finished)
                      const Text(
                        'Game Over',
                        style: TextStyle(color: Colors.amber),
                      ),
                    if (game.creatorId == state.userId)
                      const Text(
                        'You created this game',
                        style: TextStyle(color: Colors.amber),
                      ),
                    const SizedBox(height: 8),
                    GameAction(
                      text: 'Choose This Place',
                      color: gameGreen,
                      onTap: () {
                        _vm(ref).selectGame(game.id);
                        context.push('/game/accept');
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (state.districtGames.isEmpty)
            GamePageSection(
              title: 'No challenges yet',
              child: const Text(
                'No local game fixture exists for this district. Choose another district or create a challenge.',
              ),
            ),
          GameAction(
            text: 'Change District',
            outline: true,
            onTap: () => context.push('/game/district'),
          ),
        ],
      ),
    );
  }
}

class GameAcceptScreen extends ConsumerWidget {
  const GameAcceptScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    final game = state.selected;
    return GameShell(
      title: 'Accept Challenge',
      subtitle: 'Step 4 of 8',
      child: Column(
        children: [
          GamePageSection(
            title: game?.title ?? 'Choose a challenge',
            color: gamePurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _detail('District', game?.district ?? '-'),
                _detail('Clue', game?.hint ?? '-'),
                _detail(
                  'Winning Reward',
                  '+${game?.rewardHp ?? 0} HP  +${game?.rewardRc ?? 0} RC',
                ),
                if (game?.creatorId == state.userId)
                  const Text(
                    'You created this game: you cannot play it.',
                    style: TextStyle(color: Colors.amber),
                  ),
                if (game?.finished == true)
                  const Text(
                    'Another player has already won this game.',
                    style: TextStyle(color: Colors.amber),
                  ),
              ],
            ),
          ),
          GameAction(
            text: 'Accept Challenge',
            color: gameGreen,
            onTap: () {
              final target = _vm(ref).acceptSelected();
              context.push(target);
            },
          ),
          const SizedBox(height: 10),
          GameAction(
            text: 'Not Now',
            outline: true,
            onTap: () => context.go('/game/challenges'),
          ),
        ],
      ),
    );
  }
}

class GameFindScreen extends ConsumerWidget {
  const GameFindScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    final game = state.selected;
    return GameShell(
      title: 'Find the Place',
      subtitle: 'Step 5 of 8 · Explore in person',
      child: Column(
        children: [
          GamePageSection(
            title: game?.title ?? 'Challenge',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.explore_outlined, size: 64, color: gamePurple),
                const SizedBox(height: 6),
                Text(
                  game?.hint ?? 'No clue',
                  style: const TextStyle(fontSize: 16),
                ),
                if (state.hintsShown > 1)
                  const Text(
                    'Extra hint (DEMO): Look for a prominent landmark.',
                    style: TextStyle(color: gameGreen),
                  ),
                if (state.hintsShown > 2)
                  const Text(
                    'Extra hint (DEMO): Ask a local about the historic site.',
                    style: TextStyle(color: gameGreen),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'No exact treasure GPS coordinate is shown.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          GameAction(
            text: 'I Found the Place',
            color: gameGreen,
            onTap: () => context.push('/game/proof'),
          ),
          const SizedBox(height: 10),
          GameAction(
            text: 'Need Another Hint',
            outline: true,
            onTap: _vm(ref).revealHint,
          ),
        ],
      ),
    );
  }
}

class GameProofScreen extends ConsumerWidget {
  const GameProofScreen({super.key});
  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (context.mounted) {
        _vm(ref).captureProof(GameEvidence(bytes: bytes, path: file.path));
      }
    } catch (e) {
      if (context.mounted) showGameMessage(context, 'Camera unavailable: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proof = ref.watch(gameViewModelProvider).proof;
    return GameShell(
      title: 'Capture Proof',
      subtitle: 'Step 6 of 8 · Live photo',
      child: Column(
        children: [
          GamePageSection(
            title: 'Live Location Proof',
            color: gamePurple,
            child: Column(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.black45,
                  ),
                  child: proof?.bytes != null
                      ? Image.memory(proof!.bytes!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              color: gamePurple,
                              size: 60,
                            ),
                            Text(
                              proof?.demo == true
                                  ? 'DEMO proof recorded'
                                  : 'Take a live photo',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                GameAction(
                  text: 'Open Camera',
                  color: gameGreen,
                  onTap: () => _capture(context, ref),
                ),
                TextButton(
                  onPressed: () =>
                      _vm(ref).captureProof(const GameEvidence(demo: true)),
                  child: const Text(
                    'Use explicitly labelled DEMO proof (emulator)',
                  ),
                ),
                if (proof != null)
                  TextButton(
                    onPressed: _vm(ref).retakeProof,
                    child: const Text('Retake'),
                  ),
              ],
            ),
          ),
          GameAction(
            text: 'Use This Photo',
            color: gameGreen,
            onTap: () {
              if (ref.read(gameViewModelProvider).proof != null) {
                context.push('/game/submit');
              } else {
                showGameMessage(
                  context,
                  'Capture a photo or choose DEMO proof first.',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class GameSubmitScreen extends ConsumerWidget {
  const GameSubmitScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'Submit Challenge',
      subtitle: 'Step 7 of 8 · Local verification',
      child: Column(
        children: [
          GamePageSection(
            title: 'Proof Status',
            child: Column(
              children: [
                _detail('Challenge', state.selected?.title ?? '-'),
                _detail(
                  'Live photo',
                  state.proof == null
                      ? 'Missing'
                      : state.proof!.demo
                      ? 'DEMO attached'
                      : 'Captured',
                ),
                _detail(
                  'Status',
                  state.verificationPending
                      ? 'Pending local verification'
                      : 'Ready to submit',
                ),
              ],
            ),
          ),
          if (!state.verificationPending)
            GameAction(
              text: 'Submit Challenge',
              color: gameGreen,
              onTap: () {
                if (!_vm(ref).submitProof()) _error(context, ref);
              },
            ),
          if (state.verificationPending) ...[
            const SizedBox(height: 12),
            GamePageSection(
              title: 'Simulate Verification · DEMO',
              color: gamePurple,
              child: Column(
                children: [
                  GameAction(
                    text: 'Valid Proof → Win',
                    color: gameGreen,
                    onTap: () => context.go(
                      _vm(ref)
                          .simulateVerification(GameVerificationOutcome.valid),
                    ),
                  ),
                  const SizedBox(height: 7),
                  GameAction(
                    text: 'Another Player Won → Game Over',
                    outline: true,
                    onTap: () => context.go(
                      _vm(ref).simulateVerification(
                        GameVerificationOutcome.otherWinner,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  GameAction(
                    text: 'Invalid Proof → Game Over',
                    outline: true,
                    onTap: () => context.go(
                      _vm(
                        ref,
                      ).simulateVerification(GameVerificationOutcome.invalid),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Device-only DEMO: real GPS verification and anti-cheat require a backend.',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class GameVictoryScreen extends ConsumerWidget {
  const GameVictoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    final game = state.selected;
    return GameShell(
      title: 'Challenge Complete',
      subtitle: 'Step 8 of 8',
      child: Column(
        children: [
          GamePageSection(
            title: 'You Win! · DEMO',
            color: gameGreen,
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFC72C),
                  size: 90,
                ),
                Text(
                  game?.title ?? 'Victory',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${game?.rewardHp ?? 0} HP    +${game?.rewardRc ?? 0} RC',
                  style: const TextStyle(
                    color: gameGreen,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Game over for all other participants in this local simulation.',
                ),
              ],
            ),
          ),
          GameAction(
            text: 'View Rewards',
            color: gameGreen,
            onTap: () => context.push('/game/rewards'),
          ),
          const SizedBox(height: 8),
          GameAction(
            text: 'Game Zone',
            outline: true,
            onTap: () => context.go('/game'),
          ),
        ],
      ),
    );
  }
}

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'Game Over',
      child: Column(
        children: [
          GamePageSection(
            title: 'Challenge Ended',
            color: gamePurple,
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_disabled,
                  color: Colors.amber,
                  size: 70,
                ),
                const SizedBox(height: 10),
                Text(
                  state.resultMessage ??
                      'This game has ended. No demo points were awarded.',
                ),
              ],
            ),
          ),
          GameAction(
            text: 'Choose Another Game',
            color: gameGreen,
            onTap: () => context.go('/game/district'),
          ),
          const SizedBox(height: 9),
          GameAction(
            text: 'Game Zone',
            outline: true,
            onTap: () => context.go('/game'),
          ),
        ],
      ),
    );
  }
}

class GameMyGamesScreen extends ConsumerWidget {
  const GameMyGamesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'My Games',
      subtitle: 'Created · Joined · Completed',
      child: Column(
        children: [
          _gameList(context, ref, 'Created Games', state.createdGames),
          _gameList(context, ref, 'Joined Games', state.joinedGames),
          _gameList(context, ref, 'Completed Games', state.completedGames),
        ],
      ),
    );
  }
}

Widget _gameList(
  BuildContext context,
  WidgetRef ref,
  String title,
  List<GameChallenge> games,
) => GamePageSection(
  title: title,
  child: games.isEmpty
      ? const Text('No games yet.')
      : Column(
          children: [
            for (final game in games)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(game.title),
                subtitle: Text(
                  '${game.district} · ${game.finished ? 'Ended' : 'Active'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _vm(ref).selectGame(game.id);
                  context.push('/game/accept');
                },
              ),
          ],
        ),
);

class GameLeaderboardScreen extends ConsumerWidget {
  const GameLeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameViewModelProvider);
    return GameShell(
      title: 'Game Leaderboard',
      subtitle: 'Local HP rankings',
      child: GamePageSection(
        title: 'Top Hunters',
        color: gamePurple,
        child: Column(
          children: [
            for (final r in state.seed.rankings)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: gamePurple,
                  child: Text('${r.rank}'),
                ),
                title: Text(r.name),
                trailing: Text('${r.hp} HP'),
              ),
          ],
        ),
      ),
    );
  }
}

class GameRewardsScreen extends ConsumerWidget {
  const GameRewardsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(gameViewModelProvider).seed.offers;
    return GameShell(
      title: 'Rewards Store',
      subtitle: 'Local RC demo offers',
      child: Column(
        children: [
          for (final offer in offers)
            GamePageSection(
              title: offer.name,
              color: gamePurple,
              child: Row(
                children: [
                  Expanded(
                    child: Text('${offer.costRc} RC · LKR ${offer.valueLkr}'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/wallet'),
                    child: const Text('My Wallet →'),
                  ),
                ],
              ),
            ),
          GameAction(
            text: 'Open My Wallet',
            color: gameGreen,
            onTap: () => context.push('/wallet'),
          ),
        ],
      ),
    );
  }
}

class GameHowScreen extends StatelessWidget {
  const GameHowScreen({super.key});
  @override
  Widget build(BuildContext context) => GameShell(
    title: 'How to Play',
    child: GamePageSection(
      title: 'Real-world treasure hunt · Guide',
      color: gamePurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('1. Choose a Sri Lankan district.'),
          SizedBox(height: 10),
          Text('2. Select an available challenge and accept it.'),
          SizedBox(height: 10),
          Text('3. Follow clues to discover the real location.'),
          SizedBox(height: 10),
          Text('4. Take a live photo as proof.'),
          SizedBox(height: 10),
          Text('5. Submit proof; first verified player wins.'),
          SizedBox(height: 10),
          Text('6. The creator cannot join their own game.'),
          SizedBox(height: 10),
          Text('This prototype simulates verification and rewards locally.'),
        ],
      ),
    ),
  );
}

class GameSponsoredScreen extends ConsumerWidget {
  const GameSponsoredScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(gameViewModelProvider).seed.sponsors;
    return GameShell(
      title: 'Sponsored Hunts',
      subtitle: 'Demonstration campaign content',
      child: Column(
        children: [
          for (final sponsor in sponsors)
            GamePageSection(
              title: sponsor.title,
              color: const Color(0xFFFFBC39),
              child: Text(
                '${sponsor.description}\n\nThis is a local mock campaign. No sponsor voucher is issued.',
              ),
            ),
          GameAction(
            text: 'Browse Available Challenges',
            color: gameGreen,
            onTap: () => context.push('/game/district'),
          ),
        ],
      ),
    );
  }
}

Widget _detail(String title, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  ),
);
