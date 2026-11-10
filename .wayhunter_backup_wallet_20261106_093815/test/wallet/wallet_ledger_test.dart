import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/games/presentation/viewmodels/game_view_model.dart';
import 'package:wayhunter_mobile/features/hunter/presentation/providers/hunter_providers.dart';
import 'package:wayhunter_mobile/features/wallet/data/mock_wallet_repository.dart';
import 'package:wayhunter_mobile/features/wallet/presentation/viewmodels/wallet_view_model.dart';

class _DelayedRepository extends MockWalletRepository {
  _DelayedRepository(super.storage);
  final result = Completer<WalletState?>();
  @override
  Future<WalletState?> restore(String userId, WalletState seed) =>
      result.future;
}

class _FailOnceStorage extends MemoryDemoStorage {
  bool fail = true;
  @override
  Future<void> writeString(String key, String value) async {
    if (fail) {
      fail = false;
      throw StateError('Test disk failure');
    }
    return super.writeString(key, value);
  }
}

void main() {
  late ProviderContainer container;
  late WalletViewModel vm;
  late MemoryDemoStorage storage;
  late DateTime now;
  WalletState state() => container.read(walletViewModelProvider);
  String request500() {
    vm.selectOffer('reward-500');
    vm.request();
    return state().selectedRequestId!;
  }

  setUp(() async {
    storage = MemoryDemoStorage();
    now = DateTime(2026, 11, 6, 12);
    container = ProviderContainer(
      overrides: [
        localDemoStorageProvider.overrideWithValue(storage),
        walletClockProvider.overrideWithValue(() => now),
      ],
    );
    vm = container.read(walletViewModelProvider.notifier);
    await vm.initialized;
  });
  tearDown(() => container.dispose());

  test('pending reserves RC without posting a deduction or issuing a voucher; repeat taps are idempotent', () {
    final before = state();
    vm.selectOffer('reward-500');
    final first = vm.request();
    final id = state().selectedRequestId;
    expect(vm.request(), first);
    expect(state().selectedRequestId, id);
    expect(state().requests.length, before.requests.length + 1);
    expect(state().rc, before.rc);
    expect(state().heldRc, before.heldRc + 500);
    expect(state().availableRc, before.availableRc - 500);
    expect(state().vouchers.length, before.vouchers.length);
    expect(state().entries.where((e) => e.requestId == id), hasLength(1));
    expect(state().availableRc, greaterThanOrEqualTo(0));
  });

  test('insufficient available RC cannot create a request', () {
    final count = state().requests.length;
    vm.selectOffer('reward-2000');
    expect(vm.request(), contains('/wallet/insufficient'));
    expect(state().requests, hasLength(count));
    expect(state().availableRc, greaterThanOrEqualTo(0));
  });

  test(
    'approval assigns one available voucher and posts exactly one RC debit',
    () {
      final id = request500();
      final before = state();
      expect(vm.approve(id), isTrue);
      expect(state().rc, before.rc - 500);
      expect(state().heldRc, before.heldRc - 500);
      expect(state().availableRc, before.availableRc);
      final voucher = state().vouchers.singleWhere((v) => v.requestId == id);
      expect(voucher.stockId, isNotNull);
      expect(voucher.code, contains('DEMO-NOT-REDEEMABLE'));
      expect(voucher.qrPayload, contains('NOT-REDEEMABLE'));
      expect(state().requestById(id)!.status, RequestStatus.approved);
      final snapshot = state();
      expect(vm.approve(id), isFalse);
      expect(vm.reject(id), isFalse);
      expect(state().rc, snapshot.rc);
      expect(state().entries, hasLength(snapshot.entries.length));
      expect(
        state().entries
            .where((e) => e.requestId == id && e.type == 'RC')
            .single
            .amount,
        -500,
      );
      expect(state().vouchers.where((v) => v.requestId == id), hasLength(1));
    },
  );

  test('rejection releases the hold without an RC deduction or a voucher', () {
    final id = request500();
    final before = state();
    expect(vm.reject(id), isTrue);
    expect(state().rc, before.rc);
    expect(state().heldRc, before.heldRc - 500);
    expect(state().availableRc, before.availableRc + 500);
    expect(state().vouchers.length, before.vouchers.length);
    expect(vm.reject(id), isFalse);
    expect(vm.approve(id), isFalse);
    expect(
      state().entries.where((e) => e.requestId == id && e.type == 'RC'),
      isEmpty,
    );
  });

  test('finite demo stock is never assigned twice or recycled after use', () {
    vm.creditReward(
      sourceId: 'stock-test-funding',
      hp: 0,
      rc: 6000,
      title: 'Test reward',
    );
    final count = state().stock.where((s) => s.offerId == 'reward-500').length;
    for (var i = 0; i < count; i++) {
      final id = request500();
      expect(vm.approve(id), isTrue);
      expect(vm.useVoucher(state().selectedVoucherId!), isTrue);
    }
    final before = state();
    vm.selectOffer('reward-500');
    expect(vm.request(), '/wallet/choose');
    expect(state().requests.length, before.requests.length);
    final vouchers = state().vouchers.where((v) => v.stockId != null).toList();
    expect(vouchers.map((v) => v.stockId).toSet(), hasLength(count));
    expect(vouchers.map((v) => v.code).toSet(), hasLength(count));
  });

  test('merchant demo accepts a valid code once and rejects used, expired and invalid codes', () {
    final id = request500();
    vm.approve(id);
    final voucher = state().selectedVoucher!;
    expect(vm.useVoucherCode(voucher.code), isTrue);
    expect(vm.useVoucherCode(voucher.qrPayload), isFalse);
    expect(state().error, contains('already been used'));
    expect(vm.useVoucherCode('not-a-voucher'), isFalse);
    expect(state().error, contains('Invalid'));
    final expired = state().vouchers.firstWhere(
      (v) => !v.used && !v.activeAt(now),
    );
    expect(vm.useVoucher(expired.id), isFalse);
    expect(state().error, contains('expired'));
    expect(
      state().entries.where((e) => e.id == 'used:${voucher.id}'),
      hasLength(1),
    );
  });

  test(
    'expiry is checked at use time, even for a previously active voucher',
    () {
      final id = request500();
      vm.approve(id);
      final voucher = state().selectedVoucher!;
      now = voucher.expires;
      expect(vm.useVoucher(voucher.id), isFalse);
      expect(state().error, contains('expired'));
      expect(voucher.statusAt(now), 'Expired');
    },
  );

  test('requests, assignments, transactions and reward deduplication survive local restore', () async {
    final id = request500();
    vm.approve(id);
    vm.useVoucher(state().selectedVoucherId!);
    vm.creditReward(
      sourceId: 'persisted-win',
      hp: 40,
      rc: 20,
      title: 'Game reward',
    );
    await vm.persistenceSettled;
    final before = state();
    container.dispose();
    container = ProviderContainer(
      overrides: [
        localDemoStorageProvider.overrideWithValue(storage),
        walletClockProvider.overrideWithValue(() => now),
      ],
    );
    vm = container.read(walletViewModelProvider.notifier);
    await vm.initialized;
    expect(state().rc, before.rc);
    expect(state().heldRc, before.heldRc);
    expect(
      state().vouchers.map((v) => v.toMap()),
      before.vouchers.map((v) => v.toMap()),
    );
    expect(
      state().entries.map((e) => e.toMap()),
      before.entries.map((e) => e.toMap()),
    );
    expect(
      vm.creditReward(
        sourceId: 'persisted-win',
        hp: 40,
        rc: 20,
        title: 'Repeated',
      ),
      isFalse,
    );
  });

  test(
    'Game and Hunter reward hooks credit the same authoritative wallet once',
    () {
      final before = state();
      final game = container.read(gameRewardSinkProvider);
      final hunter = container.read(hunterRewardCreditProvider);
      expect(
        game(sourceId: 'game-win', hp: 40, rc: 20, title: 'Game win'),
        isTrue,
      );
      expect(
        hunter(sourceId: 'hunter-approved', hp: 50, title: 'Hunter discovery'),
        isTrue,
      );
      expect(
        game(sourceId: 'game-win', hp: 40, rc: 20, title: 'Game win'),
        isFalse,
      );
      expect(state().hp, before.hp + 90);
      expect(state().rc, before.rc + 20);
      expect(state().lifetimeHp, before.lifetimeHp + 90);
      for (final type in ['HP', 'RC', 'Vouchers']) {
        vm.historyType(type);
        expect(
          state().filteredEntries.every(
            (e) => e.type == (type == 'Vouchers' ? 'Voucher' : type),
          ),
          isTrue,
        );
      }
    },
  );

  test('credits arriving during restore are merged with saved balances and deduplicated', () async {
    final repo = _DelayedRepository(storage);
    final seed = repo.initial(null);
    container.dispose();
    container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repo),
        localDemoStorageProvider.overrideWithValue(storage),
        walletClockProvider.overrideWithValue(() => now),
      ],
    );
    vm = container.read(walletViewModelProvider.notifier);
    expect(
      vm.creditReward(
        sourceId: 'early',
        hp: 40,
        rc: 20,
        title: 'Early game reward',
      ),
      isTrue,
    );
    expect(
      vm.creditReward(sourceId: 'early', hp: 40, rc: 20, title: 'Duplicate'),
      isFalse,
    );
    expect(
      vm.creditReward(
        sourceId: 'old-win',
        hp: 40,
        rc: 20,
        title: 'Old game reward',
      ),
      isTrue,
    );
    expect(vm.request(), '/wallet');
    repo.result.complete(
      seed.copyWith(hp: 4000, rc: 1200, credited: {'old-win'}),
    );
    await vm.persistenceSettled;
    expect(state().hp, 4040);
    expect(state().rc, 1220);
    expect(state().credited, containsAll(['old-win', 'early']));
    expect(state().entries.where((e) => e.id == 'early:rc'), hasLength(1));
  });

  test('debug approval, rejection and merchant actions are blocked when tools are disabled', () async {
    final before = state();
    container.dispose();
    container = ProviderContainer(
      overrides: [
        localDemoStorageProvider.overrideWithValue(storage),
        walletDemoToolsEnabledProvider.overrideWithValue(false),
      ],
    );
    vm = container.read(walletViewModelProvider.notifier);
    await vm.initialized;
    expect(vm.approve(state().requests.first.id), isFalse);
    expect(vm.reject(state().requests.first.id), isFalse);
    expect(vm.useVoucher(state().vouchers.first.id), isFalse);
    expect(state().rc, before.rc);
  });

  test('invalid saved balances fall back safely, and local storage is account-scoped', () async {
    final repo = MockWalletRepository(storage);
    final seed = repo.initial(null);
    await repo.save('bad-wallet', seed.copyWith(rc: -1));
    expect(await repo.restore('bad-wallet', seed), isNull);
    await repo.save('owner-a', seed.copyWith(rc: 2300));
    expect((await repo.restore('owner-a', seed))!.rc, 2300);
    expect(await repo.restore('owner-b', seed), isNull);
  });

  test('a local write failure is visible and retry saves without duplicate credits', () async {
    final disk = _FailOnceStorage();
    container.dispose();
    container = ProviderContainer(
      overrides: [localDemoStorageProvider.overrideWithValue(disk)],
    );
    vm = container.read(walletViewModelProvider.notifier);
    await vm.initialized;
    vm.creditReward(
      sourceId: 'retry-win',
      hp: 40,
      rc: 20,
      title: 'Game reward',
    );
    await vm.persistenceSettled;
    expect(state().persistenceError, isNotNull);
    final rc = state().rc;
    vm.retryPersistence();
    await vm.persistenceSettled;
    expect(state().persistenceError, isNull);
    expect(state().rc, rc);
    final saved = await MockWalletRepository(disk)
        .restore(MockData.currentUser['id'] as String, state());
    expect(saved!.credited, contains('retry-win'));
  });
}
