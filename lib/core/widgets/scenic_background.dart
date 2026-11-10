import 'package:flutter/material.dart';

import '../theme/wayhunter_palette.dart';
import 'app_themed_background.dart';

/// Legacy API preserved. Only an explicit `home: true` shows an image.
/// Other callers automatically receive the neutral soft-glass background.
/// wayhunter-soft-glass-no-photo-v2
class ScenicBackground extends StatelessWidget {
  const ScenicBackground({
    super.key,
    required this.child,
    this.dim = true,
    this.home = false,
    this.module = WayhunterModule.common,
  });

  final Widget child;
  final bool dim;
  final bool home;
  final WayhunterModule module;

  @override
  Widget build(BuildContext context) =>
      AppThemedBackground(dim: dim, home: home, module: module, child: child);
}
