import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/wayhunter_module_theme.dart';

/// Wrap an *existing* Scaffold with this to preserve its business logic,
/// routes, providers, map, camera, and navigation while changing backdrop.
class WayhunterGradientBackdrop extends StatelessWidget {
  const WayhunterGradientBackdrop({
    super.key,
    required this.mode,
    required this.child,
  });

  final WayhunterMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = WayhunterModulePalette.of(mode);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.top, p.bottom],
          stops: const [.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Use for new screens only. Existing screens can just wrap their current
/// Scaffold in WayhunterGradientBackdrop (above).
class WayhunterGlassScaffold extends StatelessWidget {
  const WayhunterGlassScaffold({
    super.key,
    required this.mode,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.floatingActionButton,
  });

  final WayhunterMode mode;
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: wayhunterModuleTheme(mode),
      child: WayhunterGradientBackdrop(
        mode: mode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: appBar,
          body: SafeArea(bottom: bottomNavigationBar == null, child: body),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}

class WayhunterGlassCard extends StatelessWidget {
  const WayhunterGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 25,
    this.blur = 15,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153449).withValues(alpha: .11),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: .83),
                width: 1.1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .74),
                  Colors.white.withValues(alpha: .48),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class WayhunterAccentButton extends StatelessWidget {
  const WayhunterAccentButton({
    super.key,
    required this.mode,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final WayhunterMode mode;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = WayhunterModulePalette.of(mode);
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [p.deepAccent, p.accent]),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(color: p.accent.withValues(alpha: .30), blurRadius: 18),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 19, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
