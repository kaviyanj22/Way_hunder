import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wayhunter_palette.dart';
import 'scenic_background.dart';

class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.module = WayhunterModule.common,
    this.backRoute = '/home',
    this.showBack = true,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final WayhunterModule module;
  final String backRoute;
  final bool showBack;
  @override
  Widget build(BuildContext context) {
    final route = switch (module) {
      WayhunterModule.traveller => '/traveller',
      WayhunterModule.hunter => '/hunter',
      WayhunterModule.game => '/game',
      _ => '/profile',
    };
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
            .copyWith(primary: module.accent),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: NavigationBar(
                    height: 68,
                    backgroundColor: const Color(0xD8071D2A),
                    indicatorColor: module.accent.withValues(alpha: .22),
                    selectedIndex: 1,
                    onDestinationSelected: (index) =>
                        context.go(switch (index) {
                          0 => '/home',
                          1 => route,
                          2 => '/leaderboard',
                          _ => '/profile',
                        }),
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(switch (module) {
                          WayhunterModule.traveller => Icons.hiking,
                          WayhunterModule.hunter => Icons.explore_outlined,
                          WayhunterModule.game => Icons.sports_esports_outlined,
                          _ => Icons.person_outline,
                        }),
                        label: switch (module) {
                          WayhunterModule.traveller => 'Traveller',
                          WayhunterModule.hunter => 'Hunter',
                          WayhunterModule.game => 'Game',
                          _ => 'Profile',
                        },
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.emoji_events_outlined),
                        label: 'Leaderboard',
                      ),
                      const NavigationDestination(
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
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (showBack)
                              IconButton(
                                tooltip: 'Go back',
                                onPressed: back,
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            const Expanded(
                              child: Text(
                                'WAYHUNTER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Profile',
                              onPressed: () => context.push('/profile'),
                              icon: const Icon(Icons.account_circle_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 18),
                        child,
                      ],
                    ),
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
