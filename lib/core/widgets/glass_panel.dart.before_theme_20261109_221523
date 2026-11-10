import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/wayhunter_palette.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (accent ?? WayhunterPalette.travellerCyan).withValues(
              alpha: .42,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF123C4F).withValues(alpha: .56),
              const Color(0xFF06121F).withValues(alpha: .70),
            ],
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}
