import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/viewmodels/wallet_view_model.dart';

import '../screenshot_harness.dart';

/// Exercises the existing local ledger through its normal prototype actions.
/// No balance, reward, stock or fixture is injected by this capture module.
Future<void> captureWallet(ScreenshotHarness h) async {
  await h.reset();
  const module = 'wallet';
  final vm = h.container.read(walletViewModelProvider.notifier);
  await vm.initialized;
  await h.settle();

  Future<void> go(String route) async {
    // Reset only transient UI after a failed capture, preserving ledger state.
    while (find.byType(AlertDialog).evaluate().isNotEmpty ||
        find.byType(SimpleDialog).evaluate().isNotEmpty ||
        find.byType(BottomSheet).evaluate().isNotEmpty) {
      h.tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await h.settle();
    }
    await h.go(route);
  }

  WalletState state() => h.container.read(walletViewModelProvider);
  String requestRoute(String route, String id) =>
      '$route?id=${Uri.encodeQueryComponent(id)}';
  Future<void> shot(
    String file,
    String name,
    String route, {
    String notes = '',
  }) => h.attempt(module, name, route, () async {
    await go(route);
    await h.capture(module, file, name, route, notes: notes);
  });

  await shot('01_overview.png', 'W-01 My Wallet overview', '/wallet');
  await shot(
    '02_choose_voucher.png',
    'W-02 Choose Voucher — All',
    '/wallet/choose',
  );
  await shot(
    '03_confirm_no_selection.png',
    'Confirm Redemption — choose reward first',
    '/wallet/confirm',
  );
  for (final (category, file) in [
    ('Shopping', '04_choose_shopping.png'),
    ('Food', '05_choose_food_empty.png'),
    ('Travel', '06_choose_travel_empty.png'),
  ]) {
    vm.category(category);
    await shot(file, 'Choose Voucher — $category', '/wallet/choose');
  }
  vm.category('All');
  await shot(
    '07_my_vouchers_empty_active.png',
    'My Vouchers — no active vouchers',
    '/wallet/vouchers',
  );
  vm.usedTab(true);
  await shot(
    '08_my_vouchers_used_expired.png',
    'My Vouchers — Used / Expired',
    '/wallet/vouchers',
  );
  for (final voucher in state().vouchers) {
    final used = voucher.used;
    await shot(
      used ? '10_voucher_used.png' : '09_voucher_expired.png',
      used ? 'W-EX Used voucher details' : 'W-EX Expired voucher details',
      requestRoute('/wallet/voucher', voucher.id),
    );
  }
  vm.usedTab(false);
  vm.selectOffer(state().offers.reduce((a, b) => a.cost > b.cost ? a : b).id);
  await shot(
    '11_confirm_insufficient.png',
    'Confirm Redemption — insufficient available RC',
    '/wallet/confirm?offer=${state().selectedOfferId}&intent=${state().intentId}',
  );
  await shot(
    '12_insufficient_rc.png',
    'W-LO Insufficient RC',
    '/wallet/insufficient?offer=${state().selectedOfferId}',
  );

  final seedPending = state().requests
      .where((r) => r.status == RequestStatus.pending)
      .first;
  final seedPendingRoute = requestRoute('/wallet/pending', seedPending.id);
  await shot(
    '13_seed_request_pending.png',
    'Seed request pending with reserved RC',
    seedPendingRoute,
  );
  await h.attempt(
    module,
    'Cancel pending request confirmation',
    seedPendingRoute,
    () async {
      await go(seedPendingRoute);
      await h.tap(find.byKey(const ValueKey('wallet-cancel-pending')));
      await h.capture(
        module,
        '14_cancel_request_confirmation.png',
        'Cancel pending request confirmation',
        seedPendingRoute,
      );
      await h.tap(find.byKey(const ValueKey('wallet-confirm-cancel-pending')));
      await h.capture(
        module,
        '15_request_cancelled.png',
        'Request Cancelled — reservation released',
        requestRoute('/wallet/rejected', seedPending.id),
      );
    },
  );

  final offer = state().offers.reduce((a, b) => a.cost < b.cost ? a : b);
  String? approvedRequestId, activeVoucherId;
  await h.attempt(
    module,
    'W-03 through W-07 redemption and approval',
    '/wallet/confirm',
    () async {
      vm.selectOffer(offer.id);
      final confirmRoute =
          '/wallet/confirm?offer=${offer.id}&intent=${state().intentId}';
      await go(confirmRoute);
      await h.capture(
        module,
        '16_confirm_redemption.png',
        'W-03 Confirm Redemption',
        confirmRoute,
      );
      await h.tap(find.byKey(const ValueKey('wallet-confirm')));
      final request = state().selectedRequest!;
      approvedRequestId = request.id;
      expect(request.status, RequestStatus.pending);
      await h.capture(
        module,
        '17_request_submitted_pending.png',
        'W-04 Request Submitted — Pending',
        requestRoute('/wallet/pending', request.id),
      );
      await go('/wallet/demo');
      await h.capture(
        module,
        '18_developer_requests.png',
        'Developer DEMO request review',
        '/wallet/demo',
      );
      await h.tap(find.byKey(ValueKey('wallet-demo-approve-${request.id}')));
      expect(state().requestById(request.id)!.status, RequestStatus.approved);
      activeVoucherId = state().selectedVoucherId;
      await h.capture(
        module,
        '19_request_approved.png',
        'W-05 Request Approved',
        requestRoute('/wallet/approved', request.id),
      );
      await h.tap(find.byKey(const ValueKey('wallet-view-issued')));
      await h.capture(
        module,
        '20_my_vouchers_active.png',
        'W-06 My Vouchers — Active',
        '/wallet/vouchers',
      );
      final voucher = state().selectedVoucher!;
      await h.tap(find.byKey(ValueKey('wallet-voucher-${voucher.id}')));
      await h.capture(
        module,
        '21_voucher_details_qr.png',
        'W-07 Voucher Details — DEMO QR and code',
        requestRoute('/wallet/voucher', voucher.id),
      );
      await h.tap(find.byKey(const ValueKey('wallet-how-to-use')));
      await h.capture(
        module,
        '22_voucher_how_to_use.png',
        'Voucher Details — How to Use expanded',
        requestRoute('/wallet/voucher', voucher.id),
      );
    },
  );

  await h.attempt(
    module,
    'W-RJ rejected request',
    '/wallet/rejected',
    () async {
      vm.selectOffer(offer.id);
      final pendingRoute = vm.request();
      final request = state().selectedRequest!;
      expect(request.status, RequestStatus.pending, reason: pendingRoute);
      await vm.persistenceSettled;
      await go('/wallet/demo');
      await h.tap(find.byKey(ValueKey('wallet-demo-reject-${request.id}')));
      expect(state().requestById(request.id)!.status, RequestStatus.rejected);
      await h.capture(
        module,
        '23_request_rejected.png',
        'W-RJ Request Rejected — RC hold released',
        requestRoute('/wallet/rejected', request.id),
      );
    },
  );

  if (activeVoucherId case final id?) {
    await h.attempt(
      module,
      'Developer DEMO merchant and used state',
      '/wallet/demo',
      () async {
        final voucher = state().voucherById(id)!;
        vm.selectVoucher(id);
        final route =
            '/wallet/demo?code=${Uri.encodeQueryComponent(voucher.code)}';
        await go(route);
        await h.capture(
          module,
          '24_developer_merchant.png',
          'Developer DEMO merchant form',
          route,
        );
        await h.tester.enterText(
          find.byKey(const ValueKey('wallet-merchant-code')),
          'invalid-demo-code',
        );
        await h.tap(find.byKey(const ValueKey('wallet-merchant-use')));
        await h.capture(
          module,
          '25_merchant_invalid_code.png',
          'DEMO merchant — invalid code error',
          route,
        );
        await h.tester.enterText(
          find.byKey(const ValueKey('wallet-merchant-code')),
          voucher.code,
        );
        await h.tap(find.byKey(const ValueKey('wallet-merchant-use')));
        expect(state().voucherById(id)!.used, isTrue);
        await h.capture(
          module,
          '26_merchant_used_success.png',
          'DEMO merchant — voucher marked used',
          route,
        );
        await go(requestRoute('/wallet/voucher', id));
        await h.capture(
          module,
          '27_new_voucher_used_details.png',
          'Voucher Details — newly used voucher',
          requestRoute('/wallet/voucher', id),
        );
      },
    );
  } else {
    h.missing(
      module,
      'Active QR / DEMO merchant simulation',
      '/wallet/voucher',
      'The approval capture did not create an active voucher; see preceding failure.',
    );
  }

  vm.historyType('All');
  await shot(
    '28_transaction_history.png',
    'W-08 Transaction History — All',
    '/wallet/history',
  );
  for (final (type, file) in [
    ('HP', '29_history_hp.png'),
    ('RC', '30_history_rc.png'),
    ('Vouchers', '31_history_vouchers.png'),
  ]) {
    vm.historyType(type);
    await shot(file, 'Transaction History — $type', '/wallet/history');
  }
  await h.attempt(
    module,
    'Transaction detail dialog',
    '/wallet/history',
    () async {
      vm.historyType('HP');
      await go('/wallet/history');
      final entry = state().filteredEntries.first;
      await h.tap(find.byKey(ValueKey('wallet-transaction-${entry.id}')));
      await h.capture(
        module,
        '32_transaction_details.png',
        'Transaction detail dialog',
        '/wallet/history',
      );
      await h.tap(find.text('Close'));
    },
  );
  vm.historyType('All');
  await shot('33_wallet_rules.png', 'Wallet Rules', '/wallet/rules');
  await shot(
    '34_missing_voucher_record.png',
    'Wallet record unavailable — missing voucher',
    '/wallet/voucher?id=missing',
  );
  await shot(
    '35_unapproved_request_error.png',
    'Wallet record unavailable — approval missing',
    '/wallet/approved?id=missing',
  );
  if (approvedRequestId != null) {
    await shot(
      '36_pending_route_after_approval.png',
      'Pending route revisited after approval',
      requestRoute('/wallet/pending', approvedRequestId!),
    );
  }
}
