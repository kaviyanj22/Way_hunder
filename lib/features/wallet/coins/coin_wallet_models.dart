/// Coins-only wallet models. All vouchers here are LOCAL DEMO records.
/// A real deployment must use authoritative backend balances and approval APIs.

enum CoinReviewStatus { pending, approved, rejected }

class CoinEarning {
  const CoinEarning({
    required this.id,
    required this.title,
    required this.coins,
    required this.status,
    required this.createdAt,
  });
  final String id, title;
  final int coins;
  final CoinReviewStatus status;
  final DateTime createdAt;

  CoinEarning reviewed(CoinReviewStatus next) => CoinEarning(
    id: id,
    title: title,
    coins: coins,
    status: next,
    createdAt: createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'coins': coins,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };
  factory CoinEarning.fromJson(Map<String, dynamic> x) => CoinEarning(
    id: x['id'] as String,
    title: x['title'] as String,
    coins: (x['coins'] as num).toInt(),
    status: CoinReviewStatus.values.byName(x['status'] as String),
    createdAt: DateTime.parse(x['createdAt'] as String),
  );
}

class CoinRedemptionRequest {
  const CoinRedemptionRequest({
    required this.id,
    required this.coins,
    required this.createdAt,
    this.status = CoinReviewStatus.pending,
    this.reviewedAt,
    this.voucherId,
    this.reason = '',
  });
  final String id, reason;
  final int coins;
  final DateTime createdAt;
  final CoinReviewStatus status;
  final DateTime? reviewedAt;
  final String? voucherId;
  int get valueLkr => coins ~/ 100; // 10,000 Coins = Rs.100

  CoinRedemptionRequest reviewed(
    CoinReviewStatus next,
    DateTime at, {
    String? voucherId,
    String reason = '',
  }) => CoinRedemptionRequest(
    id: id,
    coins: coins,
    createdAt: createdAt,
    status: next,
    reviewedAt: at,
    voucherId: voucherId,
    reason: reason,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'coins': coins,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'voucherId': voucherId,
    'reason': reason,
  };
  factory CoinRedemptionRequest.fromJson(Map<String, dynamic> x) =>
      CoinRedemptionRequest(
        id: x['id'] as String,
        coins: (x['coins'] as num).toInt(),
        createdAt: DateTime.parse(x['createdAt'] as String),
        status: CoinReviewStatus.values.byName(x['status'] as String),
        reviewedAt: DateTime.tryParse(x['reviewedAt'] as String? ?? ''),
        voucherId: x['voucherId'] as String?,
        reason: x['reason'] as String? ?? '',
      );
}

class CoinVoucher {
  const CoinVoucher({
    required this.id,
    required this.requestId,
    required this.code,
    required this.valueLkr,
    required this.issuedAt,
    required this.expiresAt,
    this.used = false,
  });
  final String id, requestId, code;
  final int valueLkr;
  final DateTime issuedAt, expiresAt;
  final bool used;
  bool activeAt(DateTime now) => !used && now.isBefore(expiresAt);
  String statusAt(DateTime now) => used
      ? 'Used'
      : now.isBefore(expiresAt)
      ? 'Approved'
      : 'Expired';
  String get qrPayload => 'WAYHUNTER-DEMO:NOT-REDEEMABLE:$id';
  CoinVoucher markUsed() => CoinVoucher(
    id: id,
    requestId: requestId,
    code: code,
    valueLkr: valueLkr,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    used: true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'code': code,
    'valueLkr': valueLkr,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'used': used,
  };
  factory CoinVoucher.fromJson(Map<String, dynamic> x) => CoinVoucher(
    id: x['id'] as String,
    requestId: x['requestId'] as String,
    code: x['code'] as String,
    valueLkr: (x['valueLkr'] as num).toInt(),
    issuedAt: DateTime.parse(x['issuedAt'] as String),
    expiresAt: DateTime.parse(x['expiresAt'] as String),
    used: x['used'] as bool? ?? false,
  );
}

