import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

export 'trip_builder_screen.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/evidence_capture.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/module_scaffold.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../domain/entities/traveller_map_data.dart';
import '../viewmodels/traveller_view_model.dart';
import '../widgets/traveller_map.dart';

String _date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
Widget _gap([double h = 14]) => SizedBox(height: h);
Widget _panel(String title, List<Widget> children) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: GlassPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        _gap(),
        ...children,
      ],
    ),
  ),
);
Widget _feedback(TravellerState s) => Column(
  children: [
    if (s.error != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          liveRegion: true,
          child: Text(
            s.error!,
            style: const TextStyle(color: Color(0xFFFFA8B5)),
          ),
        ),
      ),
    if (s.message != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          s.message!,
          style: const TextStyle(color: Color(0xFF8BE5FF)),
        ),
      ),
  ],
);
Widget _page(
  String title,
  Widget child, {
  String? subtitle,
  String back = '/traveller',
}) => ModuleScaffold(
  title: title,
  subtitle: subtitle,
  backRoute: back,
  module: WayhunterModule.traveller,
  child: child,
);
Widget _routeMap(
  TravellerState s,
  List<String> stops, {
  List<TravellerMapMarker> extra = const [],
}) => TravellerMap(
  routePoints: s.pointsFor(stops),
  extraMarkers: extra,
  alternative: s.alternateRoute,
);
Widget _summary(TripPlan p) => _panel(p.title, [
  Text('${_date(p.startDate)} – ${_date(p.endDate)} · ${p.days} days'),
  _gap(7),
  Text(p.stops.join(' → ')),
  _gap(7),
  Text(
    '${p.vehicle} · ${p.people} travellers · LKR ${p.budget.toStringAsFixed(0)}',
  ),
]);

class TravellerLandingScreen extends ConsumerWidget {
  const TravellerLandingScreen({super.key, this.placeId});
  final String? placeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme
            .copyWith(primary: WayhunterPalette.travellerCyan),
      ),
      child: PopScope(
        canPop: context.canPop(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) context.go('/home');
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Filter only the original artwork, never the foreground controls.
            ImageFiltered(
              key: const ValueKey('traveller-background-blur'),
              imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.asset(
                AppAssets.homeBackground,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                excludeFromSemantics: true,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000713), Color(0x99000713)],
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              bottomNavigationBar: const _TravellerLandingNavigation(),
              body: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 460;
                    final spacing = compact ? 8.0 : 12.0;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Go back',
                                    onPressed: back,
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                  const Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'WAYHUNTER',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Profile',
                                    onPressed: () => context.push('/profile'),
                                    icon: const Icon(
                                      Icons.account_circle_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: compact ? 30 : 40,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Traveller Map',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing),
                              Expanded(
                                child: Container(
                                  key: const ValueKey('traveller-landing-map'),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: const Color(0x55071D2A),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: WayhunterPalette.travellerCyan
                                          .withValues(alpha: .45),
                                    ),
                                  ),
                                  child: const TravellerMap(landing: true),
                                ),
                              ),
                              SizedBox(height: spacing),
                              NeonButton(
                                key: const ValueKey('traveller-create'),
                                label: 'Create New Trip',
                                icon: Icons.add_road,
                                accent: WayhunterPalette.travellerCyan,
                                onPressed: () {
                                  ref
                                      .read(travellerViewModelProvider.notifier)
                                      .newTrip();
                                  context.go('/traveller/create');
                                },
                              ),
                              SizedBox(height: spacing),
                              NeonButton(
                                key: const ValueKey('traveller-plans'),
                                label: 'My Plans',
                                icon: Icons.event_note_outlined,
                                accent: WayhunterPalette.travellerCyan,
                                onPressed: () => context.go('/traveller/plans'),
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
      ),
    );
  }
}

class _TravellerLandingNavigation extends StatelessWidget {
  const _TravellerLandingNavigation();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: NavigationBar(
          height: 68,
          backgroundColor: const Color(0xD8071D2A),
          indicatorColor: WayhunterPalette.travellerCyan.withValues(alpha: .22),
          selectedIndex: 1,
          onDestinationSelected: (index) => context.go(switch (index) {
            0 => '/home',
            1 => '/traveller',
            2 => '/leaderboard',
            _ => '/profile',
          }),
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
        ),
      ),
    ),
  );
}

