import 'package:fancy_bottom_navigation_plus/fancy_bottom_navigation_plus.dart';
import 'package:flutter/material.dart';

import '../theme/wayhunter_module_theme.dart';

class WayhunterNavEntry {
  const WayhunterNavEntry({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class WayhunterBubbleBottomNav extends StatelessWidget {
  const WayhunterBubbleBottomNav({
    super.key,
    required this.mode,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final WayhunterMode mode;
  final int selectedIndex;
  final List<WayhunterNavEntry> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = WayhunterModulePalette.of(mode);
    const navBackground = Color(0xFF0C2937);

    assert(items.length >= 2, 'Provide at least two navigation tabs');
    assert(selectedIndex >= 0 && selectedIndex < items.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: navBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: palette.accent.withValues(alpha: 0.27),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Theme(
            data: Theme.of(context).copyWith(
              primaryColor: palette.accent,
              canvasColor: navBackground,
            ),
            child: FancyBottomNavigationPlus(
              key: ValueKey('wayhunter-${mode.name}-$selectedIndex'),
              tabs: [
                for (final item in items)
                  TabData(
                    icon: Icon(item.icon, size: 23),
                    title: item.title,
                    activeIconColor: Colors.white,
                    inactiveIconColor: const Color(0xFFC5D9E6),
                  ),
              ],
              initialSelection: selectedIndex,
              barBackgroundColor: navBackground,
              onTabChangedListener: (index) {
                if (index != selectedIndex) onSelected(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
