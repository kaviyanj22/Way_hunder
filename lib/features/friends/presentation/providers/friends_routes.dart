import 'package:go_router/go_router.dart';

import '../views/friends_screens.dart';

/// New Profile Friends routes. Does not replace the existing active-trip Friends route.
final List<RouteBase> friendsRoutes = [
  GoRoute(path: '/friends', builder: (_, _) => const FriendsHubScreen()),
  GoRoute(
    path: '/friends/followers',
    builder: (_, _) => const FollowersListScreen(),
  ),
  GoRoute(
    path: '/friends/following',
    builder: (_, _) => const FollowingListScreen(),
  ),
  GoRoute(
    path: '/friends/discover',
    builder: (_, _) => const DiscoverFriendsScreen(),
  ),
  GoRoute(
    path: '/friends/requests',
    builder: (_, _) => const FriendRequestsScreen(),
  ),
  GoRoute(
    path: '/friends/contacts',
    builder: (_, _) => const MyContactsDemoScreen(),
  ),
  GoRoute(
    path: '/friends/trip-selection',
    builder: (_, state) => TripAddFriendsScreen(
      initial: state.extra is List<String>
          ? state.extra! as List<String>
          : const <String>[],
    ),
  ),
];