class _StopsEditor extends ConsumerWidget {
  const _StopsEditor();
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final cities = ref.read(travellerViewModelProvider).catalog.cities.keys;
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Choose a stop')),
            for (final city in cities)
              ListTile(
                title: Text(city),
                leading: const Icon(Icons.place_outlined),
                onTap: () => Navigator.pop(ctx, city),
              ),
          ],
        ),
      ),
    );
    if (value != null) {
      ref.read(travellerViewModelProvider.notifier).addStop(value);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    return _panel('Route builder', [
      const Text(
        'The first stop is Start, the last is End. Add intermediate stops, reorder or remove any stop.',
      ),
      _gap(),
      for (var i = 0; i < s.draft.stops.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('stop-$i-${s.draft.stops[i]}'),
                initialValue: s.draft.stops[i],
                decoration: InputDecoration(
                  labelText: i == 0
                      ? 'Start'
                      : i == s.draft.stops.length - 1
                      ? 'End'
                      : 'Stop ${i + 1}',
                ),
                items:
                    {
                          ...s.catalog.locations.map((p) => p.name),
                          ...s.draft.customStops.keys,
                        }
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) vm.changeStop(i, v);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Move stop ${i + 1} up',
                    onPressed: i == 0 ? null : () => vm.moveStop(i, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Move stop ${i + 1} down',
                    onPressed: i == s.draft.stops.length - 1
                        ? null
                        : () => vm.moveStop(i, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    tooltip: 'Remove stop ${i + 1}',
                    onPressed: () => vm.removeStop(i),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      OutlinedButton.icon(
        key: const ValueKey('trip-add-stop'),
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Stop'),
      ),
    ]);
  }
}

class RouteReviewScreen extends ConsumerWidget {
  const RouteReviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    return _page(
      'Edit Route',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          Text(
            s.draft.title.isEmpty ? 'Your route' : s.draft.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          _gap(),
          _routeMap(s, s.draft.stops),
          _gap(),
          const _StopsEditor(),
          NeonButton(
            label: 'Save Route & Trip',
            onPressed: () {
              if (vm.saveDraft()) context.go('/traveller/plans');
            },
          ),
          TextButton(
            onPressed: () => context.go('/traveller/create'),
            child: const Text('Continue editing trip details'),
          ),
        ],
      ),
      subtitle: 'Review, reorder and add stops before or during your journey',
      back: '/traveller/create',
    );
  }
}

class AiTripPlanScreen extends ConsumerStatefulWidget {
  const AiTripPlanScreen({super.key});
  @override
  ConsumerState<AiTripPlanScreen> createState() => _AiTripPlanScreenState();
}

class _AiTripPlanScreenState extends ConsumerState<AiTripPlanScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final d = s.draft;
    return _page(
      'AI Trip Plan',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _panel(d.title, [
            const Text(
              'Deterministic local suggestions · no live AI, booking or prices.',
            ),
            Text(
              '${d.people} travellers · ${d.vehicle} · LKR ${d.budget.toStringAsFixed(0)}',
            ),
          ]),
          _routeMap(s, d.stops),
          _gap(),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(['Day-wise plan', 'Stays', 'Budget'][i]),
                  selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i),
                ),
            ],
          ),
          _gap(),
          if (_tab == 0)
            _panel('Suggested itinerary', [
              for (var i = 0; i < d.stops.length; i++)
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(d.stops[i]),
                  subtitle: const Text(
                    'Explore local sights · estimated demo day',
                  ),
                ),
            ])
          else if (_tab == 1)
            _panel('Stay planning', [
              for (final stop in d.stops.take(
                d.stops.length > 1 ? d.stops.length - 1 : 0,
              ))
                ListTile(
                  leading: const Icon(Icons.hotel_outlined),
                  title: Text('Plan a stay in $stop'),
                  subtitle: const Text(
                    'No hotel availability or booking service connected',
                  ),
                ),
            ])
          else
            _panel('Estimated budget', [
              Text('Total LKR ${d.budget.toStringAsFixed(0)}'),
              Text(
                'Per person LKR ${(d.budget / d.people).toStringAsFixed(0)}',
              ),
              const Text(
                'Estimate only; update your own budget in trip details.',
              ),
            ]),
          NeonButton(
            label: 'Save AI Plan',
            onPressed: () {
              if (vm.saveDraft()) context.go('/traveller/plans');
            },
          ),
          TextButton(
            onPressed: () => context.go('/traveller/create'),
            child: const Text('Edit plan and dates'),
          ),
        ],
      ),
      subtitle: 'Review your local suggested itinerary',
      back: '/traveller/create',
    );
  }
}

