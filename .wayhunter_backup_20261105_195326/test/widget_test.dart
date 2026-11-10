import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/app/app.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/core/constants/app_assets.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/core/services/maps_service.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/core/widgets/demo_map.dart';
import 'package:wayhunter_mobile/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:wayhunter_mobile/features/home/presentation/views/home_screen.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/widgets/traveller_map.dart';

class _UnavailableMaps extends MapsService {
  @override
  Future<MapsAvailability> availability() async => MapsAvailability.missingKey;
}

Future<ProviderContainer> boot(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
      mapsServiceProvider.overrideWithValue(_UnavailableMaps()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('review-root'),
        child: WayhunterApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    for (final asset in [
      AppAssets.homeBackground,
      AppAssets.travellerButton,
      AppAssets.hunterButton,
      AppAssets.gameButton,
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
  return container;
}

Future<void> demoSignIn(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('auth-demo-fill')));
  await tester.tap(find.byKey(const ValueKey('auth-demo-fill')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('auth-sign-in')));
  await tester.tap(find.byKey(const ValueKey('auth-sign-in')));
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['WAYHUNTER_CAPTURE'] != 'true') return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('review-root')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('.codex_review').create(recursive: true);
    await File('.codex_review/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> loadReviewFonts() async {
  final fontPath = Platform.environment['WAYHUNTER_REVIEW_FONT'];
  if (fontPath != null) {
    final loader = FontLoader('Roboto')
      ..addFont(
        File(fontPath).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    final directory = File(fontPath).parent;
    for (final name in ['roboto-bold.ttf', 'roboto-medium.ttf']) {
      loader.addFont(
        File('${directory.path}/$name')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File('${directory.path}/materialicons-regular.otf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)),
      );
    await icons.load();
  }
}

void main() {
  setUpAll(loadReviewFonts);

  testWidgets('signed-out deep links cannot bypass auth or OTP recovery', (
    tester,
  ) async {
    final container = await boot(tester);
    final router = container.read(appRouterProvider);
    for (final path in [
      '/home',
      '/traveller',
      '/hunter',
      '/game',
      '/profile',
      '/wallet',
      '/otp',
      '/permissions',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/sign-in',
        reason: path,
      );
    }
    router.go('/reset-password');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/forgot-password');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'demo login opens original Home images and every module entry returns Home',
    (tester) async {
      final container = await boot(tester);
      await capture(tester, 'sign-in');
      await demoSignIn(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Hi, ${MockData.currentUser['name']}'), findsOneWidget);
      await capture(tester, 'home');
      final router = container.read(appRouterProvider);
      final routes = {
        AppAssets.travellerButton: '/traveller',
        AppAssets.hunterButton: '/hunter',
        AppAssets.gameButton: '/game',
      };
      for (final entry in routes.entries) {
        final image = find.image(AssetImage(entry.key));
        expect(image, findsOneWidget);
        await tester.ensureVisible(image);
        await tester.tap(image);
        await tester.pumpAndSettle();
        expect(router.state.uri.path, entry.value);
        if (entry.value == '/traveller') {
          expect(find.byType(TravellerMap), findsOneWidget);
        } else {
          expect(find.byType(DemoMap), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        final home = entry.value == '/traveller'
            ? find.byTooltip('Go back')
            : find.text('Back to Home');
        await tester.ensureVisible(home);
        await tester.tap(home);
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Home search filters fixtures and notifications update local state',
    (tester) async {
      final container = await boot(tester);
      await demoSignIn(tester);
      await tester.tap(find.byTooltip('Search places'));
      await tester.pumpAndSettle();
      final place = MockData.places.first;
      await tester.enterText(find.byType(TextField), place['name']! as String);
      await tester.pumpAndSettle();
      final result = find.widgetWithText(ListTile, place['name']! as String);
      expect(result, findsOneWidget);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).state.uri.queryParameters['place'],
        place['id'],
      );
      expect(find.byType(TravellerMap), findsOneWidget);
      expect(find.text('Traveller Map'), findsOneWidget);
      container.read(appRouterProvider).go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mark all as read'));
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();
      expect(container.read(homeViewModelProvider).unreadCount, 0);
      expect(find.text('Read'), findsNWidgets(MockData.notifications.length));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'profile sign-out cancel preserves session and confirm protects Home',
    (tester) async {
      final container = await boot(tester);
      await demoSignIn(tester);
      await tester.tap(find.byTooltip('Open Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/profile');
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/sign-in',
      );
      container.read(appRouterProvider).go('/home');
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/sign-in',
      );
    },
  );

  testWidgets('small screen and keyboard leave sign-in and Home usable', (
    tester,
  ) async {
    await boot(tester, size: const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('auth-sign-in')));
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    await demoSignIn(tester);
    final game = find.image(const AssetImage(AppAssets.gameButton));
    await tester.ensureVisible(game);
    expect(tester.takeException(), isNull);
    await capture(tester, 'home-small');
  });
}
