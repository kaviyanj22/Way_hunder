import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:wayhunter_mobile/features/home/presentation/viewmodels/home_view_model.dart';
import '../screenshot_harness.dart';

Future<void> captureAuth(ScreenshotHarness h) async {
  await h.reset(signedIn: false);
  final vm = h.container.read(authViewModelProvider.notifier);
  Future<void> shot(String file, String name, String route) =>
      h.capture('auth', file, name, route);
  await h.attempt('auth', 'Sign In and validation', '/sign-in', () async {
    await h.go('/sign-in');
    await shot('01_login.png', 'Login', '/sign-in');
    await h.tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
    await shot('21_login_lower.png', 'Login lower controls and demo note', '/sign-in');
    await h.tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 500));
    await h.settle();
    await h.tap(find.byKey(const ValueKey('auth-language')));
    await shot('02_login_language.png', 'Login language dropdown', '/sign-in');
    await h.tap(find.text('English').last);
    await vm.signIn();
    await shot('03_login_missing_fields.png', 'Login missing fields', '/sign-in');
    vm.updateSignIn(email: MockData.demoEmail, password: '${MockData.demoPassword}!');
    await vm.signIn();
    await shot('04_login_incorrect.png', 'Incorrect login credentials', '/sign-in');
    vm.clearFeedback();
  });
  await h.attempt('auth', 'Register and OTP', '/register', () async {
    await h.go('/register');
    await shot('05_register.png', 'Register', '/register');
    await h.tap(find.text('I agree to Terms & Conditions'));
    await shot('06_register_terms.png', 'Registration terms dialog', '/register');
    await h.tap(find.text('Close'));
    await vm.register();
    await shot('07_register_validation.png', 'Register validation', '/register');
    final user = MockData.currentUser;
    vm.updateRegistration(RegistrationDraft(
      name: user['name']! as String,
      email: 'capture.${MockData.demoEmail}',
      phone: user['phone']! as String,
      password: MockData.demoPassword, confirm: MockData.demoPassword,
      acceptedTerms: true,
    ));
    final next = await vm.register();
    if (next != '/otp') throw StateError('Existing register action failed');
    await h.go(next!);
    await shot('08_registration_otp.png', 'Registration OTP', '/otp');
    vm.updateOtp('000000');
    await vm.verifyOtp();
    await shot('09_invalid_otp.png', 'Invalid OTP', '/otp');
    vm.updateOtp(MockData.demoOtp);
    await h.go((await vm.verifyOtp())!);
    await shot('10_registration_success.png', 'Registration success at Sign In', '/sign-in');
    vm.updateSignIn(password: MockData.demoPassword);
    await h.go((await vm.signIn())!);
    await shot('11_permissions.png', 'First-time permissions introduction', '/permissions');
    await h.tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
    await shot('22_permissions_lower.png', 'Permissions Continue / Not Now controls', '/permissions');
    await vm.completePermissions();
    vm.signOut();
    await h.go('/sign-in');
  });
  await h.attempt('auth', 'Recovery and reset', '/forgot-password', () async {
    vm.abandonOtp();
    await h.go('/forgot-password');
    await shot('12_forgot_password.png', 'Forgot Password', '/forgot-password');
    await vm.forgotPassword();
    await shot('13_forgot_validation.png', 'Forgot Password validation', '/forgot-password');
    vm.updateRecoveryEmail(MockData.demoEmail);
    await h.go((await vm.forgotPassword())!);
    await shot('14_recovery_otp.png', 'Recovery OTP', '/otp');
    vm.updateOtp(MockData.demoOtp);
    await h.go((await vm.verifyOtp())!);
    await shot('15_reset_password.png', 'Reset Password', '/reset-password');
    vm.updateReset(password: MockData.demoPassword, confirm: '${MockData.demoPassword}!');
    await vm.resetPassword();
    await shot('16_reset_mismatch.png', 'Reset password mismatch', '/reset-password');
    vm.updateReset(confirm: MockData.demoPassword);
    await h.go((await vm.resetPassword())!);
    await shot('17_reset_success.png', 'Password reset success', '/sign-in');
  });
  await h.attempt('auth', 'Offline Retry and Cancel', '/offline', () async {
    vm.signOut();
    vm.useDemoCredentials();
    vm.setOffline(true);
    await h.go((await vm.signIn())!);
    await shot('18_offline.png', 'Offline', '/offline');
    await h.go('/cancel-auth');
    await shot('19_cancel_auth.png', 'Cancel auth confirmation', '/cancel-auth');
    await h.go('/offline');
    vm.restoreConnection();
    await h.go('/connection-restored');
    await shot('20_connection_restored.png', 'Retry succeeds / Resume', '/connection-restored');
    vm.cancelPending();
  });
}

Future<void> captureHome(ScreenshotHarness h) async {
  await h.reset();
  final vm = h.container.read(homeViewModelProvider.notifier);
  await h.attempt('home', 'Home and branches', '/home', () async {
    await h.go('/home');
    await h.capture('home', '01_home.png', 'Home', '/home');
    await h.tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -350));
    await h.capture('home', '02_home_lower.png', 'Home module buttons and footer', '/home');
    await h.go('/home');
    await h.tap(find.byTooltip('Search places'));
    FocusManager.instance.primaryFocus?.unfocus();
    await h.capture('home', '03_search.png', 'Search local places', '/home');
    vm.search('no-match-for-screenshot');
    await h.capture('home', '04_search_empty.png', 'Search empty result', '/home');
    Navigator.of(h.tester.element(find.byType(TextField).first)).pop();
    await h.settle();
    await h.go('/home');
    await h.tap(find.text(h.container.read(homeViewModelProvider).content.advertisements.first.title));
    await h.capture('home', '05_advertisement.png', 'Demo advertisement dialog', '/home');
    await h.tap(find.text('Close'));
    await h.go('/notifications');
    await h.capture('home', '06_notifications.png', 'Notifications unread', '/notifications');
    vm.markNotificationsRead();
    await h.capture('home', '07_notifications_read.png', 'Notifications read', '/notifications');
    await h.go('/leaderboard');
    await h.capture('home', '08_leaderboard.png', 'Global leaderboard', '/leaderboard');
  });
  await h.attempt('home', 'Unavailable route', '/missing-screen', () async {
    await h.go('/missing-screen');
    await h.capture('home', '09_unavailable_route.png', 'Router unavailable trail fallback', '/missing-screen');
  });
  h.missing('app', 'Preference initialization', '/loading',
      'Transient loading route intentionally excluded: requested export must not capture loading screens.');
  h.missing('app', 'Obsolete entry preview classes', 'not routed',
      'FeatureEntryScreen/ProfileEntryScreen/WalletEntryScreen and superseded Traveller screen classes are unreachable historical implementations; current routed replacements are captured.');
}
