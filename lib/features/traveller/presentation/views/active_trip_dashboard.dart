import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../viewmodels/traveller_view_model.dart';
import '../viewmodels/traveller_map_view_model.dart';
import '../widgets/traveller_map.dart';

/// Fixed-height active journey home. Only the Google map can pan/zoom;
/// the main page is intentionally NOT inside a vertical scroll view.
/// All route distances, nearby counts and trip progression are DEMO data.
class ActiveTripDashboard extends ConsumerWidget {
  const ActiveTripDashboard({super.key});

  static const Color _cyan = WayhunterPalette.travellerCyan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travellerViewModelProvider);
    final trip = state.active;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/traveller/plans'),
            icon: const Icon(Icons.route),
            label: const Text('Open My Plans'),
          ),
        ),
      );
    }
    final vm = ref.read(travellerViewModelProvider.notifier);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: _cyan),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Image.asset(AppAssets.homeBackground, fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xAA00121E), Color(0xD9001220)],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            bottomNavigationBar: const _TripBottomNavigation(),
            body: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final compact = viewport.maxHeight < 680;
                  final gap = compact ? 5.0 : 8.0;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(9, 0, 9, gap),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(context, compact),
                            SizedBox(height: gap),
                            _tripSummary(context, trip, state, compact),
                            SizedBox(height: gap),
                            // Expanded is the only dynamically sized section.
                            Expanded(
                              child: _mapPanel(
                                context,
                                ref,
                                trip,
                                state,
                                compact,
                              ),
                            ),
                            SizedBox(height: gap),
                            SizedBox(
                              height: compact ? 73 : 88,
                              child: Row(
                                children: [
                                  _action(
                                    Icons.search_rounded,
                                    'Find',
                                    'Nearby',
                                    const Color(0xFF04B5D9),
                                    () {
                                      vm.loadNearby();
                                      context.go('/traveller/nearby');
                                    },
                                  ),
                                  _action(
                                    Icons.warning_amber_rounded,
                                    'Report Hazard',
                                    'Road safety',
                                    const Color(0xFFE09A1B),
                                    () => context.go('/traveller/hazard'),
                                  ),
                                  _action(
                                    Icons.camera_alt_outlined,
                                    'Add Memories',
                                    'Photo / video',
                                    const Color(0xFFA657E9),
                                    () => context.go('/traveller/memories'),
                                  ),
                                  _action(
                                    Icons.groups_outlined,
                                    'Friends',
                                    'Trip group',
                                    const Color(0xFF1EB663),
                                    () => context.go('/traveller/friends'),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: gap),
                            _nearbyStrip(context, compact),
                            SizedBox(height: gap),
                            _roadPrompt(context, compact),
                            SizedBox(height: gap),
                            SizedBox(
                              height: compact ? 34 : 41,
                              child: OutlinedButton.icon(
                                key: const ValueKey('trip-end'),
                                onPressed: () =>
                                    context.go('/traveller/finish'),
                                icon: const Icon(Icons.flag_outlined, size: 19),
                                label: const Text('Finish Trip / Save Summary'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: _cyan),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, bool compact) => SizedBox(
    height: compact ? 42 : 49,
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back to My Plans',
          onPressed: () => context.go('/traveller/plans'),
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'WAYHUNTER',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              Text(
                'ACTIVE TRIP · LOCAL DEMO',
                style: TextStyle(fontSize: compact ? 8 : 10, color: _cyan),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    ),
  );

  Widget _tripSummary(
    BuildContext context,
    TripPlan trip,
    TravellerState state,
    bool compact,
  ) {
    final dates =
        '${DateFormat('dd MMM').format(trip.startDate)} – ${DateFormat('dd MMM yyyy').format(trip.endDate)}';
    return GlassPanel(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 8 : 11),
      child: Row(
        children: [
          Container(
            width: compact ? 43 : 56,
            height: compact ? 53 : 62,
            decoration: BoxDecoration(
              color: const Color(0xD900526A),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _cyan),
            ),
            child: const Icon(
              Icons.landscape_outlined,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(dates, style: TextStyle(fontSize: compact ? 10 : 11)),
                Text(
                  trip.stops.join(' → '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9EE8F5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          TextButton(
            onPressed: () => context.go('/traveller/finish'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: _cyan,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Text('Details', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _mapPanel(
    BuildContext context,
    WidgetRef ref,
    TripPlan trip,
    TravellerState state,
    bool compact,
  ) => ClipRRect(
    borderRadius: BorderRadius.circular(21),
    child: Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, box) => TravellerMap(
            height: box.maxHeight,
            compact: true,
            routePoints: state.pointsFor(trip.stops),
            alternative: state.alternateRoute,
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: _mapBadge(
            'LIVE TRIP · DEMO',
            Icons.wifi_tethering,
            Colors.green,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: const Color(0xDA062439),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Enable current GPS location',
              onPressed: () => ref
                  .read(travellerMapViewModelProvider.notifier)
                  .enableMyLocation(),
              icon: const Icon(Icons.my_location, color: Colors.white),
              iconSize: 23,
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 115 : 136),
            child: GlassPanel(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  for (var i = 0; i < trip.stops.length && i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            i <= state.progress
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 12,
                            color: i <= state.progress
                                ? Colors.greenAccent
                                : _cyan,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              trip.stops[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextButton(
                    onPressed: state.progress < trip.stops.length - 1
                        ? ref.read(travellerViewModelProvider.notifier).nextStop
                        : null,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Next stop (DEMO)',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mapBadge(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xED042739),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _action(
    IconData icon,
    String title,
    String subtitle,
    Color accent,
    VoidCallback onTap,
  ) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: const Color(0xB0072638),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: accent, width: 1.5),
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          key: ValueKey(
            "active-action-${title.toLowerCase().replaceAll(' ', '-')}",
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: 21),
                const SizedBox(height: 1),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8, color: Color(0xFFBED7E0)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _nearbyStrip(BuildContext context, bool compact) => GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    child: Row(
      children: [
        const Icon(Icons.place_outlined, size: 17, color: _cyan),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            'Nearby Places · within 1 km (DEMO)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/traveller/nearby'),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(
            compact ? 'View' : 'View All →',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Widget _roadPrompt(BuildContext context, bool compact) => Material(
    color: const Color(0xD305524E),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      key: const ValueKey('active-road-alert'),
      onTap: () => context.go('/traveller/road-alert'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.alt_route, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                compact
                    ? 'Route & road alerts (DEMO)'
                    : 'Route preview · road alerts and alternatives (DEMO)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class _TripBottomNavigation extends StatelessWidget {
  const _TripBottomNavigation();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: NavigationBar(
          height: 61,
          selectedIndex: 1,
          backgroundColor: const Color(0xE0052032),
          indicatorColor: WayhunterPalette.travellerCyan.withValues(alpha: .25),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(icon: Icon(Icons.hiking), label: 'Traveller'),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Leaderboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          onDestinationSelected: (index) => context.go(switch (index) {
            0 => '/home',
            1 => '/traveller',
            2 => '/leaderboard',
            _ => '/profile',
          }),
        ),
      ),
    ),
  );
}
