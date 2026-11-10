import 'package:flutter/material.dart';

/// Use on Sign In, Create Account, OTP, Forgot Password and Reset Password.
/// Keep each page's existing form and navigation widgets as its [child].
class WayhunterAuthBackground extends StatelessWidget {
  const WayhunterAuthBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.18,
  });

  final Widget child;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/backgrounds/wayhunter_auth_home_bg.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        ColoredBox(color: Colors.black.withValues(alpha: overlayOpacity)),
        child,
      ],
    );
  }
}
