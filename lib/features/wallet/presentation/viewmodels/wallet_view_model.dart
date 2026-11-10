import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_demo_storage.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../data/mock_wallet_repository.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_repository.dart';
export '../../domain/wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => MockWalletRepository(ref.read(localDemoStorageProvider)),
);
final walletViewModelProvider = NotifierProvider<WalletViewModel, WalletState>(
  WalletViewModel.new,
);
final walletClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final walletDemoToolsEnabledProvider = Provider<bool>((ref) => kDebugMode);

class _RewardCredit {
  const _RewardCredit(this.sourceId, this.hp, this.rc, this.title);
  final String sourceId, title;
  final int hp, rc;
}

class WalletViewModel extends Notifier<WalletState> {
  int _generation = 0, _writeId = 0;
  Future<void> _writes = Future.value();
  Future<void> _hydration = Future.value();
  List<_RewardCredit> _pendingCredits = [];
  String _userId = '';
  @override
  WalletState build() {
    final userId = ref.watch(authViewModelProvider.select((s) => s.user?.id));
    final user = ref.read(authViewModelProvider).user;
    final seed = ref.read(walletRepositoryProvider).initial(user);
    _userId = userId ?? MockData.currentUser['id'] as String;
    final owner = _userId;
    final generation = ++_generation;
    final pending = _pendingCredits = [];
    final loaded = Completer<void>();
    _hydration = loaded.future;
    Future.microtask(() async {
      try {
        final saved = await ref
            .read(walletRepositoryProvider)
            .restore(owner, seed);
        if (!ref.mounted || generation != _generation) return;
        state = (saved ?? seed).copyWith(initialized: true);
        for (final credit in List<_RewardCredit>.of(pending)) {
          creditReward(
            sourceId: credit.sourceId,
            hp: credit.hp,
            rc: credit.rc,
            title: credit.title,
          );
        }
        pending.clear();
      } catch (_) {
        if (ref.mounted && generation == _generation) {
          state = seed.copyWith(
            initialized: true,
            error: 'Saved wallet could not be loaded. Local demo balances are available.',
          );
          for (final credit in List<_RewardCredit>.of(pending)) {
            creditReward(
              sourceId: credit.sourceId,
              hp: credit.hp,
              rc: credit.rc,
              title: credit.title,
            );
          }
          pending.clear();
        }
      } finally {
        loaded.complete();
      }
    });
    return seed;
  }

  bool _commit(WalletState next) {
    if (next.integrityError case final error?) return _fail(error);
    state = next;
    final writeId = ++_writeId;
    final userId = _userId;
    final repo = ref.read(walletRepositoryProvider);
    _writes = _writes
        .then((_) async {
          await repo.save(userId, next);
          if (ref.mounted && _userId == userId && writeId == _writeId) {
            state = state.copyWith(clearPersistenceError: true);
          }
        })
        .catchError((Object error) {
          if (ref.mounted && _userId == userId && writeId == _writeId) {
            state = state.copyWith(
              persistenceError: 'Changes are in memory. Retry saving this wallet on the device.',
            );
          }
        });
    return true;
  }

  Future<void> get initialized => _hydration;
  Future<void> get persistenceSettled async {
    await _hydration;
    await _writes;
  }

  void retryPersistence() {
    if (state.initialized) _commit(state);
  }

  bool _fail(String message) {
    state = state.copyWith(error: message);
    return false;
  }

  DateTime get _now => ref.read(walletClockProvider)();
  bool get _canDecide =>
      state.initialized && ref.read(walletDemoToolsEnabledProvider);
  void category(String value) => state = state.copyWith(category: value);
  void historyType(String value) => state = state.copyWith(historyType: value);
  void usedTab(bool value) => state = state.copyWith(usedTab: value);
  void selectOffer(String id) => state = state.copyWith(
    selectedOfferId: id,
    intentId: const Uuid().v4(),
    clearRequest: true,
    clearVoucher: true,
  );
  void selectRequest(String id) {
    final r = state.requests.where((r) => r.id == id).firstOrNull;
    state = state.copyWith(selectedRequestId: id, selectedOfferId: r?.offerId);
  }

  void selectVoucher(String id) {
    final v = state.vouchers.where((v) => v.id == id).firstOrNull;
    state = state.copyWith(selectedVoucherId: id, selectedOfferId: v?.offerId);
  }

