import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/wallet_view_model.dart';
import 'wallet_ui.dart';

class WalletOverviewScreen extends ConsumerWidget {
  const WalletOverviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletViewModelProvider);
    final vm = ref.read(walletViewModelProvider.notifier);
    final latest = state.requests.lastOrNull;
    return WalletShell(
      title: 'My Wallet',
      subtitle: 'Manage your coins, vouchers and rewards',
      backRoute: '/profile',
      child: WalletFit(
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(
                    child: _Balance(
                      label: 'HP',
                      amount: state.hp,
                      color: walletPurple,
                      icon: Icons.bolt,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _Balance(
                      label: 'RC',
                      amount: state.rc,
                      color: walletGold,
                      icon: Icons.paid_outlined,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _Balance(
                      label: 'Lifetime HP',
                      amount: state.lifetimeHp,
                      color: walletGreen,
                      icon: Icons.stars_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Available ${walletNumber.format(state.availableRc)} RC  •  Reserved ${walletNumber.format(state.heldRc)} RC',
              key: const ValueKey('wallet-available-balance'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: walletGold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: WalletGlass(
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_outlined,
                      color: walletGold,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Level ${state.level}  •  Travel Explorer',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          LinearProgressIndicator(
                            value: state.progress,
                            minHeight: 7,
                            color: walletCyan,
                            backgroundColor: const Color(0xFF204754),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${walletNumber.format(state.hp % state.levelTargetHp)} / ${walletNumber.format(state.levelTargetHp)} XP',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFD0E9F0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _WalletAction(
              key: const ValueKey('wallet-redeem'),
              title: 'Redeem Rewards',
              subtitle: 'Use your available RC for demo vouchers',
              icon: Icons.card_giftcard,
              color: const Color(0xFFFF628F),
              onTap: () => context.push('/wallet/choose'),
            ),
            const SizedBox(height: 8),
            _WalletAction(
              key: const ValueKey('wallet-my-vouchers'),
              title: 'My Vouchers',
              subtitle: 'View your issued vouchers',
              icon: Icons.confirmation_number_outlined,
              color: walletCyan,
              onTap: () => context.push('/wallet/vouchers'),
            ),
            const SizedBox(height: 8),
            _WalletAction(
              key: const ValueKey('wallet-history'),
              title: 'Transaction History',
              subtitle: 'HP, RC and voucher activities',
              icon: Icons.history,
              color: walletGreen,
              onTap: () => context.push('/wallet/history'),
            ),
            const SizedBox(height: 8),
            _WalletAction(
              key: const ValueKey('wallet-rules'),
              title: 'Wallet Rules',
              subtitle: 'How balances and demo rewards work',
              icon: Icons.info_outline,
              color: walletCyan,
              onTap: () => context.push('/wallet/rules'),
            ),
            const SizedBox(height: 12),
            if (state.persistenceError != null)
              WalletButton(
                label: 'Retry local wallet save',
                icon: Icons.save_outlined,
                onPressed: vm.retryPersistence,
              )
            else if (latest != null)
              SizedBox(
                height: 40,
                child: InkWell(
                  key: const ValueKey('wallet-latest-request'),
                  onTap: () => context.push(vm.routeForRequest(latest)),
                  child: WalletGlass(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 19,
                          color: walletCyan,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Latest voucher request',
                            maxLines: 1,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        WalletPill(
                          latest.status.name[0].toUpperCase() +
                              latest.status.name.substring(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => WalletGlass(
    accent: color,
    padding: const EdgeInsets.all(9),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              walletNumber.format(amount),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: WalletGlass(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFCCE3EB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class WalletRulesScreen extends ConsumerWidget {
  const WalletRulesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WalletShell(
    title: 'Wallet Rules',
    child: WalletFit(
      height: 530,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WalletGlass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rule('Earn HP from local activities.'),
                _Rule('Only available RC can be reserved.'),
                _Rule('Approval deducts RC exactly once.'),
                _Rule('Pending holds RC; rejection releases it.'),
                _Rule('Demo codes are never redeemable.'),
                _Rule('Used and expired vouchers have no active QR.'),
                _Rule('The Used tab also contains expired vouchers.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (ref.watch(walletDemoToolsEnabledProvider)) ...[
            const Text(
              'Developer testing • local simulation only',
              textAlign: TextAlign.center,
              style: TextStyle(color: walletPurple, fontSize: 12),
            ),
            const SizedBox(height: 8),
            WalletButton(
              key: const ValueKey('wallet-open-demo-tools'),
              label: 'DEMO testing area',
              icon: Icons.science_outlined,
              outline: true,
              onPressed: () => context.push('/wallet/demo'),
            ),
          ],
          const Spacer(),
          WalletButton(
            label: 'Back to Wallet',
            onPressed: () => context.go('/wallet'),
          ),
        ],
      ),
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: walletCyan, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