class PreviousTravellerPlanScreen extends ConsumerStatefulWidget {
  const PreviousTravellerPlanScreen({super.key});
  @override
  ConsumerState<PreviousTravellerPlanScreen> createState() =>
      _PreviousTravellerPlanScreenState();
}

class _PreviousTravellerPlanScreenState
    extends ConsumerState<PreviousTravellerPlanScreen> {
  final _selected = <int>{};
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final previous = s.catalog.plans.last;
    return _page(
      'Suggested Traveller Plan',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _summary(previous),
          _routeMap(s, previous.stops),
          _gap(),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 4; i++)
                ChoiceChip(
                  label: Text(
                    [
                      'Trip overview',
                      'Photos & memories',
                      'Stays',
                      'Traveller notes',
                    ][i],
                  ),
                  selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i),
                ),
            ],
          ),
          _gap(),
          if (_tab == 0)
            _panel('Reuse connected route segments', [
              for (var i = 0; i < s.catalog.segments.length; i++)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${s.catalog.segments[i].from} → ${s.catalog.segments[i].to}',
                  ),
                  subtitle: Text(
                    '${s.catalog.segments[i].distanceKm.toStringAsFixed(0)} km · estimated',
                  ),
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(i);
                    } else {
                      _selected.remove(i);
                    }
                  }),
                ),
            ])
          else if (_tab == 1)
            _panel('Photo inspiration', [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  AppAssets.homeBackground,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
              _gap(),
              const Text(
                'Original scenic artwork · no shared live media has been downloaded.',
              ),
            ])
          else if (_tab == 2)
            _panel('Stay ideas', [
              for (final stop in previous.stops.take(previous.stops.length - 1))
                ListTile(
                  title: Text(stop),
                  subtitle: const Text(
                    'Add your own accommodation after reusing the route.',
                  ),
                ),
            ])
          else
            _panel('Traveller notes', [
              const Text(
                'Reuse selected connected segments, then change the route, dates, people and budget for your own journey. All suggestions are local demo content.',
              ),
            ]),
          NeonButton(
            label: 'Use Selected Segments',
            onPressed: () {
              if (vm.useSegments(_selected)) context.go('/traveller/create');
            },
          ),
          TextButton(
            onPressed: () => context.go('/traveller/create'),
            child: const Text('Back to my route'),
          ),
        ],
      ),
      subtitle: 'Reuse part of a previous journey, then make it yours',
      back: '/traveller/create',
    );
  }
}

class MyPlansScreen extends ConsumerWidget {
  const MyPlansScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    return _page(
      'My Plans',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          Wrap(
            spacing: 8,
            children: [
              for (final tab in PlanTab.values)
                ChoiceChip(
                  key: ValueKey('plans-${tab.name}'),
                  label: Text(switch (tab) {
                    PlanTab.mine => 'My Plans',
                    PlanTab.shared => 'Shared With Me',
                    PlanTab.completed => 'Completed',
                  }),
                  selected: s.tab == tab,
                  onSelected: (_) => vm.setTab(tab),
                ),
            ],
          ),
          _gap(),
          if (s.filteredPlans.isEmpty)
            _panel('No journeys here yet', [
              const Text('Create a new trip or reuse a shared route.'),
              TextButton(
                onPressed: () {
                  vm.newTrip();
                  context.go('/traveller/create');
                },
                child: const Text('Create a trip'),
              ),
            ]),
          for (final p in s.filteredPlans)
            _panel(p.title, [
              Text(p.stops.join(' → ')),
              Text(
                '${_date(p.startDate)} · ${p.days} days · ${p.people} people',
              ),
              Text(
                '${p.vehicle} · LKR ${p.budget.toStringAsFixed(0)} · ${p.status.name}',
              ),
              _gap(),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      vm.edit(p);
                      context.go('/traveller/create');
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      p.ownerId == s.ownerId ? 'Edit' : 'Reuse & Edit',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/traveller/invites'),
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('Add Friends'),
                  ),
                  if (p.ownerId == s.ownerId &&
                      p.status != TripStatus.completed)
                    FilledButton.icon(
                      key: ValueKey('start-${p.id}'),
                      onPressed: () {
                        if (vm.start(p.id)) context.go('/traveller/active');
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        p.status == TripStatus.active
                            ? 'Resume Trip'
                            : 'Start Trip',
                      ),
                    ),
                  if (p.status == TripStatus.completed)
                    TextButton(
                      onPressed: () {
                        vm.select(p.id);
                        context.go(
                          '/traveller/finish?id=${Uri.encodeComponent(p.id)}',
                        );
                      },
                      child: const Text('View summary'),
                    ),
                ],
              ),
            ]),
          NeonButton(
            label: 'Create New Trip',
            onPressed: () {
              vm.newTrip();
              context.go('/traveller/create');
            },
          ),
        ],
      ),
      subtitle: 'Saved journeys · shared inspiration · completed adventures',
    );
  }
}

