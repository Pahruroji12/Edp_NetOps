import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// THEME NOTIFIER — kontrol Dark/Light mode secara global
// Dipakai di app/app.dart lewat ValueListenableBuilder
// ══════════════════════════════════════════════════════════════
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// ══════════════════════════════════════════════════════════════
// APP THEMES
// ══════════════════════════════════════════════════════════════
class AppThemes {
  // ── DARK MODE ─────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1F38),
    primaryColor: const Color(0xFF0A1628),
    cardColor: const Color(0xFF162340),
    dividerColor: const Color(0xFF1E3A5F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0A1628),
      secondary: Color(0xFF00D4FF), // accentColor
      tertiary: Color(0xFF6C63FF), // secondaryAccent (Ungu Neon)
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE8F4FF)), // textPrimary
      bodyMedium: TextStyle(color: Color(0xFF7A9CC4)), // textSecondary
    ),
  );

  // ── LIGHT MODE ────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    primaryColor: const Color(0xFFFFFFFF),
    cardColor: const Color(0xFFFFFFFF),
    dividerColor: const Color(0xFFE5E7EB),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF007BFF), // Biru Terang
      tertiary: Color(0xFF5A52D5), // secondaryAccent Ungu
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF111827)), // Hitam
      bodyMedium: TextStyle(color: Color(0xFF6B7280)), // Abu-abu
    ),
  );
}
