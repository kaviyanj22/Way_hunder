class VoucherOffer {
  const VoucherOffer({
    required this.id,
    required this.name,
    required this.partner,
    required this.value,
    required this.cost,
    required this.category,
  });
  final String id, name, partner, category;
  final int value, cost;
  factory VoucherOffer.fromMap(Map<String, Object?> m) => VoucherOffer(
    id: m['id'] as String,
    name: m['name'] as String,
    partner: m['partner'] as String,
    value: m['valueLkr'] as int,
    cost: m['costRc'] as int,
    category: m['category'] as String,
  );
}

enum RequestStatus { pending, approved, rejected }

class DemoVoucherStock {
  const DemoVoucherStock({
    required this.id,
    required this.offerId,
    required this.code,
  });
  final String id, offerId, code;
}

class VoucherRequest {
  const VoucherRequest({
    required this.id,
    required this.offerId,
    required this.cost,
    this.status = RequestStatus.pending,
    this.reason = '',
    this.intentId,
    this.created,
    this.decidedAt,
    this.voucherId,
  });
  final String id, offerId, reason;
  final int cost;
  final RequestStatus status;
  final String? intentId, voucherId;
  final DateTime? created, decidedAt;
  Map<String, Object?> toMap() => {
    'id': id,
    'offerId': offerId,
    'cost': cost,
    'status': status.name,
    'reason': reason,
    'intentId': intentId,
    'created': created?.toIso8601String(),
    'decidedAt': decidedAt?.toIso8601String(),
    'voucherId': voucherId,
  };
  factory VoucherRequest.fromMap(Map<String, dynamic> m) => VoucherRequest(
    id: m['id'],
    offerId: m['offerId'],
    cost: m['cost'],
    status: RequestStatus.values.byName(m['status']),
    reason: m['reason'] ?? '',
    intentId: m['intentId'],
    created: DateTime.tryParse(m['created'] as String? ?? ''),
    decidedAt: DateTime.tryParse(m['decidedAt'] as String? ?? ''),
    voucherId: m['voucherId'],
  );
  VoucherRequest decided(
    RequestStatus value,
    String reason, {
    DateTime? at,
    String? voucherId,
  }) => VoucherRequest(
    id: id,
    offerId: offerId,
    cost: cost,
    status: value,
    reason: reason,
    intentId: intentId,
    created: created,
    decidedAt: at,
    voucherId: voucherId ?? this.voucherId,
  );
}

class DemoVoucher {
  const DemoVoucher({
    required this.id,
    required this.offerId,
    required this.code,
    required this.issued,
    required this.expires,
    this.used = false,
    this.stockId,
    this.requestId,
  });
  final String id, offerId, code;
  final DateTime issued, expires;
  final bool used;
  final String? stockId, requestId;
  bool get expired => !DateTime.now().isBefore(expires);
  bool get active => !used && !expired;
  bool activeAt(DateTime now) => !used && now.isBefore(expires);
  String statusAt(DateTime now) => used
      ? 'Used'
      : now.isBefore(expires)
      ? 'Active'
      : 'Expired';
  String get qrPayload => 'WAYHUNTER-DEMO:NOT-REDEEMABLE:$id';
  DemoVoucher markUsed() => DemoVoucher(
    id: id,
    offerId: offerId,
    code: code,
    issued: issued,
    expires: expires,
    used: true,
    stockId: stockId,
    requestId: requestId,
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'offerId': offerId,
    'code': code,
    'issued': issued.toIso8601String(),
    'expires': expires.toIso8601String(),
    'used': used,
    'stockId': stockId,
    'requestId': requestId,
  };
  factory DemoVoucher.fromMap(Map<String, dynamic> m) => DemoVoucher(
    id: m['id'],
    offerId: m['offerId'],
    code: m['code'],
    issued: DateTime.parse(m['issued']),
    expires: DateTime.parse(m['expires']),
    used: m['used'],
    stockId: m['stockId'],
    requestId: m['requestId'],
  );
}

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.status,
    required this.date,
    this.requestId,
    this.voucherId,
  });
  final String id, type, title, status;
  final int amount;
  final DateTime date;
  final String? requestId, voucherId;
  Map<String, Object?> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'amount': amount,
    'status': status,
    'date': date.toIso8601String(),
    'requestId': requestId,
    'voucherId': voucherId,
  };
  factory WalletEntry.fromMap(Map<String, dynamic> m) => WalletEntry(
    id: m['id'],
    type: m['type'],
    title: m['title'],
    amount: m['amount'],
    status: m['status'],
    date: DateTime.parse(m['date']),
    requestId: m['requestId'],
    voucherId: m['voucherId'],
  );
}

