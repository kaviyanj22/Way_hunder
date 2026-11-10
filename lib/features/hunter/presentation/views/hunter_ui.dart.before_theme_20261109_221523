import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/scenic_background.dart';

const hunterGold = WayhunterPalette.hunterGold;
const hunterGreen = Color(0xFF22E878);

class HunterShell extends StatelessWidget {
  const HunterShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.backRoute = '/hunter',
    this.selectedIndex = 1,
    this.fillBody = false,
    this.compactHeader = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String backRoute;
  final int selectedIndex;

  /// Fill the viewport without scaling; only Hunter Home uses an inner list scroll.
  final bool fillBody;

  /// Smaller title area for Hunter Home so the search and map fit above the list.
  final bool compactHeader;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(primary: hunterGold),
    ),
    child: ScenicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Keep the Hunter Home layout fixed while the search keyboard opens.
        // Other form pages can adapt their scale to the keyboard viewport.
        resizeToAvoidBottomInset: !fillBody,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: NavigationBar(
                height: 65,
                backgroundColor: const Color(0xD906202A),
                indicatorColor: hunterGold.withValues(alpha: .25),
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => context.go(switch (index) {
                  0 => '/home',
                  1 => '/hunter',
                  2 => '/hunter/leaderboard',
                  _ => '/profile',
                }),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    label: 'Hunter',
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
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 51,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(backRoute);
                            }
                          },
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
                                'LOCATION HUNTER',
                                style: TextStyle(
                                  color: hunterGold,
                                  fontSize: 9,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: compactHeader
                        ? const EdgeInsets.fromLTRB(16, 0, 16, 3)
                        : const EdgeInsets.fromLTRB(17, 5, 17, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: compactHeader ? 17 : 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Color(0xFFD7E5E8),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      // No page-level scrolling. Non-Home screens scale down to
                      // fit available height. Hunter Home instead fills the
                      // viewport and scrolls only its discoveries list.
                      child: fillBody
                          ? child
                          : LayoutBuilder(
                              builder: (context, constraints) => ClipRect(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: child,
                                  ),
                                ),
                              ),
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
  );
}

class HunterPanel extends StatelessWidget {
  const HunterPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(13),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) =>
      GlassPanel(accent: hunterGold, padding: padding, child: child);
}

class HunterAction extends StatelessWidget {
  const HunterAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.green = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary, green;
  @override
  Widget build(BuildContext context) {
    final color = green ? hunterGreen : hunterGold;
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: secondary
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.arrow_forward, size: 18),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: color.withValues(alpha: .8)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.arrow_forward, size: 19),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: const Color(0xFF092332),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
    );
  }
}

class HunterSectionLabel extends StatelessWidget {
  const HunterSectionLabel(
    this.label, {
    super.key,
    this.icon = Icons.place_outlined,
  });
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Icon(icon, color: hunterGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

void hunterMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
  );
}

Future<void> hunterAlert(
  BuildContext context,
  String heading,
  String message,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(heading),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('OK'),
      ),
    ],
  ),
);
