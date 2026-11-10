import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/wayhunter_palette.dart';
import '../core/widgets/feature_scaffold.dart';
import '../core/widgets/neon_button.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/views/auth_screens.dart';
import '../features/home/presentation/views/feature_entry_screen.dart';
import '../features/home/presentation/views/home_screen.dart';
import '../features/traveller/presentation/providers/traveller_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authViewModelProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: refresh,
    redirect: (context, route) {
      final auth = ref.read(authViewModelProvider);
      final path = route.uri.path;
      if (!auth.initialized) return path == '/loading' ? null : '/loading';
      if (path == '/loading' || path == '/') {
        return auth.user == null
            ? '/sign-in'
            : auth.permissionsRequired
            ? '/permissions'
            : '/home';
      }
      final isAuth = {
        '/sign-in',
        '/register',
        '/otp',
        '/forgot-password',
        '/reset-password',
        '/offline',
        '/connection-restored',
        '/cancel-auth',
      }.contains(path);
      if (auth.user == null) {
        if (!isAuth) return '/sign-in';
        if (path == '/otp' && auth.flow == null) return '/sign-in';
        if (path == '/reset-password' &&
            (!auth.recoveryVerified || auth.flow != OtpPurpose.recovery)) {
          return '/forgot-password';
        }
        if ({
              '/offline',
              '/connection-restored',
              '/cancel-auth',
            }.contains(path) &&
            auth.pendingAction == null) {
          if (auth.recoveryVerified) return '/reset-password';
          if (auth.flow != null) return '/otp';
          return auth.pendingReturnRoute;
        }
        return null;
      }
      if (auth.permissionsRequired && path != '/permissions') {
        return '/permissions';
      }
      if (!auth.permissionsRequired && (isAuth || path == '/permissions')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/sign-in'),
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(path: '/offline', builder: (_, _) => const OfflineScreen()),
      GoRoute(
        path: '/connection-restored',
        builder: (_, _) => const ConnectionRestoredScreen(),
      ),
      GoRoute(
        path: '/cancel-auth',
        builder: (_, _) => const CancelAuthScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (_, _) => const PermissionsScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      ...travellerRoutes,
      GoRoute(
        path: '/hunter',
        builder: (_, _) =>
            const FeatureEntryScreen(module: WayhunterModule.hunter),
      ),
      GoRoute(
        path: '/game',
        builder: (_, _) =>
            const FeatureEntryScreen(module: WayhunterModule.game),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileEntryScreen()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletEntryScreen()),
      GoRoute(
        path: '/leaderboard',
        builder: (_, _) => const LeaderboardEntryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => FeatureScaffold(
      title: 'This trail is not available',
      subtitle: 'Return to a working screen.',
      child: NeonButton(
        label: 'Back to Home',
        onPressed: () => context.go('/home'),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
