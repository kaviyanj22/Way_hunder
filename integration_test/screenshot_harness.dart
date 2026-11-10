import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wayhunter_mobile/app/app.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

/// Drives the existing app. The only override is disposable local storage.
/// Native maps/cameras, fonts, layout, repositories and reward rules stay real.
class ScreenshotHarness {
  ScreenshotHarness(this.tester, this.binding);
  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  late ProviderContainer container;
  bool _mounted = false;
  bool _converted = false;
  static const _captureChannel = MethodChannel('plugins.flutter.io/integration_test');
  final rows = <Map<String, Object?>>[];
  final root = Directory('${Directory.systemTemp.path}/wayhunter_screen_export');
  static const _fileSelection = String.fromEnvironment('SCREENSHOT_FILES');
  bool get partial => _fileSelection.isNotEmpty;
  GoRouter get router => container.read(appRouterProvider);

  Future<void> reset({bool signedIn = true}) async {
    debugPrint('SCREEN_RESET starting');
    if (_mounted) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      container.dispose();
    }
    container = ProviderContainer(overrides: [
      localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
    ]);
    _mounted = true;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const WayhunterApp(),
    ));
    await container.read(authViewModelProvider.notifier).initialize();
    await settle();
    debugPrint('SCREEN_RESET app mounted');
    // Decode original bundled images before the first capture. No replacement art.
    final context = tester.element(find.byType(WayhunterApp));
    for (final asset in [
      'assets/images/backgrounds/home_background.png',
      'assets/images/buttons/traveller_button.png',
      'assets/images/buttons/hunter_button.png',
      'assets/images/buttons/game_button.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
    debugPrint('SCREEN_RESET assets ready');
    if (signedIn) {
      final auth = container.read(authViewModelProvider.notifier);
      auth.useDemoCredentials();
      final next = await auth.signIn();
      if (next == null) throw StateError('Existing demo sign-in failed.');
      await go(next);
    }
  }

  Future<void> settle() async {
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 15));
    _checkErrors();
  }

  void _checkErrors() {
    final error = tester.takeException();
    if (error != null) throw StateError('Flutter rendering/runtime error: $error');
  }

  Future<void> go(String route) async {
    for (var i = 0; i < 5; i++) {
      final modals = find.byWidgetPredicate((w) =>
          w is AlertDialog || w is SimpleDialog || w is BottomSheet).evaluate();
      if (modals.isEmpty) break;
      final active = modals.where((e) => ModalRoute.of(e)?.isCurrent == true);
      if (active.isEmpty) {
        await settle();
        break;
      }
      Navigator.of(active.last).pop();
      await settle();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    router.go(route);
    await settle();
    if (router.routeInformationProvider.value.uri.toString() != route) {
      throw StateError('Route $route redirected to '
          '${router.routeInformationProvider.value.uri}');
    }
  }

  Future<void> tap(Finder finder) async {
    if (finder.evaluate().isEmpty) throw StateError('Control not found: $finder');
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first);
    await settle();
  }

  Future<void> capture(String module, String filename, String screenName,
      String route, {String notes = ''}) async {
    if (partial && !_fileSelection.split(',').contains('$module/$filename')) return;
    debugPrint('SCREEN_CAPTURING $module/$filename');
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await settle();
    if (router.routeInformationProvider.value.uri.path != Uri.parse(route).path) {
      throw StateError('Expected $route for $screenName, actual route is '
          '${router.routeInformationProvider.value.uri}. Capture refused.');
    }
    // Native tiles and textures finish independently of Flutter's scheduler.
    final map = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'GoogleMap');
    await tester.pump(Duration(milliseconds: map.evaluate().isEmpty ? 500 : 3500));
    await settle();
    if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(ErrorWidget).evaluate().isNotEmpty) {
      throw StateError('Loading/error widget remains visible; capture refused.');
    }
    final size = tester.view.physicalSize;
    if (size != const Size(390, 844)) {
      throw StateError('Android surface is $size; expected 390 × 844.');
    }
    final name = '$module/$filename';
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    } else {
      await _captureChannel.invokeMethod<void>('convertFlutterSurfaceToImage');
    }
    await tester.pump();
    late final List<int> png;
    try {
      png = await binding.takeScreenshot(name).timeout(const Duration(seconds: 20));
    } finally {
      // Android 17's ImageReader can stop drawing during later UI animations
      // if the converted surface stays attached between captures.
      await _captureChannel.invokeMethod<void>('revertFlutterImage');
    }
    final target = File('${root.path}/$name');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(png, flush: true);
    // Keep the VM response small; the host driver retrieves the original PNG
    // bytes with adb run-as, without encoding hundreds of MB as JSON arrays.
    (binding.reportData!['screenshots'] as List).clear();
    rows.add({
      'module': module, 'screen': screenName, 'route': route,
      'filename': name, 'status': 'Captured', 'notes': notes,
      'devicePath': target.path,
    });
    await _saveManifest();
    debugPrint('SCREEN_CAPTURED $name');
  }

  void missing(String module, String screen, String route, String reason) {
    rows.add({'module': module, 'screen': screen, 'route': route,
      'filename': '', 'status': 'Missing / inaccessible', 'notes': reason});
  }

  Future<void> attempt(String module, String screen, String route,
      Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      // Failures are surfaced in the index and fail the final integration test.
      rows.add({'module': module, 'screen': screen, 'route': route,
        'filename': '', 'status': 'Capture failed', 'notes': '$error'});
      debugPrint('SCREEN_FAILED $module $screen: $error\n$stack');
      await _saveManifest();
    }
  }

  Future<void> _saveManifest() async {
    binding.reportData ??= {};
    binding.reportData!['screenIndex'] = rows;
    await root.create(recursive: true);
    await File('${root.path}/manifest.json').writeAsString(jsonEncode(rows), flush: true);
  }

  Future<void> finish() async {
    await _saveManifest();
    if (_mounted) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      container.dispose();
      _mounted = false;
    }
  }

  void auditRoutes(Set<String> modules) {
    final capturedPaths = rows.where((r) => r['status'] == 'Captured')
        .map((r) => Uri.parse(r['route']! as String).path).toSet();
    for (final route in router.configuration.routes.whereType<GoRoute>()) {
      final path = route.path;
      if (path == '/' || path == '/loading') continue;
      final module = path.startsWith('/traveller') ? 'traveller'
          : path.startsWith('/hunter') ? 'hunter'
          : path.startsWith('/game') ? 'games'
          : path.startsWith('/profile') ? 'profile'
          : path.startsWith('/wallet') ? 'wallet'
          : {'/home','/leaderboard','/notifications'}.contains(path) ? 'home' : 'auth';
      if (!modules.contains(module)) continue;
      final pattern = RegExp('^${path.split('/').map((s) => s.startsWith(':') ? '[^/]+' : RegExp.escape(s)).join('/')}\u0024');
      if (!capturedPaths.any(pattern.hasMatch)) {
        missing(module, 'Registered route not captured', path,
            'No successful PNG reached this existing route. See capture failure records.');
      }
    }
  }
}