  String request({String? offerId, String? intentId}) {
    if (!state.initialized) {
      _fail('Wallet is loading. Please try again shortly.');
      return '/wallet';
    }
    final offer = state.offerById(offerId ?? state.selectedOfferId);
    if (offer == null) return '/wallet/choose';
    final token = intentId ?? state.intentId;
    if (token == null) {
      _fail('Choose a voucher before confirming.');
      return '/wallet/choose';
    }
    final existing = state.requests
        .where((r) => r.intentId == token)
        .firstOrNull;
    if (existing != null) {
      state = state.copyWith(
        selectedRequestId: existing.id,
        error: 'This request was already submitted.',
      );
      return routeForRequest(existing);
    }
    if (state.availableRc < offer.cost) {
      _fail(
        'Insufficient available RC. Pending requests reserve part of your balance.',
      );
      return '/wallet/insufficient?offer=${Uri.encodeQueryComponent(offer.id)}';
    }
    if (state.availableStock(offer.id) == null) {
      _fail('No demo vouchers remain for this reward. Choose another reward.');
      return '/wallet/choose';
    }
    final id = 'WH-DEMO-${const Uuid().v4()}';
    final r = VoucherRequest(
      id: id,
      offerId: offer.id,
      cost: offer.cost,
      intentId: token,
      created: _now,
    );
    final committed = _commit(
      state.copyWith(
        requests: [...state.requests, r],
        selectedRequestId: id,
        entries: [
          WalletEntry(
            id: 'request:$id',
            type: 'Voucher',
            title: 'DEMO voucher request',
            amount: 0,
            status: 'Pending',
            date: _now,
            requestId: id,
          ),
          ...state.entries,
        ],
      ),
    );
    return committed ? routeForRequest(r) : '/wallet/choose';
  }

