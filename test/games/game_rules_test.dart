import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/features/games/domain/entities/game_models.dart';

void main() {
  const game = GameChallenge(
    id: 'test-game', title: 'Mannar Fort Hunt', district: 'Mannar',
    creatorId: 'creator', hint: 'Old coastal fort',
    instructions: 'Take a live photo', type: 'Treasure Hunt',
    rewardHp: 40, rewardRc: 20,
  );
  test('a creator cannot enter their own game', () {
    expect(GameRules.joinError(game, 'creator'), contains('creator'));
  });
  test('another player can join open game', () {
    expect(GameRules.joinError(game, 'player'), isNull);
  });
  test('no player can join a finished game', () {
    final ended = game.withWinner('winner');
    expect(GameRules.joinError(ended, 'different-player'), contains('ended'));
  });
  test('game setup must have usable title, district and type', () {
    const draft = GameDraft(title: 'Hi', district: 'Mannar', type: 'Treasure Hunt');
    const seed = GameSeed(
      games: [], districts: ['Mannar'], types: ['Treasure Hunt'],
      rankings: [], offers: [], sponsors: [], defaultRewardHp: 40,
      defaultRewardRc: 20, defaultInstructions: 'Take a live photo',
      defaultUserId: 'player', participantIds: [],
    );
    expect(GameRules.setupError(draft, seed), contains('title'));
  });
}