class WalletState {
  const WalletState({
    required this.hp,
    required this.rc,
    required this.lifetimeHp,
    required this.offers,
    required this.requests,
    required this.vouchers,
    required this.entries,
    this.credited = const {},
    this.selectedOfferId,
    this.selectedRequestId,
    this.selectedVoucherId,
    this.category = 'All',
    this.historyType = 'All',
    this.usedTab = false,
    this.error,
    this.stock = const [],
    this.initialized = false,
    this.intentId,
    this.persistenceError,
    this.baseLevel = 1,
    this.baseHp = 0,
    this.levelTargetHp = 5000,
    this.voucherValidityDays = 180,
  });
  final int hp, rc, lifetimeHp;
  final List<VoucherOffer> offers;
  final List<VoucherRequest> requests;
  final List<DemoVoucher> vouchers;
  final List<WalletEntry> entries;
  final Set<String> credited;
  final String? selectedOfferId, selectedRequestId, selectedVoucherId, error;
  final String category, historyType;
  final bool usedTab;
  final List<DemoVoucherStock> stock;
  final bool initialized;
  final String? intentId, persistenceError;
  final int baseLevel, baseHp, levelTargetHp, voucherValidityDays;
  int get level => baseLevel + hp ~/ levelTargetHp - baseHp ~/ levelTargetHp;
  double get progress => (hp % levelTargetHp) / levelTargetHp;
  int get heldRc => requests
      .where((r) => r.status == RequestStatus.pending)
      .fold(0, (sum, r) => sum + r.cost);
  int get availableRc => rc - heldRc;
  VoucherOffer? offerById(String? id) =>
      offers.where((o) => o.id == id).firstOrNull;
  VoucherRequest? requestById(String? id) =>
      requests.where((r) => r.id == id).firstOrNull;
  DemoVoucher? voucherById(String? id) =>
      vouchers.where((v) => v.id == id).firstOrNull;
  List<DemoVoucher> visibleVouchers(DateTime now) => vouchers
      .where((v) => usedTab ? !v.activeAt(now) : v.activeAt(now))
      .toList();
  DemoVoucherStock? availableStock(String offerId) => stock
      .where(
        (s) => s.offerId == offerId && !vouchers.any((v) => v.stockId == s.id),
      )
      .firstOrNull;
  String? get integrityError {
    if (levelTargetHp <= 0 || baseLevel < 1) return 'Invalid wallet level.';
    if (hp < 0 || rc < 0 || lifetimeHp < hp || heldRc > rc) {
      return 'Invalid wallet balances.';
    }
    if (requests.any((r) => r.cost <= 0 || offerById(r.offerId) == null)) {
      return 'Invalid voucher request.';
    }
    if (vouchers.any(
      (v) => offerById(v.offerId) == null || !v.code.startsWith('DEMO'),
    )) {
      return 'Invalid demo voucher.';
    }
    if (requests.map((r) => r.id).toSet().length != requests.length ||
        vouchers.map((v) => v.id).toSet().length != vouchers.length ||
        vouchers.map((v) => v.code).toSet().length != vouchers.length ||
        entries.map((e) => e.id).toSet().length != entries.length) {
      return 'Duplicate wallet records.';
    }
    final assigned = vouchers
        .map((v) => v.stockId)
        .whereType<String>()
        .toList();
    if (assigned.toSet().length != assigned.length) {
      return 'Duplicate voucher assignment.';
    }
    return null;
  }

  VoucherOffer? get selectedOffer =>
      offers.where((o) => o.id == selectedOfferId).firstOrNull;
  VoucherRequest? get selectedRequest =>
      requests.where((r) => r.id == selectedRequestId).firstOrNull;
  DemoVoucher? get selectedVoucher =>
      vouchers.where((v) => v.id == selectedVoucherId).firstOrNull;
  List<VoucherOffer> get filteredOffers =>
      offers.where((o) => category == 'All' || o.category == category).toList();
  List<WalletEntry> get filteredEntries =>
      entries
          .where(
            (e) =>
                historyType == 'All' ||
                (historyType == 'Vouchers'
                    ? e.type == 'Voucher'
                    : e.type == historyType),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  WalletState copyWith({
    int? hp,
    int? rc,
    int? lifetimeHp,
    List<VoucherRequest>? requests,
    List<DemoVoucher>? vouchers,
    List<WalletEntry>? entries,
    Set<String>? credited,
    String? selectedOfferId,
    String? selectedRequestId,
    String? selectedVoucherId,
    String? category,
    String? historyType,
    bool? usedTab,
    String? error,
    bool? initialized,
    String? intentId,
    String? persistenceError,
    bool clearPersistenceError = false,
    bool clearRequest = false,
    bool clearVoucher = false,
    int? baseLevel,
    int? baseHp,
  }) => WalletState(
    hp: hp ?? this.hp,
    rc: rc ?? this.rc,
    lifetimeHp: lifetimeHp ?? this.lifetimeHp,
    offers: offers,
    requests: requests ?? this.requests,
    vouchers: vouchers ?? this.vouchers,
    entries: entries ?? this.entries,
    credited: credited ?? this.credited,
    selectedOfferId: selectedOfferId ?? this.selectedOfferId,
    selectedRequestId: clearRequest
        ? null
        : selectedRequestId ?? this.selectedRequestId,
    selectedVoucherId: clearVoucher
        ? null
        : selectedVoucherId ?? this.selectedVoucherId,
    category: category ?? this.category,
    historyType: historyType ?? this.historyType,
    usedTab: usedTab ?? this.usedTab,
    error: error,
    stock: stock,
    initialized: initialized ?? this.initialized,
    intentId: intentId ?? this.intentId,
    persistenceError: clearPersistenceError
        ? null
        : persistenceError ?? this.persistenceError,
    baseLevel: baseLevel ?? this.baseLevel,
    baseHp: baseHp ?? this.baseHp,
    levelTargetHp: levelTargetHp,
    voucherValidityDays: voucherValidityDays,
  );
}
