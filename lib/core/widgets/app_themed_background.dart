import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/wayhunter_palette.dart';

/// Photo backgrounds are limited to Home. All other screens use soft,
/// image-free colour gradients with subtle glass/neumorphic highlights.
/// wayhunter-soft-glass-no-photo-v2
class AppThemedBackground extends StatelessWidget {
  const AppThemedBackground({
    super.key,
    required this.child,
    this.module = WayhunterModule.common,
    this.home = false,
    this.dim = true,
  });

  final Widget child;
  final WayhunterModule module;
  final bool home;
  final bool dim;

  String get _asset {
    if (home) return AppAssets.wayhunterHomeBackground;
    return switch (module) {
      WayhunterModule.traveller => AppAssets.travellerSoftBackground,
      WayhunterModule.hunter => AppAssets.hunterSoftBackground,
      WayhunterModule.game => AppAssets.gameSoftBackground,
      WayhunterModule.common => AppAssets.commonSoftBackground,
    };
  }

  Color get _shine => switch (module) {
    WayhunterModule.traveller => const Color(0xFF90E0EF),
    WayhunterModule.hunter => const Color(0xFFDAF1DE),
    WayhunterModule.game => const Color(0xFF9D4CCC),
    WayhunterModule.common => const Color(0xFFDCE7F1),
  };

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        _asset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        excludeFromSemantics: true,
      ),
      if (home)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: dim ? .22 : .06),
                Colors.transparent,
                Colors.black.withValues(alpha: dim ? .45 : .22),
              ],
            ),
          ),
        )
      else ...[
        // Pure colours, no mountains, landscape photos or background logos.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .08),
                Colors.transparent,
                Colors.black.withValues(alpha: .28),
              ],
            ),
          ),
        ),
        Positioned(
          top: -115,
          right: -112,
          width: 310,
          height: 310,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _shine.withValues(alpha: .20),
                    _shine.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
      child,
    ],
  );
}