class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final trip = s.active;
    if (trip == null) return _noTrip(context, 'Active Trip');
    return _page(
      'Active Trip',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _summary(trip),
          _routeMap(s, trip.stops),
          _gap(),
          _panel('Journey progress · DEMO', [
            for (var i = 0; i < trip.stops.length; i++)
              ListTile(
                dense: true,
                leading: Icon(
                  i <= s.progress
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: i <= s.progress
                      ? WayhunterPalette.travellerCyan
                      : null,
                ),
                title: Text(trip.stops[i]),
                trailing: i == s.progress ? const Text('Current stop') : null,
              ),
            OutlinedButton(
              onPressed: s.progress < trip.stops.length - 1
                  ? vm.nextStop
                  : null,
              child: const Text('Simulate reaching next stop'),
            ),
          ]),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tool(context, 'Find Nearby Places', Icons.search, () {
                vm.loadNearby();
                context.go('/traveller/nearby');
              }),
              _tool(
                context,
                'Road Alert',
                Icons.warning_amber_outlined,
                () => context.go('/traveller/road-alert'),
              ),
              _tool(
                context,
                'Report Hazard',
                Icons.report_outlined,
                () => context.go('/traveller/hazard'),
              ),
              _tool(
                context,
                'Add Memories',
                Icons.photo_camera_outlined,
                () => context.go('/traveller/memories'),
              ),
              _tool(
                context,
                'Trip Friends',
                Icons.groups_outlined,
                () => context.go('/traveller/friends'),
              ),
              _tool(context, 'Edit Route', Icons.route, () {
                vm.edit(trip);
                context.go('/traveller/review');
              }),
            ],
          ),
          _gap(),
          _panel('Trip moments', [
            Text(
              '${s.memories.where((m) => m.tripId == trip.id).length} memories · ${s.hazards.where((h) => h.tripId == trip.id).length} local hazard reports',
            ),
            if (s.alternateRoute)
              const Text('Estimated alternative route selected · DEMO only'),
          ]),
          NeonButton(
            key: const ValueKey('trip-end'),
            label: 'End Trip · Review Summary',
            icon: Icons.flag_outlined,
            onPressed: () => context.go('/traveller/finish'),
          ),
        ],
      ),
      subtitle: 'Your journey is in progress · local simulation',
      back: '/traveller/plans',
    );
  }
}

Widget _tool(
  BuildContext context,
  String label,
  IconData icon,
  VoidCallback action,
) => OutlinedButton.icon(
  onPressed: action,
  icon: Icon(icon),
  label: Text(label),
);
Widget _noTrip(BuildContext context, String title) => _page(
  title,
  _panel('No active trip', [
    const Text('Start a saved trip to use this journey tool.'),
    NeonButton(
      label: 'Open My Plans',
      onPressed: () => context.go('/traveller/plans'),
    ),
  ]),
  back: '/traveller/plans',
);

