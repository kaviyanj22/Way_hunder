import '../views/fixed_trip_forms.dart';
import 'package:go_router/go_router.dart';

import '../views/traveller_screens.dart';
import '../views/active_trip_dashboard.dart';

final List<RouteBase> travellerRoutes = [
  GoRoute(
    path: '/traveller',
    builder: (_, s) =>
        TravellerLandingScreen(placeId: s.uri.queryParameters['place']),
  ),
  GoRoute(
    path: '/traveller/create',
    builder: (_, _) => const TripBuilderScreen(),
  ),
  GoRoute(
    path: '/traveller/review',
    builder: (_, _) => const RouteReviewScreen(),
  ),
  GoRoute(path: '/traveller/ai', builder: (_, _) => const AiTripPlanScreen()),
  GoRoute(
    path: '/traveller/reuse',
    builder: (_, _) => const PreviousTravellerPlanScreen(),
  ),
  GoRoute(path: '/traveller/plans', builder: (_, _) => const MyPlansScreen()),
  GoRoute(
    path: '/traveller/active',
    builder: (_, _) => const ActiveTripDashboard(),
  ),
  GoRoute(
    path: '/traveller/nearby',
    builder: (_, _) => const NearbyPlacesScreen(),
  ),
  GoRoute(
    path: '/traveller/road-alert',
    builder: (_, _) => const RoadAlertScreen(),
  ),
  GoRoute(
    path: '/traveller/hazard',
    builder: (_, _) => const FixedHazardReportScreen(),
  ),
  GoRoute(
    path: '/traveller/memories',
    builder: (_, _) => const FixedAddMemoriesScreen(),
  ),
  GoRoute(
    path: '/traveller/friends',
    builder: (_, _) => const TripFriendsScreen(),
  ),
  GoRoute(
    path: '/traveller/invites',
    builder: (_, _) => const GroupInvitationsScreen(),
  ),
  GoRoute(
    path: '/traveller/finish',
    builder: (_, state) =>
        FinishTripScreen(tripId: state.uri.queryParameters['id']),
  ),
];
