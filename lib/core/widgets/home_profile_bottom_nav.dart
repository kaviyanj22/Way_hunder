import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Two-destination navigation used ONLY on Home and Profile.
/// Other module screens retain their own existing navigation.
class HomeProfileBottomNav extends StatelessWidget {
  const HomeProfileBottomNav({super.key, this.isProfile = false});

  final bool isProfile;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    maintainBottomViewPadding: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: NavigationBar(
          height: 66,
          backgroundColor: const Color(0xD9001C2D),
          indicatorColor: const Color(0xFF00DDED).withValues(alpha: .26),
          selectedIndex: isProfile ? 1 : 0,
          onDestinationSelected: (index) =>
              context.go(index == 0 ? '/home' : '/profile'),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
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
