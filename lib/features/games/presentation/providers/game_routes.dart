import 'package:go_router/go_router.dart';

import '../views/game_zone_screen.dart';
import '../views/game_flow_screens.dart';

/// Complete local-only Game navigation, separate from Traveller and Hunter.
final gameRoutes = <RouteBase>[
  GoRoute(path: '/game', builder: (_, _) => const GameZoneScreen()),
  GoRoute(
    path: '/game/create/setup',
    builder: (_, _) => const GameSetupScreen(),
  ),
  GoRoute(
    path: '/game/create/photo',
    builder: (_, _) => const GamePhotoScreen(),
  ),
  GoRoute(
    path: '/game/create/hints',
    builder: (_, _) => const GameHintsScreen(),
  ),
  GoRoute(
    path: '/game/create/review',
    builder: (_, _) => const GameReviewScreen(),
  ),
  GoRoute(
    path: '/game/create/published',
    builder: (_, _) => const GamePublishedScreen(),
  ),
  GoRoute(path: '/game/play', builder: (_, _) => const GamePlayScreen()),
  GoRoute(
    path: '/game/district',
    builder: (_, _) => const GameDistrictScreen(),
  ),
  GoRoute(
    path: '/game/challenges',
    builder: (_, _) => const GameChallengesScreen(),
  ),
  GoRoute(path: '/game/accept', builder: (_, _) => const GameAcceptScreen()),
  GoRoute(path: '/game/find', builder: (_, _) => const GameFindScreen()),
  GoRoute(path: '/game/proof', builder: (_, _) => const GameProofScreen()),
  GoRoute(path: '/game/submit', builder: (_, _) => const GameSubmitScreen()),
  GoRoute(path: '/game/victory', builder: (_, _) => const GameVictoryScreen()),
  GoRoute(path: '/game/over', builder: (_, _) => const GameOverScreen()),
  GoRoute(path: '/game/my-games', builder: (_, _) => const GameMyGamesScreen()),
  GoRoute(
    path: '/game/leaderboard',
    builder: (_, _) => const GameLeaderboardScreen(),
  ),
  GoRoute(path: '/game/rewards', builder: (_, _) => const GameRewardsScreen()),
  GoRoute(path: '/game/how-to-play', builder: (_, _) => const GameHowScreen()),
  GoRoute(
    path: '/game/sponsored',
    builder: (_, _) => const GameSponsoredScreen(),
  ),
];
