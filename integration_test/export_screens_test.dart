import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'modules/auth_home_capture.dart';
import 'modules/traveller_capture.dart';
import 'modules/hunter_capture.dart';
import 'modules/games_capture.dart';
import 'modules/profile_capture.dart';
import 'modules/wallet_capture.dart';
import 'screenshot_harness.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Export every existing Wayhunter screen and significant state', (tester) async {
    final h = ScreenshotHarness(tester, binding);
    const selected = String.fromEnvironment('SCREENSHOT_MODULE', defaultValue: 'all');
    final modules = <String>{};
    try {
      for (final entry in {
        'auth': captureAuth, 'home': captureHome, 'traveller': captureTraveller,
        'hunter': captureHunter, 'games': captureGames,
        'profile': captureProfile, 'wallet': captureWallet,
      }.entries) {
        if (selected == 'all' || selected == entry.key || (selected == 'remaining' && entry.key != 'auth')) {
          modules.add(entry.key);
          await h.attempt(entry.key, 'Module export', '', () => entry.value(h));
        }
      }
    } finally {
      if (!h.partial) h.auditRoutes(modules);
      binding.reportData ??= {};
      binding.reportData!['modules'] = modules.toList();
      binding.reportData!['partial'] = h.partial;
      await h.finish();
    }
    expect(h.rows.where((r) => r['status'] == 'Capture failed'), isEmpty,
      reason: 'Failed states are recorded accurately in screenshots/SCREEN_INDEX.md.');
  }, timeout: const Timeout(Duration(minutes: 40)));
}
