import 'dart:convert';

import '../../../core/mock/mock_data.dart';
import '../../../core/storage/local_demo_storage.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_repository.dart';

class MockWalletRepository implements WalletRepository {
  MockWalletRepository(this.storage);
  final LocalDemoStorage storage;
  @override
  WalletState initial(AuthUser? user) {
    final seed = user == null || user.id == MockData.currentUser['id'];
    return WalletState(
      hp: user?.hp ?? MockData.currentUser['hp'] as int,
      rc: user?.rc ?? MockData.currentUser['rc'] as int,
      lifetimeHp: seed ? MockData.currentUser['lifetimeHp'] as int : user.hp,
      baseLevel: user?.level ?? MockData.currentUser['level'] as int,
      baseHp: user?.hp ?? MockData.currentUser['hp'] as int,
      levelTargetHp: MockData.walletLevelTargetHp,
      voucherValidityDays: MockData.walletVoucherValidityDays,
      stock: MockData.demoVoucherInventory
          .map(
            (s) => DemoVoucherStock(
              id: s['id']!,
              offerId: s['offerId']!,
              code: s['code']!,
            ),
          )
          .toList(growable: false),
      offers: MockData.rewards.map(VoucherOffer.fromMap).toList(),
      requests: seed
          ? MockData.sampleVoucherRequests
                .map(
                  (m) => VoucherRequest(
                    id: m['id'] as String,
                    offerId: m['rewardId'] as String,
                    cost: m['costRc'] as int,
                    status: RequestStatus.values.byName(
                      (m['status']! as String).toLowerCase(),
                    ),
                    created: DateTime.tryParse(m['createdAt'] as String? ?? ''),
                  ),
                )
                .toList()
          : [],
      vouchers: seed
          ? MockData.sampleVouchers
                .map(
                  (m) => DemoVoucher(
                    id: m['id'] as String,
                    offerId: m['rewardId'] as String,
                    code: m['code'] as String,
                    issued: DateTime.parse(m['issueDate'] as String),
                    expires: DateTime.parse(m['expiryDate'] as String),
                    used: m['status'] == 'Used',
                  ),
                )
                .toList()
          : [],
      entries: seed
          ? MockData.transactionHistory
                .map(
                  (m) => WalletEntry(
                    id: m['id'] as String,
                    type: m['type'] as String,
                    title: m['title'] as String,
                    amount: m['amount'] as int,
                    status: m['status'] as String,
                    date: DateTime.parse(m['createdAt'] as String),
                    requestId: m['requestId'] as String?,
                    voucherId: m['voucherId'] as String?,
                  ),
                )
                .toList()
          : [],
    );
  }

  @override
  Future<WalletState?> restore(String userId, WalletState seed) async {
    try {
      final text = await storage.readString('wallet:$userId');
      if (text == null) return null;
      final m = jsonDecode(text) as Map<String, dynamic>;
      final restored = seed.copyWith(
        hp: m['hp'],
        rc: m['rc'],
        lifetimeHp: m['lifetimeHp'],
        requests: (m['requests'] as List)
            .map((v) => VoucherRequest.fromMap(Map<String, dynamic>.from(v)))
            .toList(),
        vouchers: (m['vouchers'] as List)
            .map((v) => DemoVoucher.fromMap(Map<String, dynamic>.from(v)))
            .toList(),
        entries: (m['entries'] as List)
            .map((v) => WalletEntry.fromMap(Map<String, dynamic>.from(v)))
            .toList(),
        credited: Set<String>.from(m['credited']),
        baseHp: m['baseHp'] as int? ?? seed.baseHp,
        baseLevel: m['baseLevel'] as int? ?? seed.baseLevel,
      );
      return restored.integrityError == null ? restored : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String userId, WalletState state) => storage.writeString(
    'wallet:$userId',
    jsonEncode({
      'hp': state.hp,
      'rc': state.rc,
      'lifetimeHp': state.lifetimeHp,
      'baseHp': state.baseHp,
      'baseLevel': state.baseLevel,
      'requests': state.requests.map((r) => r.toMap()).toList(),
      'vouchers': state.vouchers.map((v) => v.toMap()).toList(),
      'entries': state.entries.map((e) => e.toMap()).toList(),
      'credited': state.credited.toList(),
    }),
  );
}
