import 'package:flutter/material.dart';

/// Only affects appearance. Never move business logic into this layer.
enum WayhunterMode { traveler, hunter, game }

/// Mist-blue frosted cards from reference 1 and deep-teal glass from reference 2.
/// Each module retains its own accent while sharing shape/typography rules.
class WayhunterModulePalette {
  const WayhunterModulePalette({
    required this.top,
    required this.bottom,
    required this.accent,
    required this.deepAccent,
    required this.ink,
    required this.subtitle,
    required this.label,
  });

  final Color top;
  final Color bottom;
  final Color accent;
  final Color deepAccent;
  final Color ink;
  final Color subtitle;
  final String label;

  static const traveler = WayhunterModulePalette(
    top: Color(0xFF5286A3),
    bottom: Color(0xFFE8EDF6),
    accent: Color(0xFF28B8EF),
    deepAccent: Color(0xFF126E9F),
    ink: Color(0xFF102C40),
    subtitle: Color(0xFF567184),
    label: 'Traveler',
  );

  static const hunter = WayhunterModulePalette(
    top: Color(0xFF4B8A7F),
    bottom: Color(0xFFE7EFE8),
    accent: Color(0xFF17C9A5),
    deepAccent: Color(0xFF117F73),
    ink: Color(0xFF112F2E),
    subtitle: Color(0xFF58756B),
    label: 'Hunter',
  );

  static const game = WayhunterModulePalette(
    top: Color(0xFF7878B1),
    bottom: Color(0xFFEEE9F7),
    accent: Color(0xFFAA78F4),
    deepAccent: Color(0xFF7152BB),
    ink: Color(0xFF272044),
    subtitle: Color(0xFF6A6486),
    label: 'Game',
  );

  static WayhunterModulePalette of(WayhunterMode mode) {
    return switch (mode) {
      WayhunterMode.traveler => traveler,
      WayhunterMode.hunter => hunter,
      WayhunterMode.game => game,
    };
  }
}

/// Optional per-module ThemeData, useful if a screen contains many Material
/// buttons and text fields. Don't replace the app's global theme blindly.
ThemeData wayhunterModuleTheme(WayhunterMode mode) {
  final p = WayhunterModulePalette.of(mode);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: p.accent).copyWith(
      primary: p.deepAccent,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: p.ink,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.ink,
      elevation: 0,
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        color: p.ink,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: p.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: p.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: p.ink, fontSize: 14),
      bodySmall: TextStyle(color: p.subtitle, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .66),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: p.accent, width: 1.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.deepAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}
