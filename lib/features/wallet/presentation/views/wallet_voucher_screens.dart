import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../viewmodels/wallet_view_model.dart';
import 'wallet_redemption_screens.dart';
import 'wallet_ui.dart';

class WalletVouchersScreen extends ConsumerWidget {
  const WalletVouchersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletViewModelProvider);
    final now = ref.watch(walletClockProvider)();
    final vouchers = state.visibleVouchers(now);
    return WalletShell(
      title: 'My Vouchers',
      subtitle: 'Your issued demo vouchers',
      child: Column(
        children: [
          WalletTabs(
            labels: const ['Active', 'Used'],
            selected: state.usedTab ? 'Used' : 'Active',
            onSelected: (tab) => ref
                .read(walletViewModelProvider.notifier)
                .usedTab(tab == 'Used'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: vouchers.isEmpty
                ? WalletEmpty(
                    message: state.usedTab
                        ? 'No used or expired vouchers.'
                        : 'No active vouchers yet.',
                    label: 'Redeem Rewards',
                    onPressed: () => context.push('/wallet/choose'),
                  )
                : ListView.separated(
                    itemCount: vouchers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final voucher = vouchers[i];
                      final offer = state.offerById(voucher.offerId)!;
                      return InkWell(
                        key: ValueKey('wallet-voucher-${voucher.id}'),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          ref
                              .read(walletViewModelProvider.notifier)
                              .selectVoucher(voucher.id);
                          context.push(
                            walletRequestPath('/wallet/voucher', voucher.id),
                          );
                        },
                        child: WalletGlass(
                          child: Column(
                            children: [
                              WalletOfferSummary(
                                offer: offer,
                                trailing: WalletPill(voucher.statusAt(now)),
                              ),
                              const SizedBox(height: 9),
                              WalletLine(
                                'Issued on',
                                walletDate(voucher.issued),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: WalletLine(
                                      'Expires on',
                                      walletDate(voucher.expires),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class WalletVoucherDetailsScreen extends ConsumerStatefulWidget {
  const WalletVoucherDetailsScreen({super.key, this.voucherId});
  final String? voucherId;
  @override
  ConsumerState<WalletVoucherDetailsScreen> createState() =>
      _WalletVoucherDetailsScreenState();
}

class _WalletVoucherDetailsScreenState
    extends ConsumerState<WalletVoucherDetailsScreen>
    with WidgetsBindingObserver {
  bool _expanded = false;
  Timer? _expiry;
  String? _watchedExpiry;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _watchExpiry(DemoVoucher voucher, DateTime now) {
    if (!voucher.activeAt(now)) {
      _expiry?.cancel();
      _watchedExpiry = null;
      return;
    }
    final key = '${voucher.id}:${voucher.expires.toIso8601String()}';
    if (_watchedExpiry == key) return;
    _expiry?.cancel();
    _watchedExpiry = key;
    _expiry = Timer(voucher.expires.difference(now), () {
      if (mounted) setState(() => _watchedExpiry = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletViewModelProvider);
    final voucher = state.voucherById(
      widget.voucherId ?? state.selectedVoucherId,
    );
    if (voucher == null) {
      return const WalletMissingScreen(
        message: 'This demo voucher could not be found.',
      );
    }
    final offer = state.offerById(voucher.offerId)!;
    final now = ref.watch(walletClockProvider)();
    final active = voucher.activeAt(now);
    _watchExpiry(voucher, now);
    return WalletShell(
      title: 'Voucher Details',
      backRoute: '/wallet/vouchers',
      child: WalletFit(
        height: _expanded ? 720 : 630,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WalletGlass(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WalletOfferSummary(offer: offer),
                  const SizedBox(height: 6),
                  const Text(
                    'DEMO • NOT REDEEMABLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: walletCyan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: SizedBox(
                      height: 136,
                      width: 136,
                      child: active
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: walletCyan.withValues(alpha: .4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: QrImageView(
                                  key: const ValueKey('wallet-active-qr'),
                                  data: voucher.qrPayload,
                                  version: QrVersions.auto,
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  voucher.used
                                      ? Icons.check_circle_outline
                                      : Icons.event_busy,
                                  color: const Color(0xFFFF858B),
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${voucher.statusAt(now)} voucher',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFF858B),
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  'No active redemption QR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Voucher Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          voucher.code,
                          key: const ValueKey('wallet-voucher-code'),
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('wallet-copy-code'),
                        tooltip: 'Copy demo voucher code',
                        icon: const Icon(Icons.copy_outlined, size: 20),
                        onPressed: () async {
                          try {
                            await Clipboard.setData(
                              ClipboardData(text: voucher.code),
                            );
                            if (context.mounted) {
                              walletFeedback(
                                context,
                                'Demo voucher code copied.',
                              );
                            }
                          } on PlatformException {
                            if (context.mounted) {
                              walletFeedback(
                                context,
                                'Clipboard unavailable. Select the code to copy it.',
                              );
                            }
                          } on MissingPluginException {
                            if (context.mounted) {
                              walletFeedback(
                                context,
                                'Clipboard unavailable. Select the code to copy it.',
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  WalletLine('Partner', offer.partner),
                  WalletLine(
                    'Issued on',
                    walletDate(voucher.issued),
                    icon: Icons.calendar_month_outlined,
                  ),
                  WalletLine(
                    'Expires on',
                    walletDate(voucher.expires),
                    icon: Icons.event_outlined,
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Status', style: TextStyle(fontSize: 12)),
                      ),
                      WalletPill(voucher.statusAt(now)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              key: const ValueKey('wallet-how-to-use'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _expanded = !_expanded),
              child: WalletGlass(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline, color: walletCyan),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'How to Use',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                    if (_expanded)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'This is a non-redeemable demo voucher. Copy its code for the separate DEMO merchant test. No shop or partner accepts this QR. Used and expired vouchers stay here for your records.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD1E8F0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (ref.watch(walletDemoToolsEnabledProvider))
              WalletButton(
                key: const ValueKey('wallet-open-merchant'),
                label: 'DEMO merchant testing',
                outline: true,
                icon: Icons.science_outlined,
                onPressed: () => context.push(
                  '/wallet/demo?code=${Uri.encodeQueryComponent(voucher.code)}',
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class WalletHistoryScreen extends ConsumerWidget {
  const WalletHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletViewModelProvider);
    return WalletShell(
      title: 'Transaction History',
      subtitle: 'Your wallet activities and redemptions',
      child: Column(
        children: [
          WalletTabs(
            labels: const ['All', 'HP', 'RC', 'Vouchers'],
            selected: state.historyType,
            onSelected: ref.read(walletViewModelProvider.notifier).historyType,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.filteredEntries.isEmpty
                ? WalletEmpty(
                    message: 'No transactions in this category.',
                    label: state.historyType == 'All'
                        ? 'Back to Wallet'
                        : 'Show all transactions',
                    onPressed: () {
                      if (state.historyType == 'All') {
                        context.go('/wallet');
                      } else {
                        ref
                            .read(walletViewModelProvider.notifier)
                            .historyType('All');
                      }
                    },
                  )
                : ListView.separated(
                    itemCount: state.filteredEntries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final entry = state.filteredEntries[i];
                      final color = entry.type == 'HP'
                          ? walletPurple
                          : entry.type == 'RC'
                          ? walletGold
                          : walletCyan;
                      final unit = entry.type == 'HP' ? 'HP' : 'RC';
                      return InkWell(
                        key: ValueKey('wallet-transaction-${entry.id}'),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          if (entry.voucherId != null) {
                            context.push(
                              walletRequestPath(
                                '/wallet/voucher',
                                entry.voucherId!,
                              ),
                            );
                          } else if (state.requestById(entry.requestId)
                              case final request?) {
                            context.push(
                              ref
                                  .read(walletViewModelProvider.notifier)
                                  .routeForRequest(request),
                            );
                          } else {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(entry.title),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WalletLine('Type', entry.type),
                                    WalletLine(
                                      'Amount',
                                      '${entry.amount > 0 ? '+' : ''}${walletNumber.format(entry.amount)} $unit',
                                    ),
                                    WalletLine('Date', walletDate(entry.date)),
                                    WalletLine('Status', entry.status),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: WalletGlass(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                entry.type == 'HP'
                                    ? Icons.bolt
                                    : entry.type == 'RC'
                                    ? Icons.paid_outlined
                                    : Icons.card_giftcard_outlined,
                                color: color,
                                size: 28,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      walletDate(entry.date),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFBDDBE6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${entry.amount > 0 ? '+' : ''}${walletNumber.format(entry.amount)} $unit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: entry.amount < 0
                                          ? const Color(0xFFFF7C89)
                                          : color,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  WalletPill(entry.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