  String routeForRequest(VoucherRequest r) =>
      '${switch (r.status) {
        RequestStatus.pending => '/wallet/pending',
        RequestStatus.approved => '/wallet/approved',
        RequestStatus.rejected => '/wallet/rejected',
      }}?id=${Uri.encodeQueryComponent(r.id)}';

  bool approve(String id) {
    if (!_canDecide) {
      return _fail(
        'DEMO approval is available only in the debug testing area after the wallet loads.',
      );
    }
    final r = state.requests.where((r) => r.id == id).firstOrNull;
    if (r == null || r.status != RequestStatus.pending) {
      return _fail('This request is missing or has already been decided.');
    }
    if (state.rc < r.cost) {
      return _fail('The posted RC balance cannot cover this request.');
    }
    if (state.vouchers.any((v) => v.requestId == id || v.id == 'voucher:$id')) {
      return _fail('A voucher has already been assigned to this request.');
    }
    final stock = state.availableStock(r.offerId);
    if (stock == null) {
      return _fail(
        'Demo voucher stock is exhausted. Reject the request to release its RC reservation.',
      );
    }
    final now = _now;
    final v = DemoVoucher(
      id: 'voucher:$id',
      offerId: r.offerId,
      code: 'DEMO-NOT-REDEEMABLE-${stock.code}-$id'.toUpperCase(),
      issued: now,
      expires: now.add(Duration(days: state.voucherValidityDays)),
      stockId: stock.id,
      requestId: id,
    );
    return _commit(
      state.copyWith(
        rc: state.rc - r.cost,
        requests: state.requests
            .map(
              (q) => q.id == id
                  ? q.decided(
                      RequestStatus.approved,
                      '',
                      at: now,
                      voucherId: v.id,
                    )
                  : q,
            )
            .toList(),
        vouchers: [...state.vouchers, v],
        selectedRequestId: id,
        selectedVoucherId: v.id,
        entries: [
          WalletEntry(
            id: 'approve:$id',
            type: 'Voucher',
            title: 'DEMO voucher issued',
            amount: 0,
            status: 'Approved',
            date: now,
            requestId: id,
            voucherId: v.id,
          ),
          WalletEntry(
            id: 'deduct:$id',
            type: 'RC',
            title: 'RC deducted for DEMO voucher',
            amount: -r.cost,
            status: 'Completed',
            date: now,
            requestId: id,
            voucherId: v.id,
          ),
          ...state.entries,
        ],
      ),
    );
  }

  /// The owner can withdraw an undecided local request. This frees its RC
  /// reservation without issuing stock or posting an RC debit. It uses the
  /// existing rejected terminal state with an explicit cancellation reason.
  bool cancelPending(String id) {
    if (!state.initialized) return _fail('Wallet is still loading.');
    final request = state.requestById(id);
    if (request == null || request.status != RequestStatus.pending) {
      return _fail('Only pending requests can be cancelled.');
    }
    final now = _now;
    return _commit(
      state.copyWith(
        requests: state.requests
            .map(
              (r) => r.id == id
                  ? r.decided(
                      RequestStatus.rejected,
                      'Cancelled by you. Reserved RC was released.',
                      at: now,
                    )
                  : r,
            )
            .toList(),
        selectedRequestId: id,
        entries: [
          WalletEntry(
            id: 'cancel:$id',
            type: 'Voucher',
            title: 'DEMO voucher request cancelled',
            amount: 0,
            status: 'Cancelled',
            date: now,
            requestId: id,
          ),
          ...state.entries,
        ],
      ),
    );
  }

  bool reject(String id) {
    if (!_canDecide) {
      return _fail(
        'DEMO rejection is available only in the debug testing area after the wallet loads.',
      );
    }
    final r = state.requests.where((r) => r.id == id).firstOrNull;
    if (r == null || r.status != RequestStatus.pending) {
      return _fail('This request is missing or has already been decided.');
    }
    return _commit(
      state.copyWith(
        requests: state.requests
            .map(
              (q) => q.id == id
                  ? q.decided(
                      RequestStatus.rejected,
                      'Developer DEMO rejection; held RC released.',
                      at: _now,
                    )
                  : q,
            )
            .toList(),
        selectedRequestId: id,
        entries: [
          WalletEntry(
            id: 'reject:$id',
            type: 'Voucher',
            title: 'DEMO request rejected',
            amount: 0,
            status: 'Rejected',
            date: _now,
            requestId: id,
          ),
          ...state.entries,
        ],
      ),
    );
  }

  bool useVoucher(String id) {
    if (!_canDecide) {
      return _fail('DEMO merchant testing is disabled outside the debug area.');
    }
    final v = state.vouchers.where((v) => v.id == id).firstOrNull;
    if (v == null) return _fail('Invalid demo voucher code.');
    if (v.used) return _fail('This voucher has already been used.');
    if (!v.activeAt(_now)) return _fail('This voucher has expired.');
    return _commit(
      state.copyWith(
        vouchers: state.vouchers
            .map((q) => q.id == id ? q.markUsed() : q)
            .toList(),
        selectedVoucherId: id,
        entries: [
          WalletEntry(
            id: 'used:$id',
            type: 'Voucher',
            title: 'DEMO voucher marked used',
            amount: 0,
            status: 'Used',
            date: _now,
            requestId: v.requestId,
            voucherId: v.id,
          ),
          ...state.entries,
        ],
      ),
    );
  }

  bool useVoucherCode(String code) {
    final input = code.trim().toUpperCase();
    final voucher = state.vouchers
        .where(
          (v) =>
              v.code.toUpperCase() == input ||
              v.qrPayload.toUpperCase() == input,
        )
        .firstOrNull;
    return voucher == null
        ? _fail('Invalid demo voucher code.')
        : useVoucher(voucher.id);
  }

  bool creditReward({
    required String sourceId,
    required int hp,
    required int rc,
    required String title,
  }) {
    if (state.credited.contains(sourceId) ||
        hp < 0 ||
        rc < 0 ||
        sourceId.isEmpty) {
      return false;
    }
    if (!state.initialized) {
      if (_pendingCredits.any((c) => c.sourceId == sourceId)) return false;
      _pendingCredits.add(_RewardCredit(sourceId, hp, rc, title));
      return true;
    }
    final now = _now;
    return _commit(
      state.copyWith(
        hp: state.hp + hp,
        rc: state.rc + rc,
        lifetimeHp: state.lifetimeHp + hp,
        credited: {...state.credited, sourceId},
        entries: [
          if (hp > 0)
            WalletEntry(
              id: '$sourceId:hp',
              type: 'HP',
              title: title,
              amount: hp,
              status: 'Completed',
              date: now,
            ),
          if (rc > 0)
            WalletEntry(
              id: '$sourceId:rc',
              type: 'RC',
              title: title,
              amount: rc,
              status: 'Completed',
              date: now,
            ),
          ...state.entries,
        ],
      ),
    );
  }
}
