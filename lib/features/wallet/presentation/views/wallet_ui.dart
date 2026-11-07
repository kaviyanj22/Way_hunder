import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/scenic_background.dart';
import '../viewmodels/wallet_view_model.dart';

const walletCyan = Color(0xFF18E9F2);
const walletGold = Color(0xFFFFC64A);
const walletPurple = Color(0xFFB576FF);
const walletGreen = Color(0xFF37ED8A);
final walletNumber = NumberFormat.decimalPattern('en');
String walletDate(DateTime? date) =>
    date == null ? 'Not recorded' : DateFormat('dd MMM yyyy').format(date);
String walletRequestPath(String route, String id) =>
    '$route?id=${Uri.encodeQueryComponent(id)}';

class WalletShell extends ConsumerWidget {
  const WalletShell({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.backRoute = '/wallet',
  });
  final String? title, subtitle;
  final String backRoute;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(
      walletViewModelProvider.select((s) => s.initialized),
    );
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(backRoute);
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme
            .copyWith(primary: walletCyan),
      ),
      child: PopScope(
        canPop: context.canPop(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) context.go(backRoute);
        },
        child: ScenicBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            bottomNavigationBar: SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: NavigationBar(
                    height: 62,
                    selectedIndex: 1,
                    backgroundColor: const Color(0xC9062531),
                    indicatorColor: walletCyan.withValues(alpha: .25),
                    onDestinationSelected: (i) =>
                        context.go(i == 0 ? '/home' : '/wallet'),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        label: 'Wallet',
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
                        height: 48,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Go back',
                              onPressed: back,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.explore_outlined,
                                      color: walletCyan,
                                      size: 25,
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'WAYHUNTER',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: SizedBox(
                            height: 36,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                title!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 3,
                          ),
                          child: Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFD2E8F0),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: ready
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text(
                          'LOCAL DEMO • NOT REDEEMABLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFFB5DCE7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed pages scale as a unit on short phones; lists use Expanded instead.
class WalletFit extends StatelessWidget {
  const WalletFit({super.key, required this.child, this.height = 550});
  final Widget child;
  final double height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limits) => Align(
      alignment: Alignment.topCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: math.max(330, math.min(430, limits.maxWidth)),
          height: height,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: child,
          ),
        ),
      ),
    ),
  );
}

class WalletGlass extends StatelessWidget {
  const WalletGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.accent = walletCyan,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: .7)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xAD0F5668), Color(0xD0031823)],
      ),
      boxShadow: [
        BoxShadow(color: accent.withValues(alpha: .16), blurRadius: 9),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class WalletButton extends StatelessWidget {
  const WalletButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outline = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outline;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: outline
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF07ECF7),
                  Color(0xFF008A9D),
                  Color(0xFF00E7D5),
                ],
              ),
        boxShadow: outline
            ? null
            : [
                BoxShadow(
                  color: walletCyan.withValues(alpha: .3),
                  blurRadius: 10,
                ),
              ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: outline
              ? const Color(0x66031D2C)
              : Colors.transparent,
          disabledBackgroundColor: const Color(0xFF28414B),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(side: BorderSide(color: walletCyan)),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    ),
  );
}

class WalletTabs extends StatelessWidget {
  const WalletTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Material(
              color: selected == labels[i]
                  ? walletCyan
                  : const Color(0xAA04212B),
              shape: const StadiumBorder(side: BorderSide(color: walletCyan)),
              child: InkWell(
                key: ValueKey('wallet-tab-${labels[i]}'),
                customBorder: const StadiumBorder(),
                onTap: () => onSelected(labels[i]),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected == labels[i]
                              ? const Color(0xFF002830)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class WalletPill extends StatelessWidget {
  const WalletPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Approved' || 'Active' || 'Completed' => walletGreen,
      'Pending' => walletGold,
      'Rejected' || 'Expired' => const Color(0xFFFF767D),
      _ => const Color(0xFFA3B8C1),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class WalletBrand extends StatelessWidget {
  const WalletBrand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
    width: large ? 100 : 66,
    height: large ? 68 : 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF245C), Color(0xFFCB23B0), Color(0xFF7112C6)],
      ),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'thyaga',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        Text('DEMO', style: TextStyle(fontSize: 8, color: Colors.white)),
      ],
    ),
  );
}

class WalletOfferSummary extends StatelessWidget {
  const WalletOfferSummary({super.key, required this.offer, this.trailing});
  final VoucherOffer offer;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const WalletBrand(),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              offer.name,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Rs. ${walletNumber.format(offer.value)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class WalletLine extends StatelessWidget {
  const WalletLine(
    this.label,
    this.value, {
    super.key,
    this.color = Colors.white,
    this.icon,
  });
  final String label, value;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFD8E8F0)),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class WalletEmpty extends StatelessWidget {
  const WalletEmpty({
    super.key,
    required this.message,
    required this.label,
    required this.onPressed,
    this.icon = Icons.confirmation_number_outlined,
  });
  final String message, label;
  final VoidCallback onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: walletCyan),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 16),
        WalletButton(label: label, onPressed: onPressed),
      ],
    ),
  );
}

void walletFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
