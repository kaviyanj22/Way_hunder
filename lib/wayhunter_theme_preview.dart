import 'package:flutter/material.dart';

import 'core/theme/wayhunter_module_theme.dart';
import 'core/widgets/wayhunter_bubble_bottom_nav.dart';
import 'core/widgets/wayhunter_glass_ui.dart';

/// Run independently of the production app:
/// flutter run -t lib/wayhunter_theme_preview.dart -d chrome
void main() => runApp(const WayhunterThemePreviewApp());

class WayhunterThemePreviewApp extends StatelessWidget {
  const WayhunterThemePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WayhunterThemePreview(),
    );
  }
}

class WayhunterThemePreview extends StatefulWidget {
  const WayhunterThemePreview({super.key});

  @override
  State<WayhunterThemePreview> createState() => _WayhunterThemePreviewState();
}

class _WayhunterThemePreviewState extends State<WayhunterThemePreview> {
  WayhunterMode _mode = WayhunterMode.traveler;
  int _selectedNav = 0;
  final _navItems = const [
    WayhunterNavEntry(title: 'Home', icon: Icons.home_rounded),
    WayhunterNavEntry(title: 'Hunter', icon: Icons.explore_rounded),
    WayhunterNavEntry(title: 'Leaderboard', icon: Icons.emoji_events_outlined),
    WayhunterNavEntry(title: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = WayhunterModulePalette.of(_mode);
    return WayhunterGlassScaffold(
      mode: _mode,
      bottomNavigationBar: WayhunterBubbleBottomNav(
        mode: _mode,
        selectedIndex: _selectedNav,
        items: _navItems,
        onSelected: (index) => setState(() => _selectedNav = index),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
        children: [
          const Text(
            'WAYHUNTER  /  UI PREVIEW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            p.label,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Text(
            'Soft glassmorphism • bubble navigation',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 24),
          WayhunterGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose mode', style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 8,
                  children: [
                    for (final mode in WayhunterMode.values)
                      ChoiceChip(
                        label: Text(WayhunterModulePalette.of(mode).label),
                        selected: mode == _mode,
                        onSelected: (_) => setState(() => _mode = mode),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WayhunterGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: TextStyle(fontSize: 12, color: p.subtitle)),
                const SizedBox(height: 8),
                Text(
                  _mode == WayhunterMode.traveler
                      ? 'Explore Sri Lanka'
                      : _mode == WayhunterMode.hunter
                          ? 'Discover a hidden place'
                          : 'Start your next challenge',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Existing Wayhunter features and user journeys remain unchanged. This is a reusable visual preview.',
                  style: TextStyle(fontSize: 13, color: p.subtitle, height: 1.4),
                ),
                const SizedBox(height: 24),
                WayhunterAccentButton(
                  mode: _mode,
                  label: 'Explore now',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme preview — no production routing')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: WayhunterGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.public_rounded, color: p.deepAccent),
                      const SizedBox(height: 12),
                      Text('Explore', style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WayhunterGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: p.deepAccent),
                      const SizedBox(height: 12),
                      Text('My progress', style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Preview tab: ${_navItems[_selectedNav].title}',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.ink, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
