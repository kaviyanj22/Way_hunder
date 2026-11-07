import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/core/services/maps_service.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/traveller/domain/entities/traveller_map_data.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/viewmodels/traveller_view_model.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/views/traveller_screens.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/widgets/trip_location_picker.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/widgets/trip_route_map.dart';

import '../widget_test.dart' show boot, demoSignIn, capture, loadReviewFonts;
import 'traveller_flow_test.dart' show tap, enter;

class _Maps extends MethodChannelGoogleMapsFlutter {
  final createdIds = <int>{};
  final moves = <CameraUpdate>[];
  @override
  Future<void> init(int mapId) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ensureChannelInitialized(mapId),
          (_) async => null,
        );
  }

  @override
  void dispose({required int mapId}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel(mapId), null);
  }

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapObjects mapObjects = const MapObjects(),
    MapConfiguration mapConfiguration = const MapConfiguration(),
  }) {
    if (createdIds.add(creationId)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onPlatformViewCreated(creationId),
      );
    }
    return const ColoredBox(color: Color(0xFF153E50));
  }

  @override
  Future<void> moveCamera(CameraUpdate update, {required int mapId}) async {
    moves.add(update);
  }

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates updates, {
    required int mapId,
  }) async {}
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  final container = await boot(tester, size: size);
  await demoSignIn(tester);
  container.read(appRouterProvider).go('/traveller/create');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(loadReviewFonts);
  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(320, 568),
    const Size(640, 360),
  ]) {
    testWidgets('Create Trip remains fixed at $size, including keyboard', (
      tester,
    ) async {
      await _open(tester, size: size);
      expect(tester.takeException(), isNull);
      final screen = find.byType(TripBuilderScreen);
      expect(
        find.descendant(
          of: screen,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: screen, matching: find.byType(ListView)),
        findsNothing,
      );
      final labels = [
        'Trip Basics',
        'Route Builder',
        'Suggested Trip Plans',
        'Travel Details',
        'AI Trip Plane',
        'Submit Trip',
      ];
      var bottom = 0.0;
      for (final label in labels) {
        final rect = tester.getRect(find.text(label));
        expect(rect.top, greaterThan(bottom));
        bottom = rect.bottom;
      }
      final footer = tester.getRect(find.byType(NavigationBar));
      expect(bottom, lessThan(footer.top));
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      await tester.drag(find.text('Route Builder'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(NavigationBar)), footer);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(NavigationBar)), footer);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }

  testWidgets('larger text keeps compact cards within their bounds', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    await capture(tester, 'create-trip-large-text');
  });

  testWidgets(
    'search, add, chip editing, reorder and removal retain the whole route',
    (tester) async {
      final c = await _open(tester);
      final vm = c.read(travellerViewModelProvider.notifier);
      await tap(tester, find.byKey(const ValueKey('trip-start-location')));
      await enter(tester, 'trip-location-search', 'Jaffna Fort');
      expect(find.byKey(const ValueKey('pick-city-Kandy')), findsNothing);
      await tap(tester, find.byKey(const ValueKey('pick-place-001')));
      await tap(tester, find.byKey(const ValueKey('trip-end-location')));
      await tap(tester, find.byKey(const ValueKey('pick-city-Kandy')));
      await tap(tester, find.byKey(const ValueKey('trip-add-place')));
      await enter(tester, 'trip-location-search', 'Mannar');
      await tap(tester, find.byKey(const ValueKey('pick-city-Mannar')));
      await tap(tester, find.byKey(const ValueKey('trip-add-stop')));
      expect(c.read(travellerViewModelProvider).draft.stops, [
        'Jaffna Fort',
        'Mannar',
        'Kandy',
      ]);
      await tap(tester, find.byKey(const ValueKey('trip-stop-chip-1')));
      await tap(tester, find.byKey(const ValueKey('pick-city-Vavuniya')));
      await tap(tester, find.byTooltip('Actions for stop 2'));
      await tap(tester, find.text('Move later'));
      expect(c.read(travellerViewModelProvider).draft.stops, [
        'Jaffna Fort',
        'Kandy',
        'Vavuniya',
      ]);
      await tap(tester, find.byTooltip('Actions for stop 2'));
      await tap(tester, find.text('Remove stop'));
      expect(c.read(travellerViewModelProvider).draft.stops, [
        'Jaffna Fort',
        'Vavuniya',
      ]);
      for (final city in ['Mannar', 'Kandy', 'Colombo', 'Kilinochchi']) {
        vm.addIntermediateStop(city);
      }
      await tester.pumpAndSettle();
      expect(find.text('+3'), findsOneWidget);
      await tap(tester, find.text('+3'));
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(c.read(travellerViewModelProvider).draft.stops, hasLength(6));
      await tap(tester, find.byKey(const ValueKey('trip-apply-route')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ideas load ordered stops; Edit Idea applies edits and Cancel restores draft',
    (tester) async {
      final c = await _open(tester);
      final ideas = c.read(travellerViewModelProvider).catalog.suggestions;
      await tap(tester, find.byKey(ValueKey('use-${ideas.first.id}')));
      expect(find.byKey(ValueKey('suggestion-use-${ideas.first.id}')), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('suggestion-use-${ideas.first.id}')));
      expect(
        c.read(travellerViewModelProvider).draft.stops,
        ideas.first.plan.stops,
      );
      final before = c.read(travellerViewModelProvider).draft;
      await tap(tester, find.byKey(ValueKey('edit-${ideas.last.id}')));
      await tap(tester, find.widgetWithText(FilledButton, 'Edit Idea'));
      await tap(tester, find.byTooltip('Remove stop 2'));
      await tap(tester, find.byTooltip('Cancel route edits'));
      expect(c.read(travellerViewModelProvider).draft.stops, before.stops);
      await tap(tester, find.byKey(ValueKey('edit-${ideas.last.id}')));
      await tap(tester, find.widgetWithText(FilledButton, 'Edit Idea'));
      await tap(tester, find.byTooltip('Move stop 2 down'));
      await tap(tester, find.byTooltip('Remove stop 2'));
      await tap(tester, find.byKey(const ValueKey('trip-apply-route')));
      expect(
        c.read(travellerViewModelProvider).draft.stops.length,
        ideas.last.plan.stops.length - 1,
      );
      expect(find.byType(TripBuilderScreen), findsOneWidget);
    },
  );

  testWidgets(
    'budget, vehicle and people validate; submit saves; AI cancellation preserves inputs',
    (tester) async {
      final c = await _open(tester);
      await tap(tester, find.byKey(const ValueKey('trip-submit')));
      expect(
        find.text('Enter a trip title with at least 3 characters.'),
        findsOneWidget,
      );
      await enter(tester, 'trip-title-null', 'Personal journey');
      await tap(tester, find.byKey(const ValueKey('trip-budget')));
      await enter(tester, 'trip-number-input', '-2');
      await tap(tester, find.text('Apply'));
      expect(find.text('Enter a positive budget.'), findsOneWidget);
      await enter(tester, 'trip-number-input', '48000');
      await tap(tester, find.text('Apply'));
      await tap(tester, find.byKey(const ValueKey('trip-vehicle')));
      await tap(tester, find.text('Van').last);
      await tap(tester, find.byKey(const ValueKey('trip-people')));
      await enter(tester, 'trip-number-input', '3');
      await tap(tester, find.text('Apply'));
      var draft = c.read(travellerViewModelProvider).draft;
      expect(
        [draft.title, draft.budget, draft.vehicle, draft.people],
        ['Personal journey', 48000, 'Van', 3],
      );
      await tap(tester, find.byKey(const ValueKey('trip-ai')));
      await tap(tester, find.text('Cancel'));
      expect(
        c.read(travellerViewModelProvider).draft.title,
        'Personal journey',
      );
      final vm = c.read(travellerViewModelProvider.notifier);
      vm.setDates(DateTime(2026, 11, 10), DateTime(2026, 11, 12));
      vm.setStartLocation('Jaffna');
      vm.setEndLocation('Kandy');
      await tester.pumpAndSettle();
      await capture(tester, 'create-trip-filled');
      await tap(tester, find.byKey(const ValueKey('trip-ai')));
      await tap(tester, find.text('Generate plan'));
      draft = c.read(travellerViewModelProvider).draft;
      expect(
        [draft.title, draft.budget, draft.vehicle, draft.people],
        ['Personal journey', 48000, 'Van', 3],
      );
      expect(find.byType(AiTripPlanScreen), findsOneWidget);
      c.read(appRouterProvider).go('/traveller/create');
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('trip-submit')));
      expect(find.byType(MyPlansScreen), findsOneWidget);
      expect(
        c
            .read(travellerViewModelProvider)
            .plans
            .where((p) => p.title == 'Personal journey'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'map-selected location updates ordered route markers and polyline',
    (tester) async {
      final original = GoogleMapsFlutterPlatform.instance;
      final maps = _Maps();
      GoogleMapsFlutterPlatform.instance = maps;
      addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
      final c = ProviderContainer(
        overrides: [
          localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
          mapsAvailabilityProvider.overrideWith(
            (ref) async => MapsAvailability.configured,
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: Scaffold(body: _MapPickerHost())),
        ),
      );
      await tap(tester, find.text('Pick location'));
      await tap(tester, find.byTooltip('Choose on map'));
      var map = tester.widget<GoogleMap>(find.byType(GoogleMap).last);
      map.onTap!(const LatLng(9.65, 80.02));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('trip-use-map-pin')));
      final draft = c.read(travellerViewModelProvider).draft;
      expect(draft.customStops.values.single.latitude, 9.65);
      expect(draft.stops.single, startsWith('Pin '));
      final vm = c.read(travellerViewModelProvider.notifier);
      vm.setEndLocation('Kandy');
      vm.addIntermediateStop('Mannar');
      await tester.pumpAndSettle();
      map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers, hasLength(3));
      expect(map.polylines.single.points, [
        const LatLng(9.65, 80.02),
        const LatLng(8.98, 79.904),
        const LatLng(7.2906, 80.6337),
      ]);
      expect(maps.moves, isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

class _MapPickerHost extends ConsumerWidget {
  const _MapPickerHost();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travellerViewModelProvider);
    return Column(
      children: [
        TextButton(
          child: const Text('Pick location'),
          onPressed: () async {
            final selected = await showTripLocationPicker(context);
            if (selected != null) {
              ref
                  .read(travellerViewModelProvider.notifier)
                  .setStartLocation(selected);
            }
          },
        ),
        Expanded(
          child: TripRouteMap(
            stops: [
              for (final name in state.draft.stops)
                if (state.positionFor(name) case final position?)
                  TravellerMapMarker(id: name, name: name, position: position),
            ],
          ),
        ),
      ],
    );
  }
}
