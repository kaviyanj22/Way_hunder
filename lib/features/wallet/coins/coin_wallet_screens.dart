import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/widgets/scenic_background.dart';
import '../presentation/views/wallet_ui.dart';
import 'coin_wallet_models.dart';
import 'coin_wallet_view_model.dart';

final _num = NumberFormat.decimalPattern('en');
String _date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String _rs(int value) => 'Rs. ${_num.format(value)}';
String _coins(int value) => '${_num.format(value)} Coins';
String _status(CoinReviewStatus value) => switch (value) {
  CoinReviewStatus.pending => 'Pending',
  CoinReviewStatus.approved => 'Approved',
  CoinReviewStatus.rejected => 'Rejected',
};
String _requestPath(String id) =>
    '/wallet/request?id=${Uri.encodeQueryComponent(id)}';

class CoinWalletShell extends ConsumerWidget {
  const CoinWalletShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.backRoute = '/wallet',
  });
  final String title, backRoute;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(coinWalletProvider.select((s) => s.initialized));
    return ScenicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NavigationBar(
                height: 58,
                selectedIndex: 3,
                backgroundColor: const Color(0xDF06222F),
                indicatorColor: walletCyan.withValues(alpha: .21),
                onDestinationSelected: (i) => context.go(switch (i) {
                  0 => '/home',
                  1 => '/traveller',
                  2 => '/game',
                  _ => '/profile',
                }),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    label: 'Traveller',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sports_esports_outlined),
                    label: 'Game',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 47,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Go back',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(backRoute),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.terrain_outlined,
                                  color: walletCyan,
                                  size: 23,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'WAYHUNTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.notifications_none_outlined),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFD0E6EE),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 3, 13, 4),
                      child: loaded
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'LOCAL DEMO • NO REAL CASH OR VALID VOUCHER',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 8.5, color: Color(0xFFC3E5EB)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoinWalletHomeScreen extends ConsumerWidget {
  const CoinWalletHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(coinWalletProvider);
    return CoinWalletShell(
      title: 'My Wallet',
      backRoute: '/profile',
      subtitle: 'Manage your Coins, redeem rewards and vouchers',
      child: WalletFit(
        height: 575,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 143,
              child: WalletGlass(
                child: Row(
                  children: [
                    SizedBox(
                      width: 105,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 83,
                                color: walletGold,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Level',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${wallet.level}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Level Progress',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_num.format(wallet.levelCoins)} / 2,000 Coins',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: walletGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          LinearProgressIndicator(
                            value: wallet.levelProgress,
                            minHeight: 12,
                            color: walletCyan,
                            backgroundColor: const Color(0xFF355869),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Earn ${_num.format(wallet.nextLevelCoins)} more Coins for Level ${wallet.level + 1}',
                            maxLines: 2,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 91,
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Total Earned',
                      value: wallet.totalEarned,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(label: 'Available', value: wallet.balance),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Reserved: ${_coins(wallet.reserved)}  •  Redeemable: ${_coins(wallet.redeemable)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: walletGold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 95,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      'Redeem\nRewards',
                      Icons.card_giftcard_outlined,
                      () => context.push('/wallet/choose'),
                      key: const ValueKey('coins-redeem'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      'My\nVouchers',
                      Icons.confirmation_number_outlined,
                      () => context.push('/wallet/vouchers'),
                      key: const ValueKey('coins-vouchers'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 95,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      'Wallet\nRules',
                      Icons.menu_book_outlined,
                      () => context.push('/wallet/rules'),
                      key: const ValueKey('coins-rules'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      'Coins\nHistory',
                      Icons.history_rounded,
                      () => context.push('/wallet/history'),
                      key: const ValueKey('coins-history'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Expanded(
              child: WalletGlass(
                padding: const EdgeInsets.all(9),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: walletCyan, size: 29),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Earn Coins through approved place hunts, game creation and game completion.',
                        style: TextStyle(fontSize: 11),
                        maxLines: 3,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Redeem Requests',
                      onPressed: () => context.push('/wallet/requests'),
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        color: walletGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => WalletGlass(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: Row(
      children: [
        const Icon(Icons.toll_outlined, size: 31, color: walletGold),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _coins(value),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: walletGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.title, this.icon, this.onTap, {super.key});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: WalletGlass(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: walletCyan, size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    ),
  );
}

class CoinRedeemScreen extends ConsumerStatefulWidget {
  const CoinRedeemScreen({super.key});
  @override
  ConsumerState<CoinRedeemScreen> createState() => _CoinRedeemScreenState();
}

class _CoinRedeemScreenState extends ConsumerState<CoinRedeemScreen> {
  final _amount = TextEditingController(text: '10000');
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(coinWalletProvider);
    final n = int.tryParse(_amount.text) ?? 0;
    final valid = n >= 10000 && n % 10000 == 0 && n <= wallet.redeemable;
    return CoinWalletShell(
      title: 'Redeem Rewards',
      subtitle: '10,000 Coins = Rs.100',
      child: WalletFit(
        height: 625,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WalletGlass(
              accent: walletGold,
              child: Column(
                children: [
                  const Icon(Icons.toll, color: walletGold, size: 38),
                  const Text(
                    '10,000 Coins = Rs.100',
                    style: TextStyle(
                      color: walletGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            WalletGlass(
              child: Column(
                children: [
                  WalletLine('Total Earned', _coins(wallet.totalEarned)),
                  WalletLine('Available', _coins(wallet.balance)),
                  WalletLine(
                    'Reserved in Pending',
                    _coins(wallet.reserved),
                    color: walletGold,
                  ),
                  WalletLine(
                    'Redeemable',
                    _coins(wallet.redeemable),
                    color: walletCyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            WalletGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter Redeem Coins',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('coins-redeem-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '10000 / 20000 / 30000',
                      suffixIcon: Icon(Icons.toll, color: walletGold),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Equivalent Amount: ${_rs(n ~/ 100)}',
                    style: const TextStyle(
                      color: walletGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    wallet.error ??
                        'Minimum 10,000 Coins. Use multiples of 10,000.',
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            WalletButton(
              key: const ValueKey('coins-request-redemption'),
              label: 'Request Redemption',
              icon: Icons.send_outlined,
              onPressed: valid
                  ? () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm redemption request?'),
                          content: Text(
                            'Request ${_coins(n)} for ${_rs(n ~/ 100)}? '
                            'Coins will NOT be deducted before approval.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Submit Request'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final id = ref
                          .read(coinWalletProvider.notifier)
                          .requestRedemption(n);
                      if (id != null) context.go(_requestPath(id));
                    }
                  : null,
            ),
            const SizedBox(height: 9),
            WalletButton(
              label: 'Redeem Requests',
              outline: true,
              onPressed: () => context.push('/wallet/requests'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your request needs ADMIN approval. Pending balance stays visible; the amount is reserved against double requests.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinRequestsScreen extends ConsumerStatefulWidget {
  const CoinRequestsScreen({super.key});
  @override
  ConsumerState<CoinRequestsScreen> createState() => _CoinRequestsScreenState();
}

class _CoinRequestsScreenState extends ConsumerState<CoinRequestsScreen> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(coinWalletProvider);
    final items = wallet.requests.reversed
        .where((r) => filter == 'All' || _status(r.status) == filter)
        .toList();
    return CoinWalletShell(
      title: 'Redeem Requests',
      child: Column(
        children: [
          WalletTabs(
            labels: const ['All', 'Pending', 'Approved', 'Rejected'],
            selected: filter,
            onSelected: (next) => setState(() => filter = next),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No requests in this category.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final request = items[index];
                      return InkWell(
                        key: ValueKey('coins-request-${request.id}'),
                        onTap: () => context.push(_requestPath(request.id)),
                        child: WalletGlass(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.toll_outlined,
                                color: walletGold,
                                size: 31,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _coins(request.coins),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${_rs(request.valueLkr)} · ${_date(request.createdAt)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'ID: ${request.id.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              WalletPill(_status(request.status)),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          WalletButton(
            label: 'New Redemption Request',
            onPressed: () => context.push('/wallet/choose'),
          ),
        ],
      ),
    );
  }
}

class CoinRequestDetailScreen extends ConsumerWidget {
  const CoinRequestDetailScreen({super.key, required this.requestId});
  final String? requestId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(coinWalletProvider);
    final request = wallet.request(requestId ?? '');
    if (request == null)
      return CoinWalletShell(
        title: 'Request Not Found',
        child: WalletEmpty(
          message: 'The request could not be found.',
          label: 'Redeem Requests',
          onPressed: () => context.go('/wallet/requests'),
        ),
      );
    final state = _status(request.status);
    return CoinWalletShell(
      title: '$state Request',
      child: WalletFit(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WalletGlass(
              accent: request.status == CoinReviewStatus.approved
                  ? walletGreen
                  : request.status == CoinReviewStatus.pending
                  ? walletGold
                  : const Color(0xFFFF7079),
              child: Column(
                children: [
                  Icon(
                    request.status == CoinReviewStatus.approved
                        ? Icons.check_circle_outline
                        : request.status == CoinReviewStatus.pending
                        ? Icons.schedule_outlined
                        : Icons.cancel_outlined,
                    size: 54,
                    color: request.status == CoinReviewStatus.approved
                        ? walletGreen
                        : request.status == CoinReviewStatus.pending
                        ? walletGold
                        : const Color(0xFFFF7079),
                  ),
                  const SizedBox(height: 10),
                  WalletPill(state),
                  const SizedBox(height: 8),
                  Text(
                    _coins(request.coins),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                  Text(
                    _rs(request.valueLkr),
                    style: const TextStyle(color: walletGold, fontSize: 19),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            WalletGlass(
              child: Column(
                children: [
                  WalletLine(
                    'Request ID',
                    request.id.substring(0, 8).toUpperCase(),
                  ),
                  WalletLine('Submitted', _date(request.createdAt)),
                  WalletLine('Status', state),
                  if (request.reviewedAt != null)
                    WalletLine('Reviewed', _date(request.reviewedAt!)),
                  if (request.reason.isNotEmpty)
                    Text(request.reason, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Text(
              switch (request.status) {
                CoinReviewStatus.pending =>
                  'Pending ADMIN approval. Balance has NOT been deducted. '
                      'These Coins are temporarily reserved against another request.',
                CoinReviewStatus.approved => 'Approved in LOCAL DEMO. Coins deducted exactly once; demo voucher issued.',
                CoinReviewStatus.rejected => 'Request rejected. No Coins were deducted; reservation has been released.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 12),
            WalletButton(
              label: request.status == CoinReviewStatus.approved
                  ? 'View My Voucher'
                  : 'Back to Requests',
              onPressed: () => context.go(
                request.status == CoinReviewStatus.approved
                    ? '/wallet/vouchers'
                    : '/wallet/requests',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinVouchersScreen extends ConsumerStatefulWidget {
  const CoinVouchersScreen({super.key});
  @override
  ConsumerState<CoinVouchersScreen> createState() => _CoinVouchersScreenState();
}

class _CoinVouchersScreenState extends ConsumerState<CoinVouchersScreen> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(coinWalletProvider);
    final vouchers = wallet.vouchers.reversed
        .where(
          (v) =>
              filter != 'Pending' &&
              (filter == 'All' || v.activeAt(DateTime.now())),
        )
        .toList();
    final pending = wallet.requests.reversed
        .where(
          (r) => r.status == CoinReviewStatus.pending && filter != 'Approved',
        )
        .toList();
    return CoinWalletShell(
      title: 'My Vouchers',
      subtitle: 'Status, amount, voucher code and expiry',
      child: Column(
        children: [
          WalletTabs(
            labels: const ['All', 'Approved', 'Pending'],
            selected: filter,
            onSelected: (v) => setState(() => filter = v),
          ),
          const SizedBox(height: 11),
          Expanded(
            child: vouchers.isEmpty && pending.isEmpty
                ? const Center(child: Text('No vouchers in this category yet.'))
                : ListView(
                    children: [
                      for (final req in pending) ...[
                        InkWell(
                          onTap: () => context.push(_requestPath(req.id)),
                          child: WalletGlass(
                            child: Row(
                              children: [
                                const WalletBrand(),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thyaga Voucher · Pending',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Value: ${_rs(req.valueLkr)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Text(
                                        'Awaiting admin approval · no code yet',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const WalletPill('Pending'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      for (final voucher in vouchers) ...[
                        InkWell(
                          key: ValueKey('coins-voucher-${voucher.id}'),
                          onTap: () => context.push(
                            '/wallet/voucher?id=${Uri.encodeQueryComponent(voucher.id)}',
                          ),
                          child: WalletGlass(
                            child: Row(
                              children: [
                                const WalletBrand(),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thyaga Gift Voucher · DEMO',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Value: ${_rs(voucher.valueLkr)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Expiry: ${_date(voucher.expiresAt)}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        'Code: ${voucher.code}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                WalletPill(voucher.statusAt(DateTime.now())),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 9),
          WalletButton(
            label: 'Redeem Requests',
            outline: true,
            onPressed: () => context.push('/wallet/requests'),
          ),
        ],
      ),
    );
  }
}

class CoinVoucherDetailScreen extends ConsumerStatefulWidget {
  const CoinVoucherDetailScreen({super.key, required this.voucherId});
  final String? voucherId;
  @override
  ConsumerState<CoinVoucherDetailScreen> createState() =>
      _CoinVoucherDetailScreenState();
}

class _CoinVoucherDetailScreenState
    extends ConsumerState<CoinVoucherDetailScreen> {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted)
        setState(() {}); // Refresh code/QR as soon as voucher expires.
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coinWalletProvider);
    final voucher = state.voucher(widget.voucherId ?? '');
    if (voucher == null)
      return CoinWalletShell(
        title: 'Voucher Not Found',
        child: WalletEmpty(
          message: 'Voucher not available.',
          label: 'My Vouchers',
          onPressed: () => context.go('/wallet/vouchers'),
        ),
      );
    final now = ref.read(coinWalletClockProvider)();
    final active = voucher.activeAt(now);
    return CoinWalletShell(
      title: 'Voucher Details',
      subtitle: 'Local DEMO voucher · not valid at stores',
      child: LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletGlass(
                child: Column(
                  children: [
                    const WalletBrand(large: true),
                    const SizedBox(height: 9),
                    const Text(
                      'Thyaga Gift Voucher · DEMO',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _rs(voucher.valueLkr),
                      style: const TextStyle(
                        color: walletGold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    WalletPill(voucher.statusAt(now)),
                    const SizedBox(height: 9),
                    WalletLine('Issued', _date(voucher.issuedAt)),
                    WalletLine('Expiry', _date(voucher.expiresAt)),
                    WalletLine('Code', voucher.code),
                    const SizedBox(height: 12),
                    if (active) ...[
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(6),
                        child: QrImageView(data: voucher.qrPayload, size: 144),
                      ),
                      const SizedBox(height: 9),
                      WalletButton(
                        label: 'Copy DEMO Voucher Code',
                        icon: Icons.copy,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: voucher.code),
                          );
                          if (context.mounted)
                            walletFeedback(context, 'DEMO code copied');
                        },
                      ),
                    ] else
                      const Text(
                        'Voucher used or expired. QR is no longer displayed.',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is NOT a real Thyaga voucher. An administrator must assign genuine inventory through the future backend.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoinRulesScreen extends ConsumerWidget {
  const CoinRulesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CoinWalletShell(
      title: 'Wallet Rules',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                _RuleCard(Icons.toll_outlined, 'How to Earn Coins', [
                  'App download / first login (once): 100 Coins',
                  '1 approved Place Hunt: 200 Coins',
                  '1 admin-approved Game Creation: 100 Coins',
                  '1 admin-approved Game Completion: 100 Coins',
                  'No duplicate reward for the same event.',
                ]),
                SizedBox(height: 10),
                _RuleCard(Icons.currency_exchange, 'Coins Value', [
                  '10,000 Coins = Rs.100',
                  '20,000 Coins = Rs.200',
                  'The cash equivalent is for admin-approved vouchers in this demo.',
                ]),
                SizedBox(height: 10),
                _RuleCard(Icons.star_outlined, 'Level System', [
                  'Every 2,000 TOTAL EARNED Coins = next level.',
                  'Redeeming Coins does not reduce your level.',
                ]),
                SizedBox(height: 10),
                _RuleCard(Icons.card_giftcard, 'Redeem Rules', [
                  'Minimum 10,000 Coins; multiples of 10,000.',
                  'Requests go to admin for review.',
                  'PENDING: displayed Coins do not decrease.',
                  'Pending amount is reserved against duplicate spending.',
                  'APPROVED: Coins deducted exactly once, voucher issued.',
                  'REJECTED: no deduction, reserved Coins released.',
                  'Each voucher shows amount, status and expiry.',
                  'Codes/QR here are local DEMO only, not valid at stores.',
                ]),
              ],
            ),
          ),
          const SizedBox(height: 9),
          if (kDebugMode) ...[
            WalletButton(
              key: const ValueKey('coins-admin-demo'),
              label: 'Developer DEMO Approval Area',
              outline: true,
              icon: Icons.science_outlined,
              onPressed: () => context.push('/wallet/demo'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard(this.icon, this.title, this.rules);
  final IconData icon;
  final String title;
  final List<String> rules;
  @override
  Widget build(BuildContext context) => WalletGlass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: walletGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final r in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 6, color: walletCyan),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(r, style: const TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class CoinHistoryScreen extends ConsumerWidget {
  const CoinHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coinWalletProvider);
    final records = [...state.history]
      ..sort((a, b) => b.date.compareTo(a.date));
    return CoinWalletShell(
      title: 'Coins History',
      child: Column(
        children: [
          WalletGlass(
            child: Column(
              children: [
                WalletLine(
                  'Total Earned',
                  _coins(state.totalEarned),
                  color: walletGold,
                ),
                WalletLine('Available', _coins(state.balance)),
                WalletLine('Reserved', _coins(state.reserved)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('No Coin history yet.'))
                : ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final e = records[index];
                      return WalletGlass(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(
                              e.coins >= 0
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              color: e.coins >= 0 ? walletGreen : walletGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${_date(e.date)} · ${e.status}',
                                    style: const TextStyle(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${e.coins > 0 ? '+' : ''}${_num.format(e.coins)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: e.coins >= 0 ? walletGreen : walletGold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 9),
          WalletButton(
            label: 'Redeem Requests',
            outline: true,
            onPressed: () => context.push('/wallet/requests'),
          ),
        ],
      ),
    );
  }
}

/// ONLY an on-device developer simulation, never a real ADMIN approval endpoint.
class CoinWalletDemoScreen extends ConsumerWidget {
  const CoinWalletDemoScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(coinWalletDemoAdminEnabledProvider);
    if (!allowed)
      return CoinWalletShell(
        title: 'Demo Tools Disabled',
        child: const Center(child: Text('Only available in debug builds.')),
      );
    final state = ref.watch(coinWalletProvider);
    final vm = ref.read(coinWalletProvider.notifier);
    final earning = state.earnings
        .where((e) => e.status == CoinReviewStatus.pending)
        .toList();
    final requests = state.requests
        .where((e) => e.status == CoinReviewStatus.pending)
        .toList();
    return CoinWalletShell(
      title: 'DEMO Admin Review',
      subtitle:
          'Local simulated approvals only. No real admin notification is sent.',
      child: ListView(
        children: [
          WalletGlass(
            accent: walletGold,
            child: Column(
              children: [
                const Text(
                  'Local testing controls',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Production must use authenticated server-side approval, audit logs and genuine voucher inventory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 7),
                WalletButton(
                  label: 'Create pending demo Game reward (+100)',
                  onPressed: () {
                    vm.recordEarning(
                      sourceId:
                          'manual-game:${DateTime.now().microsecondsSinceEpoch}',
                      title: 'DEMO game completion awaiting admin',
                      coins: 100,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'PENDING COIN EARNINGS',
            style: TextStyle(color: walletGold, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (earning.isEmpty)
            const WalletGlass(child: Text('No pending earnings.')),
          for (final e in earning) ...[
            WalletGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    e.title,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _coins(e.coins),
                    style: const TextStyle(color: walletGold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: ValueKey('coins-earn-approve-${e.id}'),
                          onPressed: () => vm.reviewEarning(e.id, true),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => vm.reviewEarning(e.id, false),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          const Text(
            'PENDING VOUCHER REQUESTS',
            style: TextStyle(color: walletGold, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (requests.isEmpty)
            const WalletGlass(child: Text('No pending redemptions.')),
          for (final req in requests) ...[
            WalletGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_coins(req.coins)} → ${_rs(req.valueLkr)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Request: ${req.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: ValueKey('coins-redeem-approve-${req.id}'),
                          onPressed: () {
                            if (vm.reviewRedemption(req.id, true)) {
                              walletFeedback(
                                context,
                                'DEMO approved; voucher issued',
                              );
                            }
                          },
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          key: ValueKey('coins-redeem-reject-${req.id}'),
                          onPressed: () => vm.reviewRedemption(req.id, false),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
