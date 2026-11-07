import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/game_models.dart';
import '../../domain/repositories/game_repository.dart';

class MockGameRepository implements GameRepository {
  @override
  GameSeed load() => GameSeed(
    games: List.unmodifiable(
      MockData.games.map(
        (game) => GameChallenge(
          id: game['id'] as String,
          title: game['title'] as String,
          district: game['district'] as String,
          creatorId: game['creatorId'] as String,
          hint: game['hint'] as String,
          instructions: MockData.gameDefaultInstructions,
          type: MockData.gameChallengeTypes.first,
          rewardHp: game['rewardHp'] as int,
          rewardRc: game['rewardRc'] as int,
        ),
      ),
    ),
    districts: MockData.districtNames,
    types: MockData.gameChallengeTypes,
    rankings: List.unmodifiable(
      MockData.leaderboard.map(
        (r) => GameRanking(
          name: r['name'] as String,
          rank: r['rank'] as int,
          hp: r['hp'] as int,
        ),
      ),
    ),
    offers: List.unmodifiable(
      MockData.rewards.map(
        (r) => GameOffer(
          id: r['id'] as String,
          name: r['name'] as String,
          costRc: r['costRc'] as int,
          valueLkr: r['valueLkr'] as int,
        ),
      ),
    ),
    sponsors: List.unmodifiable(
      MockData.advertisements.map(
        (s) => GameSponsor(
          title: s['title'] as String,
          description: s['description'] as String,
        ),
      ),
    ),
    defaultRewardHp: MockData.gameDefaultRewardHp,
    defaultRewardRc: MockData.gameDefaultRewardRc,
    defaultInstructions: MockData.gameDefaultInstructions,
    defaultUserId: MockData.currentUser['id'] as String,
    participantIds: List.unmodifiable(
      MockData.groupMembers.map((member) => member['userId'] as String),
    ),
  );
}
