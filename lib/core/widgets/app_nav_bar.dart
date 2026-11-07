import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, this.selectedIndex = 0});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: NavigationBar(
          height: 70,
          backgroundColor: const Color(0xDA061C2A),
          indicatorColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: .22),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => context.go(switch (index) {
            0 => '/home',
            1 => '/hunter',
            2 => '/leaderboard',
            _ => '/profile',
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Hunter',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
}
