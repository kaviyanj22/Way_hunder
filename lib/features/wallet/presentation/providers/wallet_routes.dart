import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../coins/coin_wallet_screens.dart';

/// Coins-only visual wallet routes. Legacy HP/RC files remain in the repository
/// for migration safety but are no longer used by user-facing wallet routes.
final walletRoutes = <RouteBase>[
  GoRoute(path: '/wallet', builder: (_, _) => const CoinWalletHomeScreen()),
  GoRoute(path: '/wallet/choose', builder: (_, _) => const CoinRedeemScreen()),
  GoRoute(path: '/wallet/confirm', builder: (_, _) => const CoinRedeemScreen()),
  GoRoute(
    path: '/wallet/requests',
    builder: (_, _) => const CoinRequestsScreen(),
  ),
  GoRoute(
    path: '/wallet/request',
    builder: (_, s) =>
        CoinRequestDetailScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/pending',
    builder: (_, s) =>
        CoinRequestDetailScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/approved',
    builder: (_, s) =>
        CoinRequestDetailScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/rejected',
    builder: (_, s) =>
        CoinRequestDetailScreen(requestId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/insufficient',
    builder: (_, _) => const CoinRedeemScreen(),
  ),
  GoRoute(
    path: '/wallet/vouchers',
    builder: (_, _) => const CoinVouchersScreen(),
  ),
  GoRoute(
    path: '/wallet/voucher',
    builder: (_, s) =>
        CoinVoucherDetailScreen(voucherId: s.uri.queryParameters['id']),
  ),
  GoRoute(
    path: '/wallet/history',
    builder: (_, _) => const CoinHistoryScreen(),
  ),
  GoRoute(path: '/wallet/rules', builder: (_, _) => const CoinRulesScreen()),
  GoRoute(
    path: '/wallet/demo',
    redirect: (_, _) => kDebugMode ? null : '/wallet',
    builder: (_, _) => const CoinWalletDemoScreen(),
  ),
];
