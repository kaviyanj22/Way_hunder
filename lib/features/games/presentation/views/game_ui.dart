import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/scenic_background.dart';

const gamePurple = WayhunterPalette.gamePurple;
const gameGreen = Color(0xFF35E978);
const gameCyan = Color(0xFF27D9F2);

/// Fixed footer and brand header for all Game screens. Only detailed flows
/// scroll; the Game Zone landing content fits the available viewport.
class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.fixed = false,
    this.backRoute = '/game',
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool fixed;
  final String backRoute;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(primary: gamePurple),
    ),
    child: ScenicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NavigationBar(
                backgroundColor: const Color(0xE5052131),
                indicatorColor: gameGreen.withValues(alpha: .27),
                height: 65,
                selectedIndex: 1,
                onDestinationSelected: (i) => context.go(switch (i) {
                  0 => '/home',
                  1 => '/game',
                  2 => '/game/leaderboard',
                  _ => '/profile',
                }),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sports_esports_outlined),
                    label: 'Game',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    label: 'Leaderboard',
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 51,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Go back',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(backRoute),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'WAYHUNTER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'GAME ZONE',
                                style: TextStyle(
                                  color: gamePurple,
                                  letterSpacing: 2,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                        IconButton(
                          tooltip: 'Your profile',
                          onPressed: () => context.push('/profile'),
                          icon: const Icon(Icons.account_circle_outlined),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Color(0xFFD1DAEB),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: fixed
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: child,
                          )
                        : SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(13, 0, 13, 20),
                            child: child,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.color = gameCyan,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: color.withValues(alpha: .75)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xE008394D),
          const Color(0xE5071020).withValues(alpha: .91),
        ],
      ),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .13), blurRadius: 9),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class GameAction extends StatelessWidget {
  const GameAction({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.color = gamePurple,
    this.outline = false,
  });
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final bool outline;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 19),
      label: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: outline ? const Color(0xE008273A) : color,
        foregroundColor: outline ? Colors.white : const Color(0xFF061222),
        minimumSize: const Size(0, 48),
        side: outline ? BorderSide(color: color) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

void showGameMessage(BuildContext context, String text) {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Wayhunter Game'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class GamePageSection extends StatelessWidget {
  const GamePageSection({
    super.key,
    required this.title,
    required this.child,
    this.color = gameCyan,
  });
  final String title;
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GamePanel(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}
