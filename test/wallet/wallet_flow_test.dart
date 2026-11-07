import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wayhunter_mobile/app/app.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:wayhunter_mobile/features/games/presentation/viewmodels/game_view_model.dart';
import 'package:wayhunter_mobile/features/hunter/presentation/providers/hunter_providers.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/viewmodels/wallet_view_model.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/views/wallet_demo_screen.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/views/wallet_overview_screen.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/views/wallet_redemption_screens.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/views/wallet_voucher_screens.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/views/wallet_ui.dart'
    show walletNumber;

import '../widget_test.dart' show boot, demoSignIn, capture, loadReviewFonts;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'After tapping $finder');
}

Future<ProviderContainer> _wallet(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  final c = await boot(tester, size: size);
  await demoSignIn(tester);
  c.read(appRouterProvider).go('/wallet');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  setUpAll(loadReviewFonts);

  testWidgets(
    'Profile and Game Rewards open the same wallet and shared credits appear in its balances',
    (tester) async {
      final c = await boot(tester);
      await demoSignIn(tester);
      await _tap(tester, find.byTooltip('Open Profile'));
      await _tap(tester, find.byKey(const ValueKey('profile-tab-4')));
      expect(find.byType(WalletOverviewScreen), findsOneWidget);
      await _tap(tester, find.byTooltip('Go back'));
      expect(c.read(appRouterProvider).state.uri.path, '/profile');
      await _tap(tester, find.byKey(const ValueKey('profile-tab-4')));
      final before = c.read(walletViewModelProvider);
      c.read(gameRewardSinkProvider)(
        sourceId: 'widget-game-win',
        hp: 40,
        rc: 20,
        title: 'Game reward',
      );
      c.read(hunterRewardCreditProvider)(
        sourceId: 'widget-hunter-approved',
        hp: 50,
        title: 'Hunter reward',
      );
      await tester.pumpAndSettle();
      expect(find.text(walletNumber.format(before.hp + 90)), findsOneWidget);
      // The balance formatter includes grouping separators.
      expect(c.read(walletViewModelProvider).rc, before.rc + 20);
      await c
          .read(authViewModelProvider.notifier)
          .saveDemoProfile(name: 'Wallet Test Traveller');
      await tester.pumpAndSettle();
      expect(c.read(walletViewModelProvider).hp, before.hp + 90);
      expect(c.read(walletViewModelProvider).rc, before.rc + 20);
      c.read(appRouterProvider).go('/game/rewards');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Open My Wallet'));
      expect(find.byType(WalletOverviewScreen), findsOneWidget);
      expect(c.read(walletViewModelProvider).hp, before.hp + 90);
      await _tap(tester, find.byTooltip('Go back'));
      expect(c.read(appRouterProvider).state.uri.path, '/game/rewards');
    },
  );

  testWidgets(
    'all eight screens complete pending, separate demo approval, QR/copy, merchant use and history',
    (tester) async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final c = await _wallet(tester);
      final vm = c.read(walletViewModelProvider.notifier);
      final before = c.read(walletViewModelProvider);
      await capture(tester, 'wallet-w01');
      await _tap(tester, find.byKey(const ValueKey('wallet-redeem')));
      expect(find.byType(WalletRewardsScreen), findsOneWidget);
      await capture(tester, 'wallet-w02');
      await _tap(tester, find.byKey(const ValueKey('wallet-offer-reward-500')));
      expect(find.byType(WalletConfirmScreen), findsOneWidget);
      await capture(tester, 'wallet-w03');
      final confirm = find.byKey(const ValueKey('wallet-confirm'));
      await tester.tap(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(WalletPendingScreen), findsOneWidget);
      final request = c.read(walletViewModelProvider).selectedRequest!;
      expect(
        c.read(walletViewModelProvider).requests.length,
        before.requests.length + 1,
      );
      expect(c.read(walletViewModelProvider).rc, before.rc);
      expect(c.read(walletViewModelProvider).heldRc, before.heldRc + 500);
      expect(
        c.read(walletViewModelProvider).vouchers.length,
        before.vouchers.length,
      );
      expect(find.text('DEMO approve'), findsNothing);
      await capture(tester, 'wallet-w04');
      await _tap(tester, find.text('Back to Wallet'));
      await _tap(tester, find.byKey(const ValueKey('wallet-rules')));
      await _tap(tester, find.byKey(const ValueKey('wallet-open-demo-tools')));
      expect(find.byType(WalletDemoScreen), findsOneWidget);
      await _tap(
        tester,
        find.byKey(ValueKey('wallet-demo-approve-${request.id}')),
      );
      expect(find.byType(WalletApprovedScreen), findsOneWidget);
      expect(c.read(walletViewModelProvider).rc, before.rc - 500);
      expect(vm.approve(request.id), isFalse);
      await tester.pumpAndSettle();
      expect(c.read(walletViewModelProvider).rc, before.rc - 500);
      await capture(tester, 'wallet-w05');
      await _tap(tester, find.byKey(const ValueKey('wallet-view-issued')));
      expect(find.byType(WalletVouchersScreen), findsOneWidget);
      final voucher = c
          .read(walletViewModelProvider)
          .vouchers
          .singleWhere((v) => v.requestId == request.id);
      await capture(tester, 'wallet-w06');
      await _tap(tester, find.byKey(ValueKey('wallet-voucher-${voucher.id}')));
      expect(find.byType(WalletVoucherDetailsScreen), findsOneWidget);
      final paintedQr =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(QrImageView),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as QrPainter;
      await tester.runAsync(() async {
        final actual = await paintedQr.toImageData(136);
        final expected = await QrPainter(
          data: voucher.qrPayload,
          version: QrVersions.auto,
          gapless: true,
        ).toImageData(136);
        expect(
          actual!.buffer.asUint8List(),
          orderedEquals(expected!.buffer.asUint8List()),
        );
      });
      expect(voucher.qrPayload, contains('NOT-REDEEMABLE'));
      await capture(tester, 'wallet-w07');
      await _tap(tester, find.byKey(const ValueKey('wallet-copy-code')));
      expect(copied, voucher.code);
      await _tap(tester, find.byKey(const ValueKey('wallet-how-to-use')));
      expect(
        find.textContaining('No shop or partner accepts this QR.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('wallet-how-to-use')));
      await _tap(tester, find.byKey(const ValueKey('wallet-open-merchant')));
      await _tap(tester, find.byKey(const ValueKey('wallet-merchant-use')));
      expect(
        c.read(walletViewModelProvider).voucherById(voucher.id)!.used,
        isTrue,
      );
      await _tap(tester, find.text('View voucher record'));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Used voucher'), findsOneWidget);
      c.read(appRouterProvider).go('/wallet/history');
      await tester.pumpAndSettle();
      expect(find.byType(WalletHistoryScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await capture(tester, 'wallet-w08');
      for (final type in ['HP', 'RC', 'Vouchers', 'All']) {
        await _tap(tester, find.byKey(ValueKey('wallet-tab-$type')));
        final entries = c.read(walletViewModelProvider).filteredEntries;
        expect(
          entries.every(
            (e) =>
                type == 'All' ||
                e.type == (type == 'Vouchers' ? 'Voucher' : type),
          ),
          isTrue,
        );
      }
      expect(
        c
            .read(walletViewModelProvider)
            .entries
            .any((e) => e.id == 'deduct:${request.id}'),
        isTrue,
      );
      expect(
        c
            .read(walletViewModelProvider)
            .entries
            .any((e) => e.id == 'used:${voucher.id}'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog filters, insufficient RC, empty vouchers, used/expired and invalid code states work',
    (tester) async {
      final c = await _wallet(tester);
      final before = c.read(walletViewModelProvider);
      await _tap(tester, find.byKey(const ValueKey('wallet-redeem')));
      await _tap(tester, find.byKey(const ValueKey('wallet-tab-Food')));
      expect(find.text('No food rewards available.'), findsOneWidget);
      await _tap(tester, find.text('Show all rewards'));
      await _tap(tester, find.byKey(const ValueKey('wallet-tab-Travel')));
      expect(find.text('No travel rewards available.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('wallet-tab-Shopping')));
      await _tap(
        tester,
        find.byKey(const ValueKey('wallet-offer-reward-2000')),
      );
      final button = find.descendant(
        of: find.byKey(const ValueKey('wallet-confirm')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(
        c.read(walletViewModelProvider).requests.length,
        before.requests.length,
      );
      await _tap(tester, find.text('View RC shortfall'));
      expect(find.byType(WalletInsufficientScreen), findsOneWidget);
      c.read(appRouterProvider).go('/wallet/vouchers');
      await tester.pumpAndSettle();
      expect(find.text('No active vouchers yet.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('wallet-tab-Used')));
      final expired = before.vouchers.firstWhere((v) => !v.used);
      await _tap(tester, find.byKey(ValueKey('wallet-voucher-${expired.id}')));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Expired voucher'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('wallet-open-merchant')));
      await tester.enterText(
        find.byKey(const ValueKey('wallet-merchant-code')),
        'invalid-demo-code',
      );
      await _tap(tester, find.byKey(const ValueKey('wallet-merchant-use')));
      expect(find.text('Invalid demo voucher code.'), findsWidgets);
      c.read(appRouterProvider).go('/wallet/voucher?id=missing');
      await tester.pumpAndSettle();
      expect(find.byType(WalletMissingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'separate demo rejection releases reserved RC and permits a new request',
    (tester) async {
      final c = await _wallet(tester);
      final vm = c.read(walletViewModelProvider.notifier);
      vm.selectOffer('reward-500');
      vm.request();
      final request = c.read(walletViewModelProvider).selectedRequest!;
      final posted = c.read(walletViewModelProvider).rc;
      c.read(appRouterProvider).go('/wallet/demo');
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.byKey(ValueKey('wallet-demo-reject-${request.id}')),
      );
      expect(find.byType(WalletRejectedScreen), findsOneWidget);
      expect(c.read(walletViewModelProvider).rc, posted);
      expect(
        c.read(walletViewModelProvider).requestById(request.id)!.status,
        RequestStatus.rejected,
      );
      expect(c.read(walletViewModelProvider).availableRc, 500);
      await _tap(tester, find.text('Choose another voucher'));
      await _tap(tester, find.byKey(const ValueKey('wallet-offer-reward-500')));
      await _tap(tester, find.byKey(const ValueKey('wallet-confirm')));
      expect(find.byType(WalletPendingScreen), findsOneWidget);
      expect(
        c.read(walletViewModelProvider).selectedRequestId,
        isNot(request.id),
      );
    },
  );

  testWidgets(
    'normal wallet has no approval controls when debug tools are disabled',
    (tester) async {
      final c = ProviderContainer(
        overrides: [
          localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
          walletDemoToolsEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const WayhunterApp()),
      );
      await tester.pumpAndSettle();
      await demoSignIn(tester);
      c.read(appRouterProvider).go('/wallet/rules');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wallet-open-demo-tools')),
        findsNothing,
      );
      c.read(appRouterProvider).go('/wallet/demo');
      await tester.pumpAndSettle();
      expect(find.text('DEMO tools disabled'), findsOneWidget);
      expect(find.text('DEMO approve'), findsNothing);
    },
  );

  testWidgets(
    'an open voucher removes its active QR at expiry without another wallet action',
    (tester) async {
      var now = DateTime(2026, 11, 6, 12);
      final c = ProviderContainer(
        overrides: [
          localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
          walletClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const WayhunterApp()),
      );
      await tester.pumpAndSettle();
      await demoSignIn(tester);
      final vm = c.read(walletViewModelProvider.notifier);
      await vm.initialized;
      vm.selectOffer('reward-500');
      vm.request();
      vm.approve(c.read(walletViewModelProvider).selectedRequestId!);
      final voucher = c.read(walletViewModelProvider).selectedVoucher!;
      now = voucher.expires.subtract(const Duration(seconds: 2));
      c
          .read(appRouterProvider)
          .go('/wallet/voucher?id=${Uri.encodeQueryComponent(voucher.id)}');
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      now = voucher.expires;
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Expired voucher'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(320, 568),
  ]) {
    testWidgets(
      'all eight wallet screens fit $size with fixed header and footer',
      (tester) async {
        final c = await _wallet(tester, size: size);
        final vm = c.read(walletViewModelProvider.notifier);
        vm.reject(c.read(walletViewModelProvider).requests.first.id);
        vm.selectOffer('reward-500');
        vm.request();
        final approvedId = c.read(walletViewModelProvider).selectedRequestId!;
        vm.approve(approvedId);
        final voucherId = c.read(walletViewModelProvider).selectedVoucherId!;
        vm.selectOffer('reward-500');
        vm.request();
        final pendingId = c.read(walletViewModelProvider).selectedRequestId!;
        vm.selectOffer('reward-500');
        final intent = c.read(walletViewModelProvider).intentId!;
        final routes = [
          '/wallet',
          '/wallet/choose',
          '/wallet/confirm?offer=reward-500&intent=$intent',
          '/wallet/pending?id=$pendingId',
          '/wallet/approved?id=$approvedId',
          '/wallet/vouchers',
          '/wallet/voucher?id=${Uri.encodeQueryComponent(voucherId)}',
          '/wallet/history',
        ];
        for (final route in routes) {
          c.read(appRouterProvider).go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          expect(find.textContaining('Phase 6 entry preview'), findsNothing);
          expect(find.byType(NavigationDestination), findsNWidgets(2));
          final nav = tester.getRect(find.byType(NavigationBar));
          expect(nav.bottom, lessThanOrEqualTo(size.height));
          expect(find.byTooltip('Go back').hitTestable(), findsOneWidget);
          if (!route.contains('/choose') &&
              !route.contains('/history') &&
              !route.contains('/vouchers')) {
            expect(
              find.byType(SingleChildScrollView),
              findsNothing,
              reason: route,
            );
          }
        }
        c
            .read(appRouterProvider)
            .go('/wallet/voucher?id=${Uri.encodeQueryComponent(voucherId)}');
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(const ValueKey('wallet-how-to-use')));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
