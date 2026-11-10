import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_demo_storage.dart';
import '../../auth/presentation/viewmodels/auth_view_model.dart';
import 'coin_wallet_models.dart';

final coinWalletClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final coinWalletDemoAdminEnabledProvider = Provider<bool>((ref) => kDebugMode);
final coinWalletProvider =
    NotifierProvider<CoinWalletViewModel, CoinWalletState>(
      CoinWalletViewModel.new,
    );

class _PendingCoinEvent {
  const _PendingCoinEvent(this.sourceId, this.title, this.coins, this.approved);
  final String sourceId, title;
  final int coins;
  final bool approved;
}

class CoinWalletViewModel extends Notifier<CoinWalletState> {
  String _userId = '';
  int _generation = 0;
  Future<void> _writes = Future.value();
  Future<void> _hydration = Future.value();
  List<_PendingCoinEvent> _eventsBeforeLoad = [];
  DateTime get _now => ref.read(coinWalletClockProvider)();
  bool get _canReview =>
      state.initialized && ref.read(coinWalletDemoAdminEnabledProvider);
  String get _key => 'wayhunter-coin-wallet-v1:$_userId';

  @override
  CoinWalletState build() {
    final id = ref.watch(authViewModelProvider.select((s) => s.user?.id));
    _userId = id ?? 'guest-local-demo';
    final demoAccount = id == 'demo-user-001';
    final initial = demoAccount ? 12800 : 100;
    final time = _now;
    final seed = CoinWalletState(
      totalEarned: initial,
      balance: initial,
      earnings: [
        CoinEarning(
          id: 'first-login',
          title: 'Welcome bonus (one time)',
          coins: 100,
          status: CoinReviewStatus.approved,
          createdAt: time,
        ),
      ],
      requests: const [],
      vouchers: const [],
      history: [
        CoinHistoryEntry(
          id: 'first-login',
          title: 'App registration / first login',
          coins: 100,
          date: time,
          status: 'Approved',
        ),
        if (demoAccount)
          CoinHistoryEntry(
            id: 'demo-seed',
            title: 'DEMO test balance only (not real earnings)',
            coins: 12700,
            date: time,
            status: 'DEMO',
          ),
      ],
    );
    final generation = ++_generation;
    final owner = _userId;
    final queued = _eventsBeforeLoad = [];
    final done = Completer<void>();
    _hydration = done.future;
    Future.microtask(() async {
      try {
        final raw = await ref
            .read(localDemoStorageProvider)
            .readString('wayhunter-coin-wallet-v1:$owner');
        if (!ref.mounted || generation != _generation) return;
        CoinWalletState loaded = seed;
        if (raw != null) {
          try {
            final parsed = CoinWalletState.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            );
            if (parsed.integrityError == null) loaded = parsed;
          } catch (_) {
            /* Keep the safe local seed if storage is malformed. */
          }
        }
        state = loaded.copyWith(initialized: true);
        for (final event in List<_PendingCoinEvent>.of(queued)) {
          recordEarning(
            sourceId: event.sourceId,
            title: event.title,
            coins: event.coins,
            approved: event.approved,
          );
        }
        queued.clear();
      } finally {
        if (!done.isCompleted) done.complete();
      }
    });
    return seed;
  }

  Future<void> get initialized => _hydration;
  Future<void> get persistenceSettled async {
    await _hydration;
    await _writes;
  }

  bool _fail(String error) {
    state = state.copyWith(error: error);
    return false;
  }

  bool _commit(CoinWalletState next) {
    if (next.integrityError case final message?) return _fail(message);
    state = next.copyWith(error: null);
    final owner = _userId;
    final json = jsonEncode(state.toJson());
    _writes = _writes
        .then(
          (_) => ref
              .read(localDemoStorageProvider)
              .writeString('wayhunter-coin-wallet-v1:$owner', json),
        )
        .catchError((Object _) {
          if (ref.mounted && owner == _userId) {
            state = state.copyWith(
              error: 'Local save failed. Your latest changes may not persist.',
            );
          }
        });
    return true;
  }

  /// Live social/game approval must eventually call this from a trusted .NET API.
  /// `approved:true` is used ONLY by the existing local Hunter demo moderator.
  bool recordEarning({
    required String sourceId,
    required String title,
    required int coins,
    bool approved = false,
  }) {
    if (sourceId.isEmpty || coins <= 0) return false;
    if (!state.initialized) {
      if (_eventsBeforeLoad.any((e) => e.sourceId == sourceId)) return false;
      _eventsBeforeLoad.add(
        _PendingCoinEvent(sourceId, title, coins, approved),
      );
      return true;
    }
    if (state.earnings.any((e) => e.id == sourceId)) return false;
    final next = CoinEarning(
      id: sourceId,
      title: title,
      coins: coins,
      status: approved ? CoinReviewStatus.approved : CoinReviewStatus.pending,
      createdAt: _now,
    );
    return _commit(
      state.copyWith(
        earnings: [...state.earnings, next],
        totalEarned: state.totalEarned + (approved ? coins : 0),
        balance: state.balance + (approved ? coins : 0),
        history: [
          CoinHistoryEntry(
            id: 'earning:$sourceId',
            title: title,
            coins: approved ? coins : 0,
            date: _now,
            status: approved ? 'Approved' : 'Pending admin approval',
          ),
          ...state.history,
        ],
      ),
    );
  }

  bool reviewEarning(String id, bool approve) {
    if (!_canReview)
      return _fail('Only local DEMO admin review is available here.');
    final earning = state.earnings.where((e) => e.id == id).firstOrNull;
    if (earning == null || earning.status != CoinReviewStatus.pending) {
      return _fail('Earning is missing or was already reviewed.');
    }
    return _commit(
      state.copyWith(
        earnings: [
          for (final e in state.earnings)
            e.id == id
                ? e.reviewed(
                    approve
                        ? CoinReviewStatus.approved
                        : CoinReviewStatus.rejected,
                  )
                : e,
        ],
        totalEarned: state.totalEarned + (approve ? earning.coins : 0),
        balance: state.balance + (approve ? earning.coins : 0),
        history: [
          CoinHistoryEntry(
            id: 'review-earning:$id',
            title:
                '${approve ? 'Congratulations! Approved' : 'Rejected'} · ${earning.title}',
            coins: approve ? earning.coins : 0,
            date: _now,
            status: approve ? 'Approved' : 'Rejected',
          ),
          ...state.history,
        ],
      ),
    );
  }

  /// Pending reserves spendability, but does NOT deduct the displayed balance.
  String? requestRedemption(int coins) {
    if (!state.initialized) {
      _fail('Wallet is still loading.');
      return null;
    }
    if (coins < 10000 || coins % 10000 != 0) {
      _fail('Minimum 10,000 Coins; use multiples of 10,000.');
      return null;
    }
    if (coins > state.redeemable) {
      _fail('Insufficient redeemable Coins (pending requests are reserved).');
      return null;
    }
    final id = const Uuid().v4();
    final request = CoinRedemptionRequest(
      id: id,
      coins: coins,
      createdAt: _now,
    );
    final ok = _commit(
      state.copyWith(
        requests: [...state.requests, request],
        history: [
          CoinHistoryEntry(
            id: 'request:$id',
            title: 'Voucher request submitted',
            coins: 0,
            date: _now,
            status: 'Pending',
          ),
          ...state.history,
        ],
      ),
    );
    return ok ? id : null;
  }

  bool reviewRedemption(String id, bool approve) {
    if (!_canReview)
      return _fail('Requires separate ADMIN approval; local demo tools only.');
    final request = state.request(id);
    if (request == null || request.status != CoinReviewStatus.pending) {
      return _fail('Request not found or already decided.');
    }
    final now = _now;
    final voucherId = const Uuid().v4();
    final voucher = CoinVoucher(
      id: voucherId,
      requestId: id,
      code: 'DEMO-WH-${voucherId.substring(0, 8).toUpperCase()}',
      valueLkr: request.valueLkr,
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 180)),
    );
    return _commit(
      state.copyWith(
        balance: state.balance - (approve ? request.coins : 0),
        requests: [
          for (final r in state.requests)
            r.id == id
                ? r.reviewed(
                    approve
                        ? CoinReviewStatus.approved
                        : CoinReviewStatus.rejected,
                    now,
                    voucherId: approve ? voucherId : null,
                    reason: approve ? '' : 'Rejected by local DEMO admin',
                  )
                : r,
        ],
        vouchers: approve ? [...state.vouchers, voucher] : state.vouchers,
        history: [
          CoinHistoryEntry(
            id: 'decision:$id',
            title: approve
                ? 'Voucher approved · DEMO issued'
                : 'Redemption rejected · hold released',
            coins: approve ? -request.coins : 0,
            date: now,
            status: approve ? 'Approved' : 'Rejected',
          ),
          ...state.history,
        ],
      ),
    );
  }

  bool useVoucherForDemo(String id) {
    if (!_canReview) return _fail('Only local DEMO admin can mark use.');
    final voucher = state.voucher(id);
    if (voucher == null || !voucher.activeAt(_now)) {
      return _fail('Voucher missing, used or expired.');
    }
    return _commit(
      state.copyWith(
        vouchers: [
          for (final v in state.vouchers) v.id == id ? v.markUsed() : v,
        ],
        history: [
          CoinHistoryEntry(
            id: 'used:$id',
            title: 'DEMO voucher used',
            coins: 0,
            date: _now,
            status: 'Used',
          ),
          ...state.history,
        ],
      ),
    );
  }
}
