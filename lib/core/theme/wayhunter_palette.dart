import 'package:flutter/material.dart';

/// Module-scoped presentation colors. Never recolor provided banner PNGs.
abstract final class WayhunterPalette {
  static const navy = Color(0xFF03045E);
  static const foreground = Color(0xFFF8FAFC);
  static const travellerBlue = Color(0xFF0077B6);
  static const travellerCyan = Color(0xFF00B4D8);
  static const hunterGold = Color(0xFF8EB69B);
  static const hunterAmber = Color(0xFFDAF1DE);
  static const gamePurple = Color(0xFF9D4CCC);
  static const gameViolet = Color(0xFF8339B3);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFF43F5E);
  static const glass = Color(0xB30F172A);
}

// Reference palette HEX values from the user-provided images.
abstract final class WayhunterThemeColors {
  static const travelDark = Color(0xFF03045E);
  static const travelBlue = Color(0xFF0077B6);
  static const travelCyan = Color(0xFF00B4D8);
  static const travelLight = Color(0xFF90E0EF);
  static const travelPale = Color(0xFFCAF0F8);
  static const hunterDeep = Color(0xFF051F20);
  static const hunterForest = Color(0xFF0B2B26);
  static const hunterTeal = Color(0xFF163832);
  static const hunterLeaf = Color(0xFF235347);
  static const hunterSage = Color(0xFF8EB69B);
  static const hunterPale = Color(0xFFDAF1DE);
  static const gameLilac = Color(0xFF9D4CCC);
  static const gameMedium = Color(0xFF8339B3);
  static const gameRichViolet = Color(0xFF682699);
  static const gameDeep = Color(0xFF4E1380);
  static const gameNight = Color(0xFF330066);
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
