import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/app/app.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

Future<ProviderContainer> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const WayhunterApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.enterText(find.byKey(ValueKey(key)), value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Register page is fixed when keyboard is closed and fields remain accessible', (tester) async {
    await _boot(tester);
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    final registerScroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(registerScroll.physics, isA<NeverScrollableScrollPhysics>());
    expect(find.byKey(const ValueKey('register-submit')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const ValueKey('register-name')), 'Demo Traveller');
    await tester.pumpAndSettle();
    expect(find.text('Demo Traveller'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signup form, OTP, sign in and one-time optional permissions', (
    tester,
  ) async {
    final container = await _boot(tester);
    final router = container.read(appRouterProvider);
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-language')), findsNothing);
    await _enter(tester, 'register-name', 'Widget Explorer');
    await _enter(tester, 'register-email', 'widget.explorer@example.test');
    await _enter(tester, 'register-phone', '+94 77 123 4567');
    await _enter(tester, 'register-password', 'widgetPassword7');
    await _enter(tester, 'register-confirm', 'widgetPassword7');
    await _tap(tester, const ValueKey('register-terms'));
    await _tap(tester, const ValueKey('register-submit'));
    expect(router.routeInformationProvider.value.uri.path, '/otp');
    await _enter(tester, 'auth-otp', '000000');
    await _tap(tester, const ValueKey('otp-verify'));
    expect(find.textContaining('Incorrect code'), findsOneWidget);
    await _enter(tester, 'auth-otp', MockData.demoOtp);
    await _tap(tester, const ValueKey('otp-verify'));
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
    expect(container.read(authViewModelProvider).user, isNull);
    await _enter(tester, 'auth-password', 'widgetPassword7');
    await _tap(tester, const ValueKey('auth-sign-in'));
    expect(router.routeInformationProvider.value.uri.path, '/permissions');
    await tester.ensureVisible(find.text('Not Now'));
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    final vm = container.read(authViewModelProvider.notifier);
    vm.signOut();
    await tester.pumpAndSettle();
    await _enter(tester, 'auth-password', 'widgetPassword7');
    await _tap(tester, const ValueKey('auth-sign-in'));
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovery UI verifies code before local password reset', (
    tester,
  ) async {
    final container = await _boot(tester);
    final router = container.read(appRouterProvider);
    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await _enter(tester, 'forgot-email', MockData.demoEmail);
    await _tap(tester, const ValueKey('forgot-submit'));
    await _enter(tester, 'auth-otp', MockData.demoOtp);
    await _tap(tester, const ValueKey('otp-verify'));
    expect(router.routeInformationProvider.value.uri.path, '/reset-password');
    await _enter(tester, 'reset-password', 'newWidgetPassword7');
    await _enter(tester, 'reset-confirm', 'newWidgetPassword7');
    await _tap(tester, const ValueKey('reset-submit'));
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
    await _enter(tester, 'auth-password', 'newWidgetPassword7');
    await _tap(tester, const ValueKey('auth-sign-in'));
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offline registration resumes to OTP and Android Back preserves draft',
    (tester) async {
      final container = await _boot(tester);
      final router = container.read(appRouterProvider);
      final vm = container.read(authViewModelProvider.notifier);
      vm.updateRegistration(
        const RegistrationDraft(
          name: 'Offline Explorer',
          email: 'offline.explorer@example.test',
          phone: '+94 77 123 4567',
          password: 'offlinePassword7',
          confirm: 'offlinePassword7',
          acceptedTerms: true,
        ),
      );
      vm.setOffline(true);
      router.go('/register');
      await tester.pumpAndSettle();
      await _tap(tester, const ValueKey('register-submit'));
      expect(router.routeInformationProvider.value.uri.path, '/offline');
      await _tap(tester, const ValueKey('offline-retry'));
      expect(
        router.routeInformationProvider.value.uri.path,
        '/connection-restored',
      );
      await _tap(tester, const ValueKey('offline-resume'));
      expect(router.routeInformationProvider.value.uri.path, '/otp');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/register');
      expect(
        container.read(authViewModelProvider).registration.name,
        'Offline Explorer',
      );
      expect(container.read(authViewModelProvider).flow, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
