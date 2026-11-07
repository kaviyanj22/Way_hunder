import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/app/app_theme.dart';
import 'package:wayhunter_mobile/core/constants/app_assets.dart';
import 'package:wayhunter_mobile/core/services/maps_service.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/views/traveller_screens.dart';

import '../widget_test.dart' show boot, demoSignIn, capture, loadReviewFonts;

// Keep the real GoogleMap/controller lifecycle while recording SDK commands.
// Only the native platform surface is replaced in widget tests.
class _RecordingMaps extends MethodChannelGoogleMapsFlutter {
  final createdIds = <int>{};
  final moves = <CameraUpdate>[];
  final sizesAtMove = <Size>[];
  Size Function()? readMapSize;

  @override
  Future<void> init(int mapId) async {
    final channel = ensureChannelInitialized(mapId);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPlatformViewCreated(creationId);
      });
    }
    return const ColoredBox(color: Color(0xFF133C51));
  }

  @override
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {
    moves.add(cameraUpdate);
    sizesAtMove.add(readMapSize!());
  }

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {}
}

Future<void> _landing(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  MapsAvailability availability = MapsAvailability.missingKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetPadding);
  final router = GoRouter(
    initialLocation: '/traveller',
    routes: [
      GoRoute(
        path: '/traveller',
        builder: (_, _) => const TravellerLandingScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mapsAvailabilityProvider.overrideWith((ref) async => availability),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadReviewFonts);

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(320, 480),
    const Size(640, 360),
  ]) {
    testWidgets('fixed landing fits $size with safe insets', (tester) async {
      await _landing(tester, size: size);
      expect(tester.takeException(), isNull);
      final landing = find.byType(TravellerLandingScreen);
      for (final type in [SingleChildScrollView, ListView, Scrollable]) {
        expect(
          find.descendant(of: landing, matching: find.byType(type)),
          findsNothing,
        );
      }
      expect(find.byType(FilledButton), findsNWidgets(2));
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      for (final copy in [
        'Your next journey',
        'Plan your route, discover places and save the moments.',
        'Enable my location',
        'Resume Draft',
        'Resume Active Trip',
        'Back to Home',
      ]) {
        expect(find.text(copy), findsNothing);
      }
      final map = find.byKey(const ValueKey('traveller-landing-map'));
      final create = find.byKey(const ValueKey('traveller-create'));
      final plans = find.byKey(const ValueKey('traveller-plans'));
      final footer = find.byType(NavigationBar);
      final before = [
        tester.getRect(find.text('Traveller Map')),
        tester.getRect(create),
        tester.getRect(plans),
        tester.getRect(footer),
      ];
      expect(tester.getSize(map).height, greaterThan(0));
      expect(tester.getRect(map).bottom, lessThan(tester.getRect(create).top));
      expect(
        tester.getRect(plans).bottom,
        lessThanOrEqualTo(tester.getRect(footer).top),
      );
      expect(
        tester.getRect(footer).bottom,
        lessThanOrEqualTo(size.height - 24),
      );
      expect(
        tester.getRect(find.byTooltip('Go back')).top,
        greaterThanOrEqualTo(24),
      );
      for (final button in [create, plans]) {
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }
      await tester.drag(map, const Offset(0, -120));
      await tester.pumpAndSettle();
      expect([
        tester.getRect(find.text('Traveller Map')),
        tester.getRect(create),
        tester.getRect(plans),
        tester.getRect(footer),
      ], before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'larger text fits; blur is restricted to the original background',
    (tester) async {
      await _landing(tester, size: const Size(320, 568), textScale: 1.4);
      final blur = find.byKey(const ValueKey('traveller-background-blur'));
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(
        find.descendant(
          of: blur,
          matching: find.image(const AssetImage(AppAssets.homeBackground)),
        ),
        findsOneWidget,
      );
      final filter = tester.widget<ImageFiltered>(blur).imageFilter.toString();
      expect(filter, contains('5.0'));
      for (final type in [Text, FilledButton, Icon, NavigationBar]) {
        expect(
          find.descendant(of: blur, matching: find.byType(type)),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'two actions, header and four footer icons use the existing real routes',
    (tester) async {
      final container = await boot(tester);
      await demoSignIn(tester);
      final router = container.read(appRouterProvider);
      Future<void> open() async {
        router.go('/traveller');
        await tester.pumpAndSettle();
      }

      await open();
      await capture(tester, 'traveller-landing-fixed');
      await tester.tap(find.byKey(const ValueKey('traveller-create')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/traveller/create');
      expect(find.byType(TripBuilderScreen), findsOneWidget);
      await open();
      await tester.tap(find.byKey(const ValueKey('traveller-plans')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/traveller/plans');
      expect(find.byType(MyPlansScreen), findsOneWidget);
      for (final entry in {
        Icons.home_outlined: '/home',
        Icons.hiking: '/traveller',
        Icons.emoji_events_outlined: '/leaderboard',
        Icons.person_outline: '/profile',
      }.entries) {
        await open();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(entry.key),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.state.uri.path, entry.value);
      }
      await open();
      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.account_circle_outlined),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TravellerLandingScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Go back'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/home');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native camera fits Sri Lanka after layout once; rebuilds preserve gestures',
    (tester) async {
      final original = GoogleMapsFlutterPlatform.instance;
      final platform = _RecordingMaps();
      GoogleMapsFlutterPlatform.instance = platform;
      addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
      platform.readMapSize = () => tester.getSize(find.byType(GoogleMap));
      await _landing(
        tester,
        size: const Size(390, 844),
        availability: MapsAvailability.configured,
      );
      expect(platform.moves, hasLength(1));
      final update = platform.moves.single as CameraUpdateNewLatLngBounds;
      expect(update.bounds.southwest, const LatLng(5.85, 79.50));
      expect(update.bounds.northeast, const LatLng(9.95, 82.20));
      expect(platform.sizesAtMove.single.width, greaterThan(0));
      expect(platform.sizesAtMove.single.height, greaterThan(0));
      expect(
        update.padding,
        inExclusiveRange(0, platform.sizesAtMove.single.shortestSide / 2),
      );
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.scrollGesturesEnabled, isTrue);
      expect(map.zoomGesturesEnabled, isTrue);
      expect(map.gestureRecognizers, isNotEmpty);
      expect(map.myLocationButtonEnabled, isFalse);
      expect(
        find.ancestor(
          of: find.byType(GoogleMap),
          matching: find.byType(ImageFiltered),
        ),
        findsNothing,
      );
      await tester.drag(find.byType(GoogleMap), const Offset(65, -90));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      expect(
        platform.moves,
        hasLength(1),
        reason: 'Panning/resizing must never reset the camera',
      );
      expect(platform.createdIds, hasLength(1));
      expect(tester.takeException(), isNull);
      // Dispose the GoogleMap while its platform implementation is still installed.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
