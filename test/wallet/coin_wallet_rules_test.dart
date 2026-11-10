import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/features/wallet/coins/coin_wallet_models.dart';

void main() {
  final now = DateTime(2026, 11, 9);
  CoinWalletState sample({int total = 12800, int balance = 12800,
      List<CoinRedemptionRequest> requests = const []}) => CoinWalletState(
    totalEarned: total, balance: balance, earnings: const [],
    requests: requests, vouchers: const [], history: const [], initialized: true,
  );

  test('every 2000 lifetime-earned coins advances level; redemption does not', () {
    final a = sample(total: 1200, balance: 1200);
    expect(a.level, 1);
    expect(a.levelCoins, 1200);
    expect(a.levelProgress, .6);
    final b = sample(total: 12800, balance: 2800);
    expect(b.level, 7);
    expect(b.levelCoins, 800);
  });

  test('pending keeps visible balance and reserves redemption amount', () {
    final pending = CoinRedemptionRequest(id: 'request-a', coins: 10000,
      createdAt: now);
    final state = sample(requests: [pending]);
    expect(state.balance, 12800);
    expect(state.reserved, 10000);
    expect(state.redeemable, 2800);
    expect(state.integrityError, isNull);
    final approved = state.copyWith(balance: 2800, requests: [
      pending.reviewed(CoinReviewStatus.approved, now, voucherId: 'voucher-a'),
    ]);
    expect(approved.reserved, 0);
    expect(approved.redeemable, 2800);
    expect(approved.totalEarned, 12800);
  });

  test('rejection releases reserved coins without deduction', () {
    final pending = CoinRedemptionRequest(id: 'request-a', coins: 10000,
      createdAt: now);
    final rejected = sample(requests: [
      pending.reviewed(CoinReviewStatus.rejected, now),
    ]);
    expect(rejected.balance, 12800);
    expect(rejected.reserved, 0);
    expect(rejected.redeemable, 12800);
  });

  test('voucher only active before expiry and not after use', () {
    final voucher = CoinVoucher(id: 'voucher-a', requestId: 'request-a',
      code: 'DEMO-WH-12345678', valueLkr: 100,
      issuedAt: now, expiresAt: now.add(const Duration(days: 180)));
    expect(voucher.activeAt(now), isTrue);
    expect(voucher.activeAt(voucher.expiresAt), isFalse);
    expect(voucher.markUsed().activeAt(now), isFalse);
    expect(voucher.qrPayload, contains('NOT-REDEEMABLE'));
  });

  test('old state JSON round trip preserves redemption status', () {
    final pending = CoinRedemptionRequest(id: 'request-a', coins: 10000,
      createdAt: now);
    final raw = sample(requests: [pending]).toJson();
    final restored = CoinWalletState.fromJson(raw);
    expect(restored.balance, 12800);
    expect(restored.requests.single.status, CoinReviewStatus.pending);
    expect(restored.integrityError, isNull);
  });
}
