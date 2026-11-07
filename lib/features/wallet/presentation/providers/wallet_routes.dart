import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../views/wallet_demo_screen.dart';
import '../views/wallet_overview_screen.dart';
import '../views/wallet_redemption_screens.dart';
import '../views/wallet_voucher_screens.dart';

final walletRoutes = <RouteBase>[
  GoRoute(path: '/wallet', builder: (_, _) => const WalletOverviewScreen()),
  GoRoute(
    path: '/wallet/choose',
    builder: (_, _) => const WalletRewardsScreen(),
  ),
  GoRoute(
    path: '/wallet/confirm',
    builder: (_, s) => WalletConfirmScreen(
      offerId: s.uri.queryParameters['offer'],
      intentId: s.uri.queryParameters['intent'],
    ),
  ),
  GoRoute(
    path: '/wallet/pending',
    builder: (_, s) =>
        WalletPendingScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/approved',
    builder: (_, s) =>
        WalletApprovedScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/vouchers',
    builder: (_, _) => const WalletVouchersScreen(),
  ),
  GoRoute(
    path: '/wallet/voucher',
    builder: (_, s) =>
        WalletVoucherDetailsScreen(voucherId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/history',
    builder: (_, _) => const WalletHistoryScreen(),
  ),
  GoRoute(path: '/wallet/rules', builder: (_, _) => const WalletRulesScreen()),
  GoRoute(
    path: '/wallet/rejected',
    builder: (_, s) =>
        WalletRejectedScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/insufficient',
    builder: (_, s) =>
        WalletInsufficientScreen(offerId: s.uri.queryParameters['offer']),
  ),
  GoRoute(
    path: '/wallet/demo',
    redirect: (_, _) => kDebugMode ? null : '/wallet',
    builder: (_, s) => WalletDemoScreen(code: s.uri.queryParameters['code']),
  ),
];