class CoinHistoryEntry {
  const CoinHistoryEntry({
    required this.id,
    required this.title,
    required this.coins,
    required this.date,
    required this.status,
  });
  final String id, title, status;
  final int coins;
  final DateTime date;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'coins': coins,
    'date': date.toIso8601String(),
    'status': status,
  };
  factory CoinHistoryEntry.fromJson(Map<String, dynamic> x) => CoinHistoryEntry(
    id: x['id'] as String,
    title: x['title'] as String,
    coins: (x['coins'] as num).toInt(),
    date: DateTime.parse(x['date'] as String),
    status: x['status'] as String,
  );
}

class CoinWalletState {
  const CoinWalletState({
    required this.totalEarned,
    required this.balance,
    required this.earnings,
    required this.requests,
    required this.vouchers,
    required this.history,
    this.initialized = false,
    this.error,
  });
  final int totalEarned, balance;
  final List<CoinEarning> earnings;
  final List<CoinRedemptionRequest> requests;
  final List<CoinVoucher> vouchers;
  final List<CoinHistoryEntry> history;
  final bool initialized;
  final String? error;

  int get reserved => requests
      .where((r) => r.status == CoinReviewStatus.pending)
      .fold<int>(0, (total, r) => total + r.coins);
  int get redeemable => balance - reserved;
  int get level => totalEarned ~/ 2000 + 1;
  int get levelCoins => totalEarned % 2000;
  double get levelProgress => levelCoins / 2000;
  int get nextLevelCoins => 2000 - levelCoins;
  CoinRedemptionRequest? request(String id) {
    for (final r in requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  CoinVoucher? voucher(String id) {
    for (final v in vouchers) {
      if (v.id == id) return v;
    }
    return null;
  }

  String? get integrityError {
    if (totalEarned < 0 || balance < 0 || reserved > balance) {
      return 'Invalid Coin balance or pending reservation.';
    }
    if (requests.any((r) => r.coins < 10000 || r.coins % 10000 != 0)) {
      return 'Invalid redemption amount.';
    }
    if (vouchers.any((v) => v.valueLkr <= 0 || !v.code.startsWith('DEMO-'))) {
      return 'Invalid local voucher.';
    }
    if (earnings.map((e) => e.id).toSet().length != earnings.length ||
        requests.map((e) => e.id).toSet().length != requests.length ||
        vouchers.map((e) => e.id).toSet().length != vouchers.length ||
        history.map((e) => e.id).toSet().length != history.length) {
      return 'Duplicate Coin event.';
    }
    return null;
  }

  CoinWalletState copyWith({
    int? totalEarned,
    int? balance,
    List<CoinEarning>? earnings,
    List<CoinRedemptionRequest>? requests,
    List<CoinVoucher>? vouchers,
    List<CoinHistoryEntry>? history,
    bool? initialized,
    String? error,
  }) => CoinWalletState(
    totalEarned: totalEarned ?? this.totalEarned,
    balance: balance ?? this.balance,
    earnings: earnings ?? this.earnings,
    requests: requests ?? this.requests,
    vouchers: vouchers ?? this.vouchers,
    history: history ?? this.history,
    initialized: initialized ?? this.initialized,
    error: error,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'totalEarned': totalEarned,
    'balance': balance,
    'earnings': earnings.map((v) => v.toJson()).toList(),
    'requests': requests.map((v) => v.toJson()).toList(),
    'vouchers': vouchers.map((v) => v.toJson()).toList(),
    'history': history.map((v) => v.toJson()).toList(),
  };
  factory CoinWalletState.fromJson(Map<String, dynamic> x) => CoinWalletState(
    totalEarned: (x['totalEarned'] as num).toInt(),
    balance: (x['balance'] as num).toInt(),
    earnings: (x['earnings'] as List)
        .map((e) => CoinEarning.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    requests: (x['requests'] as List)
        .map(
          (e) => CoinRedemptionRequest.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(),
    vouchers: (x['vouchers'] as List)
        .map((e) => CoinVoucher.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    history: (x['history'] as List)
        .map(
          (e) => CoinHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    initialized: true,
  );
}
