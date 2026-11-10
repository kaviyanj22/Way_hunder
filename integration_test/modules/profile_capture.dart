import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screenshot_harness.dart';

/// Captures the existing profile routes and their implemented modal branches.
/// Reference-only pages are recorded as missing instead of constructing new UI.
Future<void> captureProfile(ScreenshotHarness h) async {
  await h.reset();
  const module = 'profile';
  Future<void> go(String route) async {
    // A failed capture must not leave an old dialog covering the next route.
    while (find.byType(AlertDialog).evaluate().isNotEmpty ||
        find.byType(SimpleDialog).evaluate().isNotEmpty ||
        find.byType(BottomSheet).evaluate().isNotEmpty) {
      h.tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await h.settle();
    }
    await h.go(route);
  }

  Future<void> shot(String file, String name, String route) =>
      h.attempt(module, name, route, () async {
        await go(route);
        await h.capture(module, file, name, route);
      });

  await shot('01_profile_posts.png', 'Profile — Posts', '/profile');
  for (final (index, file, name) in [
    (0, '02_profile_games.png', 'Profile — Games'),
    (2, '03_profile_trips.png', 'Profile — Trips'),
    (3, '04_profile_hunt_places.png', 'Profile — Hunt Places'),
  ]) {
    await h.attempt(module, name, '/profile', () async {
      await go('/profile');
      await h.tap(find.byKey(ValueKey('profile-tab-$index')));
      await h.capture(module, file, name, '/profile');
    });
  }
  await h.attempt(module, 'My Badges dialog', '/profile', () async {
    await go('/profile');
    await h.tap(find.text('My Badges'));
    await h.capture(
      module,
      '05_profile_badges.png',
      'My Badges dialog',
      '/profile',
    );
    await h.tap(find.text('Close'));
  });
  await shot('06_edit_profile.png', 'Edit Profile', '/profile/edit');
  await h.attempt(
    module,
    'Edit Profile name validation',
    '/profile/edit',
    () async {
      await go('/profile');
      await go('/profile/edit');
      await h.tester.enterText(find.byType(TextField).first, '');
      await h.tap(find.text('Save Changes Locally'));
      await h.capture(
        module,
        '17_edit_profile_name_error.png',
        'Edit Profile — name validation error',
        '/profile/edit',
      );
    },
  );
  await shot('07_settings.png', 'Settings', '/profile/settings');

  Future<void> dialog(
    String file,
    String name,
    Finder action, {
    String close = 'OK',
    String notes = '',
  }) => h.attempt(module, name, '/profile/settings', () async {
    await go('/profile/settings');
    await h.tap(action);
    await h.capture(module, file, name, '/profile/settings', notes: notes);
    await h.tap(find.text(close));
  });

  await dialog(
    '08_security_password_info.png',
    'Security & Password information',
    find.text('Security & Password'),
    notes: 'Actual implementation is an explanatory dialog; no change-password form exists.',
  );
  await dialog(
    '09_language_choices.png',
    'Language choices dialog',
    find.textContaining('Language:'),
    close: 'English',
  );
  await dialog(
    '10_privacy_choices.png',
    'Privacy choices dialog',
    find.textContaining('Privacy:'),
    close: 'Public',
  );
  await h.attempt(
    module,
    'Notification preferences sheet',
    '/profile/settings',
    () async {
      await go('/profile/settings');
      await h.tap(find.text('Notifications'));
      await h.capture(
        module,
        '11_notification_preferences.png',
        'Notification preferences sheet',
        '/profile/settings',
      );
      // Close through the actual navigator without changing preferences.
      h.tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await h.settle();
    },
  );
  await dialog(
    '12_help_how_to_use_info.png',
    'How to Use Wayhunter information',
    find.text('Help & Support'),
    notes: 'Help opens this implemented information dialog directly.',
  );
  await dialog(
    '13_about_version.png',
    'About Wayhunter and version',
    find.text('About Wayhunter'),
  );
  await dialog(
    '14_account_deletion_info.png',
    'Account deletion information',
    find.text('Delete Account'),
    notes: 'Actual implementation explains that deletion is unavailable; it has no Yes/No deletion action.',
  );
  await dialog(
    '15_logout_confirmation.png',
    'Logout confirmation',
    find.text('Logout'),
    close: 'Cancel',
  );
  await shot(
    '16_settings_after_logout_cancel.png',
    'Settings after cancelling logout',
    '/profile/settings',
  );
  await h.attempt(
    module,
    'Sign In after confirmed logout',
    '/sign-in',
    () async {
      await go('/profile/settings');
      await h.tap(find.text('Logout'));
      await h.tap(find.text('Log Out'));
      await h.capture(
        module,
        '18_sign_in_after_logout.png',
        'Sign In after confirmed logout',
        '/sign-in',
      );
    },
  );

  h.missing(
    module,
    'UJ-042 dedicated change-password form',
    '(no implemented route)',
    'Settings implements the captured Security & Password information dialog only.',
  );
  h.missing(
    module,
    'UJ-046 help hub / P-MISS support destinations',
    '(no implemented route)',
    'Help & Support opens the captured How to Use information dialog; no FAQ/contact/report screens exist.',
  );
  h.missing(
    module,
    'UJ-047 dedicated How to Use page',
    '(no implemented route)',
    'The current implementation is the captured Help information dialog.',
  );
  h.missing(
    module,
    'UJ-048 app update / What is New page',
    '(no implemented route)',
    'Only the captured About/version dialog exists; there is no update UI.',
  );
  h.missing(
    module,
    'UJ-049 Delete Yes/No and P-DO cancellation',
    '(no implemented route)',
    'Delete Account opens the captured informational dialog; no deletion confirmation or P-DO page exists.',
  );
}
