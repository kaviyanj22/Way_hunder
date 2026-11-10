import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/features/hunter/domain/hunter_models.dart';
import 'package:wayhunter_mobile/features/hunter/presentation/viewmodels/hunter_view_model.dart';

import '../screenshot_harness.dart';

Future<void> captureHunter(ScreenshotHarness h) async {
  await h.reset();
  final vm = h.container.read(hunterViewModelProvider.notifier);
  await _hunterShot(h, '01_home.png', 'Hunter Home', '/hunter');
  vm.search('no matching local discovery');
  await _hunterShot(h, '02_search_empty.png', 'Hunter search empty result', '/hunter');
  vm.search('');
  vm.beginDiscovery();
  await _hunterShot(h, '03_add_place.png', 'Add New Place', '/hunter/add');
  expect(vm.validateDetails(), isFalse);
  await _hunterShot(h, '31_add_validation_error.png', 'Add New Place validation error', '/hunter/add');
  final seed = h.container.read(hunterViewModelProvider).seed;
  final sample = seed.submissions.first;
  vm.updateDetails(
    name: '${sample.name} DEMO',
    address: sample.address,
    description: '${sample.name}, ${sample.district}. Local demo discovery.',
  );
  await _hunterShot(h, '04_add_place_details.png', 'Add New Place filled', '/hunter/add');
  await _hunterShot(h, '05_gps.png', 'GPS and restricted-zone check', '/hunter/gps');
  vm.setRestricted(true);
  vm.runDemoGpsCheck();
  await _hunterShot(h, '06_gps_restricted.png', 'Restricted-zone error', '/hunter/gps');
  vm.setRestricted(false);
  vm.setDuplicateSimulation(true);
  await h.attempt('hunter', 'Duplicate place warning', '/hunter/gps', () async {
    await h.go('/hunter/gps');
    await h.tap(find.text('Verify District (DEMO)'));
    await h.capture('hunter', '07_duplicate_warning.png', 'Duplicate place warning', '/hunter/gps',
        notes: 'H-DUP is the implemented validation dialog, not a separate route.');
    await h.tap(find.text('OK'));
  });
  vm.setDuplicateSimulation(false);
  expect(vm.runDemoGpsCheck(), isTrue);
  expect(vm.checkDuplicate(), isTrue);
  await _hunterShot(h, '08_camera360.png', 'Live 360 Camera', '/hunter/camera360');
  await h.attempt('hunter', '360 camera device result', '/hunter/camera360', () async {
    await h.tap(find.text('Open Live Camera'));
    await h.capture('hunter', '09_camera360_device.png', '360 camera device result', '/hunter/camera360',
        notes: 'Actual native camera result; unavailable-device message is preserved if camera access fails.');
    if (find.text('Start Video').evaluate().isNotEmpty) {
      await h.tap(find.text('Start Video'));
      await h.capture('hunter', '10_camera360_recording.png', '360 evidence video recording', '/hunter/camera360',
          notes: 'Ordinary native video; the existing UI explicitly disclaims verified 360 capture.');
      await h.tap(find.text('Stop & Use Video'));
    } else {
      h.missing('hunter', 'Native video recording', '/hunter/camera360',
          'Native camera was unavailable. Existing explicit DEMO evidence path is captured.');
    }
  });
  expect(vm.complete360(), isTrue);
  await _hunterShot(h, '11_video_complete.png', '360 Video Complete', '/hunter/video-complete');
  vm.toggle360Preview();
  await _hunterShot(h, '12_video_preview.png', '360 DEMO evidence preview', '/hunter/video-complete');
  vm.toggle360Preview();
  await _hunterShot(h, '13_video_attached.png', 'Add Place with video attached', '/hunter/video-attached');
  await _hunterShot(h, '14_photo_camera.png', 'Normal Photo Camera', '/hunter/photo-camera');
  await h.attempt('hunter', 'Normal photo camera device result', '/hunter/photo-camera', () async {
    await h.tap(find.text('Open Live Camera'));
    await h.capture('hunter', '15_photo_camera_device.png', 'Normal photo camera device result', '/hunter/photo-camera');
  });
  // This is the same explicit local DEMO option supplied by the existing camera UI.
  expect(vm.attachPhoto(const HunterEvidence(demo: true)), isTrue);
  await _hunterShot(h, '16_review.png', 'Review New Place', '/hunter/review');
  await h.attempt('hunter', 'Submission success confirmation', '/hunter/review', () async {
    await h.go('/hunter/review');
    await h.tap(find.text('Submit for Verification'));
    await h.capture('hunter', '17_submit_success.png', 'Submission success confirmation', '/hunter/review');
    await h.tap(find.text('OK'));
  });
  final submittedId = h.container.read(hunterViewModelProvider).selectedId;
  await _hunterShot(h, '18_verification_pending.png', 'Verification Pending', '/hunter/verification');
  await _hunterShot(h, '19_admin_review.png', 'Developer DEMO Admin Review', '/hunter/admin-review');
  await h.attempt('hunter', 'Approval confirmation', '/hunter/admin-review', () async {
    await h.go('/hunter/admin-review');
    await h.tap(find.textContaining('Approve (DEMO)'));
    await h.capture('hunter', '20_approval_confirmation.png', 'DEMO approval confirmation', '/hunter/admin-review');
    await h.tap(find.text('OK'));
  });
  await _hunterShot(h, '21_verification_approved.png', 'Verification Approved', '/hunter/verification');
  // Rejection uses the existing centralized pending submission, not a second fixture.
  final pending = h.container.read(hunterViewModelProvider).submissions
      .where((s) => s.status == HunterStatus.pending).firstOrNull;
  if (pending != null) {
    vm.selectSubmission(pending.id);
    await h.attempt('hunter', 'Rejection confirmation', '/hunter/admin-review', () async {
      await h.go('/hunter/admin-review');
      await h.tap(find.text('Reject (DEMO)'));
      await h.capture('hunter', '22_rejection_confirmation.png', 'DEMO rejection confirmation', '/hunter/admin-review');
      await h.tap(find.text('OK'));
    });
    await _hunterShot(h, '23_verification_rejected.png', 'Verification Rejected', '/hunter/verification');
  }
  if (submittedId != null) vm.selectSubmission(submittedId);
  await _hunterShot(h, '24_rewards_all.png', 'Rewards and My Places', '/hunter/rewards');
  for (final entry in <(String, String)>[
    ('Pending', '25_rewards_pending.png'),
    ('Approved', '26_rewards_approved.png'),
    ('Rejected', '27_rewards_rejected.png'),
  ]) {
    vm.setRewardsTab(entry.$1);
    await _hunterShot(h, entry.$2, 'My Places ${entry.$1} filter', '/hunter/rewards');
  }
  vm.setRewardsTab('All');
  await _hunterShot(h, '28_leaderboard_district.png', 'Hunter Leaderboard District', '/hunter/leaderboard');
  vm.setLeaderboardFilter('Monthly');
  await _hunterShot(h, '29_leaderboard_monthly.png', 'Hunter Leaderboard Monthly', '/hunter/leaderboard');
  vm.setLeaderboardFilter('All-Time');
  await _hunterShot(h, '30_leaderboard_all_time.png', 'Hunter Leaderboard All Time', '/hunter/leaderboard');
}

Future<void> _hunterShot(ScreenshotHarness h, String file, String title, String route) =>
    h.attempt('hunter', title, route, () async {
      // Re-enter forms so their controllers read the current local draft.
      if (h.router.routeInformationProvider.value.uri.toString() == route) {
        await h.go('/home');
      }
      await h.go(route);
      await h.capture('hunter', file, title, route);
    });