class NearbyPlacesScreen extends ConsumerWidget {
  const NearbyPlacesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (s.active == null) return _noTrip(context, 'Find Nearby Places');
    return _page(
      'Find Nearby Places',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _routeMap(s, s.active!.stops),
          _gap(),
          const Text('On-demand local suggestions · not a live Places API'),
          _gap(),
          if (!s.nearbyLoaded)
            NeonButton(
              label: 'Load demo nearby places',
              onPressed: vm.loadNearby,
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final c in [
                'All',
                'Hotel',
                'Food',
                'Fuel',
                'Hospital',
                'Attraction',
              ])
                ChoiceChip(
                  label: Text(c),
                  selected: s.category == c,
                  onSelected: (_) => vm.category(c),
                ),
            ],
          ),
          _gap(),
          if (s.nearbyLoaded && s.filteredNearby.isEmpty)
            _panel('No demo results', [const Text('Choose another category.')]),
          for (final p in s.filteredNearby)
            _panel(p.name, [
              Text('${p.category} · ${p.district}'),
              Text(p.description),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(p.name),
                    content: Text(
                      '${p.description}\nApproximate coordinate: ${p.position.latitude}, ${p.position.longitude}. No live navigation or booking.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                child: const Text('View details'),
              ),
            ]),
          TextButton(
            onPressed: () => context.go('/traveller/active'),
            child: const Text('Return to Active Trip'),
          ),
        ],
      ),
      back: '/traveller/active',
    );
  }
}

class RoadAlertScreen extends ConsumerWidget {
  const RoadAlertScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (s.active == null) return _noTrip(context, 'Road Alert');
    return _page(
      'Road Alert Ahead',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(s.catalog.roadAlertType, [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 48,
            ),
            _gap(),
            Text(s.catalog.roadAlertDescription),
            const Text('DEMO alert · not a verified live safety warning.'),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Demo road alert details'),
                  content: Text(
                    '${s.catalog.roadAlertDescription}\nThis is a local scenario. No real traffic or road closure feed is connected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              child: const Text('View details'),
            ),
          ]),
          _routeMap(s, s.active!.stops),
          _gap(),
          NeonButton(
            label: s.alternateRoute
                ? 'Use Original Demo Route'
                : 'Show Estimated Alternative',
            onPressed: vm.alternativeRoute,
          ),
          _feedback(s),
          TextButton(
            onPressed: () => context.go('/traveller/active'),
            child: const Text('Resume trip'),
          ),
        ],
      ),
      back: '/traveller/active',
    );
  }
}

class HazardReportScreen extends ConsumerWidget {
  const HazardReportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (s.active == null) return _noTrip(context, 'Report Hazard');
    return _page(
      'Report Hazard',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _panel('Hazard report', [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: s.hazardType,
              decoration: const InputDecoration(labelText: 'Hazard type'),
              items: const [
                'Blocked Road',
                'Flooding',
                'Landslide',
                'Accident',
                'Other',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => vm.hazardDraft(type: v),
            ),
            _gap(),
            TextFormField(
              key: const ValueKey('hazard-description'),
              initialValue: s.hazardDescription,
              maxLength: 200,
              maxLines: 3,
              onChanged: (v) => vm.hazardDraft(description: v),
              decoration: const InputDecoration(
                labelText: 'Reason / description',
              ),
            ),
            _gap(),
            Text(
              'Trip stop: ${s.currentStop} · DEMO context, not a verified GPS fix',
            ),
          ]),
          _attachments(
            s.hazardEvidence,
            (id) => vm.removeEvidence(id, memory: false),
          ),
          EvidenceCapture(
            allowGallery: true,
            allowVideo: true,
            onCaptured: (e) => vm.addEvidence(e, memory: false),
          ),
          _gap(),
          NeonButton(
            label: 'Submit Local Report',
            onPressed: () {
              if (vm.submitHazard()) context.go('/traveller/active');
            },
          ),
          TextButton(
            onPressed: () => context.go('/traveller/active'),
            child: const Text('Cancel · keep report draft'),
          ),
        ],
      ),
      subtitle: 'Attach up to five photo/video items',
      back: '/traveller/active',
    );
  }
}

