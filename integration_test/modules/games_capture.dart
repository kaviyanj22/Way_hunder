import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/features/games/domain/entities/game_models.dart';
import 'package:wayhunter_mobile/features/games/presentation/viewmodels/game_view_model.dart';

import '../screenshot_harness.dart';

Future<void> captureGames(ScreenshotHarness h) async {
  await h.reset();
  var vm = h.container.read(gameViewModelProvider.notifier);
  await _gameShot(h, '01_game_zone.png', 'Game Zone', '/game');
  vm.startCreate();
  await _gameShot(h, '02_create_setup.png', 'Create Game Setup', '/game/create/setup');
  await h.attempt('games', 'Setup validation error', '/game/create/setup', () async {
    await h.go('/game/create/setup');
    await h.tap(find.textContaining('Add Location Photo'));
    await h.capture('games', '03_setup_error.png', 'Create Game setup validation error', '/game/create/setup');
    await h.tap(find.text('OK'));
  });
  final sample = h.container.read(gameViewModelProvider).seed.games.first;
  vm.updateDraft(h.container.read(gameViewModelProvider).draft.copyWith(
    title: sample.title,
    district: sample.district,
    hint: sample.hint,
    instructions: sample.instructions,
  ));
  await _gameShot(h, '04_create_setup_filled.png', 'Create Game filled setup', '/game/create/setup');
  await _gameShot(h, '05_create_photo.png', 'Add Location Photo', '/game/create/photo');
  await h.attempt('games', 'Creation photo required error', '/game/create/photo', () async {
    await h.go('/game/create/photo');
    await h.tap(find.text('Use This Photo'));
    await h.capture('games', '37_creation_photo_missing.png', 'Creation photo required error', '/game/create/photo');
    await h.tap(find.text('OK'));
  });
  vm.attachCreationPhoto(const GameEvidence(demo: true));
  await _gameShot(h, '06_create_photo_attached.png', 'Location DEMO photo attached', '/game/create/photo');
  await _gameShot(h, '07_create_hints.png', 'Hint and Rules', '/game/create/hints');
  vm.updateDraft(h.container.read(gameViewModelProvider).draft.copyWith(hint: ''));
  await h.attempt('games', 'Hint required error', '/game/create/hints', () async {
    await h.go('/home');
    await h.go('/game/create/hints');
    await h.tap(find.text('Continue'));
    await h.capture('games', '38_hint_missing.png', 'Hint required error', '/game/create/hints');
    await h.tap(find.text('OK'));
  });
  vm.updateDraft(h.container.read(gameViewModelProvider).draft.copyWith(hint: sample.hint));
  vm.updateDraft(h.container.read(gameViewModelProvider).draft.copyWith(rewardsEnabled: false));
  await _gameShot(h, '08_create_rewards_off.png', 'Hint and Rules reward disabled', '/game/create/hints');
  vm.updateDraft(h.container.read(gameViewModelProvider).draft.copyWith(rewardsEnabled: true));
  await _gameShot(h, '09_create_review.png', 'Review and Publish', '/game/create/review');
  expect(vm.publish(), isTrue);
  await _gameShot(h, '10_create_published.png', 'Game Published', '/game/create/published');
  await _gameShot(h, '11_my_games_created.png', 'My Games with created challenge', '/game/my-games');
  await _gameShot(h, '12_own_challenge_preview.png', 'Own challenge preview', '/game/accept');
  final ownResult = vm.acceptSelected();
  expect(ownResult, '/game/over');
  await _gameShot(h, '13_own_game_blocked.png', 'Creator cannot join own challenge', ownResult);

  await _gameShot(h, '14_play_landing.png', 'Play Game', '/game/play');
  await _gameShot(h, '15_select_district.png', 'Select District', '/game/district');
  vm.selectDistrict(sample.district);
  await _gameShot(h, '16_challenges.png', 'District Challenges', '/game/challenges');
  final emptyDistrict = h.container.read(gameViewModelProvider).seed.districts
      .where((d) => !h.container.read(gameViewModelProvider).games.any((g) => g.district == d)).firstOrNull;
  if (emptyDistrict != null) {
    vm.selectDistrict(emptyDistrict);
    await _gameShot(h, '17_challenges_empty.png', 'District with no challenges', '/game/challenges');
    vm.selectDistrict(sample.district);
  }
  vm.selectGame(sample.id);
  await _gameShot(h, '18_accept_challenge.png', 'Accept Challenge', '/game/accept');
  expect(vm.acceptSelected(), '/game/find');
  await _gameShot(h, '19_find_place.png', 'Find the Place', '/game/find');
  vm.revealHint();
  await _gameShot(h, '20_second_hint.png', 'Find the Place second hint', '/game/find');
  vm.revealHint();
  await _gameShot(h, '21_all_hints.png', 'Find the Place all hints', '/game/find');
  await _gameShot(h, '22_capture_proof.png', 'Capture Proof', '/game/proof');
  await h.attempt('games', 'Proof required error', '/game/proof', () async {
    await h.go('/game/proof');
    await h.tap(find.text('Use This Photo'));
    await h.capture('games', '23_proof_missing.png', 'Capture Proof missing evidence error', '/game/proof');
    await h.tap(find.text('OK'));
  });
  vm.captureProof(const GameEvidence(demo: true));
  await _gameShot(h, '24_proof_attached.png', 'DEMO proof attached', '/game/proof');
  await _gameShot(h, '25_submit_ready.png', 'Submit Challenge ready', '/game/submit');
  expect(vm.submitProof(), isTrue);
  await _gameShot(h, '26_verification_pending.png', 'Local verification pending', '/game/submit');
  final invalidResult = vm.simulateVerification(GameVerificationOutcome.invalid);
  await _gameShot(h, '27_invalid_proof_game_over.png', 'Invalid proof Game Over', invalidResult);
  vm.captureProof(const GameEvidence(demo: true));
  expect(vm.submitProof(), isTrue);
  final victoryResult = vm.simulateVerification(GameVerificationOutcome.valid);
  await _gameShot(h, '28_victory.png', 'First winner Victory DEMO', victoryResult);
  await _gameShot(h, '29_my_games_completed.png', 'My Games with completed challenge', '/game/my-games');
  await _gameShot(h, '30_challenge_ended.png', 'Ended challenge preview', '/game/accept');

  // A clean isolated run exercises the mutually exclusive other-winner branch.
  await h.reset();
  vm = h.container.read(gameViewModelProvider.notifier);
  await h.go('/game');
  final other = h.container.read(gameViewModelProvider).seed.games.first;
  vm.selectGame(other.id);
  expect(vm.acceptSelected(), '/game/find');
  vm.captureProof(const GameEvidence(demo: true));
  expect(vm.submitProof(), isTrue);
  final otherResult = vm.simulateVerification(GameVerificationOutcome.otherWinner);
  await _gameShot(h, '31_another_winner_game_over.png', 'Another player won Game Over', otherResult);
  await _gameShot(h, '32_ended_challenge_preview.png', 'Another-winner challenge preview', '/game/accept');
  await _gameShot(h, '33_leaderboard.png', 'Game Leaderboard', '/game/leaderboard');
  await _gameShot(h, '34_rewards_store.png', 'Game Rewards Store', '/game/rewards');
  await _gameShot(h, '35_how_to_play.png', 'How to Play', '/game/how-to-play');
  await _gameShot(h, '36_sponsored.png', 'Sponsored Hunts', '/game/sponsored');
}

Future<void> _gameShot(ScreenshotHarness h, String file, String title, String route) =>
    h.attempt('games', title, route, () async {
      // TextFormField initialValue is read when the existing form mounts.
      if (h.router.routeInformationProvider.value.uri.toString() == route) {
        await h.go('/home');
      }
      await h.go(route);
      await h.capture('games', file, title, route);
    });
