import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class ScenicBackground extends StatelessWidget {
  const ScenicBackground({super.key, required this.child, this.dim = true});
  final Widget child;
  final bool dim;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        AppAssets.homeBackground,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        excludeFromSemantics: true,
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .3, 1],
            colors: [
              Colors.black.withValues(alpha: dim ? .35 : .16),
              Colors.black.withValues(alpha: dim ? .28 : .08),
              const Color(0xFF020C16).withValues(alpha: dim ? .82 : .5),
            ],
          ),
        ),
      ),
      child,
    ],
  );
}