Widget _attachments(
  List<TripEvidence> evidence,
  void Function(String) remove,
) => Column(
  children: [
    for (final e in evidence)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (e.bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    e.bytes!,
                    width: 68,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  e.video ? Icons.videocam_outlined : Icons.photo_outlined,
                  size: 38,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.demo
                      ? 'DEMO ${e.video ? 'video' : 'photo'} attachment'
                      : 'Local ${e.video ? 'video' : 'photo'} attached',
                ),
              ),
              IconButton(
                tooltip: 'Remove attachment',
                onPressed: () => remove(e.id),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
  ],
);

class AddMemoriesScreen extends ConsumerWidget {
  const AddMemoriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (s.active == null) return _noTrip(context, 'Add Memories');
    return _page(
      'Add Memories',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _summary(s.active!),
          _panel('A moment from your journey', [
            Text('Trip stop: ${s.currentStop} · local demo context'),
            _gap(),
            TextFormField(
              key: const ValueKey('memory-caption'),
              initialValue: s.memoryCaption,
              maxLength: 300,
              maxLines: 3,
              onChanged: vm.caption,
              decoration: const InputDecoration(
                labelText: 'Caption / description',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in [
                  'Relaxed',
                  'Scenic',
                  'Heritage',
                  'Memorable',
                ])
                  FilterChip(
                    label: Text(tag),
                    selected: s.memoryTags.contains(tag),
                    onSelected: (_) => vm.tag(tag),
                  ),
              ],
            ),
          ]),
          _attachments(
            s.memoryEvidence,
            (id) => vm.removeEvidence(id, memory: true),
          ),
          EvidenceCapture(
            allowGallery: true,
            allowVideo: true,
            onCaptured: (e) => vm.addEvidence(e, memory: true),
          ),
          _gap(),
          NeonButton(
            label: 'Post Memories Locally',
            onPressed: () {
              if (vm.postMemory()) context.go('/traveller/active');
            },
          ),
          TextButton(
            onPressed: () => context.go('/traveller/active'),
            child: const Text('Cancel · keep memory draft'),
          ),
          for (final memory in s.tripMemories)
            _panel(memory.caption, [
              Text(memory.stop),
              Text(memory.tags.join(' · ')),
              Text('${memory.evidence.length} attachments'),
            ]),
        ],
      ),
      back: '/traveller/active',
    );
  }
}

class TripFriendsScreen extends ConsumerWidget {
  const TripFriendsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (s.active == null) return _noTrip(context, 'Trip Friends');
    return _page(
      'Trip Friends',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _summary(s.active!),
          _routeMap(
            s,
            s.active!.stops,
            extra: s.members
                .map(
                  (m) => TravellerMapMarker(
                    id: m.id,
                    name: m.name,
                    position: m.position,
                  ),
                )
                .toList(),
          ),
          _gap(),
          const Text(
            'DEMO member positions · no real-time tracking or messages',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final filter in FriendFilter.values)
                ChoiceChip(
                  label: Text(filter.name),
                  selected: s.friendFilter == filter,
                  onSelected: (_) => vm.friendFilter(filter),
                ),
            ],
          ),
          _gap(),
          for (final member in s.filteredMembers)
            _panel(member.name, [
              Text(
                '${member.deviationMetres} m deviation · ${member.isOffRoute ? 'Off route — over 500 m' : 'On route'}',
              ),
              if (member.isOffRoute)
                OutlinedButton.icon(
                  onPressed: s.safetyAlertsEnabled
                      ? () => vm.alert(member.id)
                      : null,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    !s.safetyAlertsEnabled
                        ? 'Safety alerts paused'
                        : s.alerted.contains(member.id)
                        ? 'DEMO alert recorded · send again'
                        : 'Send DEMO check-in alert',
                  ),
                ),
            ]),
          NeonButton(
            label: 'Invite / Accept Friends',
            onPressed: () => context.go('/traveller/invites'),
          ),
          TextButton(
            onPressed: () => context.go('/traveller/active'),
            child: const Text('Return to Active Trip'),
          ),
        ],
      ),
      subtitle: 'Live journey layout with simulated group data',
      back: '/traveller/active',
    );
  }
}

class GroupInvitationsScreen extends ConsumerStatefulWidget {
  const GroupInvitationsScreen({super.key});
  @override
  ConsumerState<GroupInvitationsScreen> createState() =>
      _GroupInvitationsScreenState();
}

