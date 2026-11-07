import 'package:flutter/material.dart';

/// Module-scoped presentation colors. Never recolor provided banner PNGs.
abstract final class WayhunterPalette {
  static const navy = Color(0xFF0F172A);
  static const foreground = Color(0xFFF8FAFC);
  static const travellerBlue = Color(0xFF0284C7);
  static const travellerCyan = Color(0xFF08B7FF);
  static const hunterGold = Color(0xFFFFBA32);
  static const hunterAmber = Color(0xFFFBBF24);
  static const gamePurple = Color(0xFFB277FF);
  static const gameViolet = Color(0xFFA855F7);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFF43F5E);
  static const glass = Color(0xB30F172A);
}

enum WayhunterModule { common, traveller, hunter, game }

extension ModuleAccent on WayhunterModule {
  Color get accent => switch (this) {
    WayhunterModule.common => WayhunterPalette.travellerCyan,
    WayhunterModule.traveller => WayhunterPalette.travellerCyan,
    WayhunterModule.hunter => WayhunterPalette.hunterGold,
    WayhunterModule.game => WayhunterPalette.gamePurple,
  };
}
