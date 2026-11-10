import 'package:go_router/go_router.dart';

import '../views/hunter_start_screens.dart';
import '../views/hunter_evidence_screens.dart';
import '../views/hunter_rewards_screens.dart';

/// All Hunter user journeys, including alternate GPS/duplicate/retake states.
final hunterRoutes = <RouteBase>[
  GoRoute(path: '/hunter', builder: (_, _) => const HunterHomeScreen()),
  GoRoute(path: '/hunter/add', builder: (_, _) => const AddNewPlaceScreen()),
  GoRoute(path: '/hunter/gps', builder: (_, _) => const HunterGpsScreen()),
  GoRoute(path: '/hunter/duplicate', builder: (_, _) => const HunterDuplicateScreen()),
  GoRoute(path: '/hunter/camera360', builder: (_, _) => const Hunter360CameraScreen()),
  GoRoute(path: '/hunter/video-complete', builder: (_, _) => const HunterVideoCompleteScreen()),
  GoRoute(path: '/hunter/video-attached', builder: (_, _) => const AddNewPlaceScreen(videoAttached: true)),
  GoRoute(path: '/hunter/photo-camera', builder: (_, _) => const HunterNormalPhotoCameraScreen()),
  GoRoute(path: '/hunter/review', builder: (_, _) => const HunterReviewScreen()),
  GoRoute(path: '/hunter/verification', builder: (_, _) => const HunterVerificationScreen()),
  GoRoute(path: '/hunter/rewards', builder: (_, _) => const HunterRewardsScreen()),
  GoRoute(path: '/hunter/leaderboard', builder: (_, _) => const HunterLeaderboardScreen()),
  GoRoute(path: '/hunter/admin-review', builder: (_, _) => const HunterAdminDemoScreen()),
];