class _GroupInvitationsScreenState
    extends ConsumerState<GroupInvitationsScreen> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    return _page(
      'Group Invitation & Safety',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _panel('Invite a friend', [
            TextField(
              key: const ValueKey('invite-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Friend name'),
            ),
            _gap(),
            NeonButton(
              label: 'Create DEMO Invitation',
              onPressed: () {
                if (vm.invite(_name.text)) _name.clear();
              },
            ),
            const Text(
              'Invitations and acceptance are simulated on this device; no message is sent.',
            ),
          ]),
          if (s.invitations.isEmpty)
            _panel('No pending invitations', [
              const Text(
                'Create an invitation to simulate a friend joining your group.',
              ),
            ]),
          for (final invitation in s.invitations)
            _panel(invitation.name, [
              Text(
                invitation.accepted
                    ? 'Accepted · joined demo group'
                    : 'Pending local invitation',
              ),
              if (!invitation.accepted)
                FilledButton(
                  onPressed: () => vm.accept(invitation.id),
                  child: const Text('Simulate Accept'),
                ),
            ]),
          _panel('Friend safety', [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Demo safety alerts'),
              value: s.safetyAlertsEnabled,
              onChanged: vm.safetyAlerts,
            ),
            const Text(
              'Members over 500 metres off the demo route are flagged. Send a local check-in alert from Trip Friends. This is not a production safety system.',
            ),
            Text(
              '${s.members.where((m) => m.isOffRoute).length} demo members currently off route',
            ),
          ]),
          NeonButton(
            label: s.active != null ? 'View Trip Friends' : 'Back to My Plans',
            onPressed: () => context.go(
              s.active != null ? '/traveller/friends' : '/traveller/plans',
            ),
          ),
        ],
      ),
      back: s.active != null ? '/traveller/friends' : '/traveller/plans',
    );
  }
}

class FinishTripScreen extends ConsumerWidget {
  const FinishTripScreen({super.key, this.tripId});
  final String? tripId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final trip = tripId != null
        ? s.plans
              .where((p) => p.id == tripId && p.status == TripStatus.completed)
              .firstOrNull
        : s.active ??
              (s.selected?.status == TripStatus.completed
                  ? s.selected
                  : s.finished);
    if (trip == null) return _noTrip(context, 'Finish Trip');
    final memories = s.memories.where((m) => m.tripId == trip.id).toList();
    final hazards = s.hazards.where((h) => h.tripId == trip.id).length;
    return _page(
      'Finish Trip',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _feedback(s),
          _summary(trip),
          _panel('Trip summary', [
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                Text('${trip.days} days'),
                Text('${trip.stops.length} stops'),
                Text('${trip.people} travellers'),
                Text('${memories.length} memories'),
                Text('$hazards local hazard reports'),
              ],
            ),
            _gap(),
            const Text(
              'Distance and route geometry are estimated demonstrations, not verified travel statistics.',
            ),
          ]),
          _routeMap(s, trip.stops),
          _gap(),
          _panel('Trip memories', [
            if (memories.isEmpty)
              const Text('No memories added to this journey.'),
            for (final memory in memories)
              ListTile(
                title: Text(memory.caption),
                subtitle: Text(
                  '${memory.stop} · ${memory.evidence.length} attachments',
                ),
              ),
          ]),
          if (trip.status != TripStatus.completed)
            NeonButton(
              key: const ValueKey('trip-finish-save'),
              label: 'Finish Trip & Save',
              icon: Icons.flag_outlined,
              onPressed: () {
                if (vm.finish()) context.go('/traveller/plans');
              },
            )
          else
            NeonButton(
              label: 'Open Completed Trips',
              onPressed: () {
                vm.setTab(PlanTab.completed);
                context.go('/traveller/plans');
              },
            ),
          if (trip.status == TripStatus.active)
            TextButton(
              onPressed: () => context.go('/traveller/active'),
              child: const Text('Keep travelling'),
            ),
        ],
      ),
      subtitle: trip.status == TripStatus.completed
          ? 'Saved journey'
          : 'Review your journey before ending it',
      back: trip.status == TripStatus.active
          ? '/traveller/active'
          : '/traveller/plans',
    );
  }
}
