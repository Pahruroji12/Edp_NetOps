import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// STATIC COLORS — bisa dipakai tanpa context
// (untuk service layer, widget const, dll)
// ══════════════════════════════════════════════════════════════
class AppStatusColors {
  static const Color success = Color(0xFF00E676); // Hijau
  static const Color danger = Color(0xFFFF6B6B); // Merah
  static const Color warning = Color(0xFFFFA726); // Oranye
  static const Color accent = Color(0xFF00D4FF); // Biru/Cyan (dark)
  static const Color info = Color(0xFF00D4FF); // Biru/Cyan — info notifications
}

// ══════════════════════════════════════════════════════════════
// EXTENSION BUILDCONTEXT
// Akses warna via context tanpa hardcode nilai hex di widget
// ══════════════════════════════════════════════════════════════
extension ThemeColors on BuildContext {
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get accentColor => Theme.of(this).colorScheme.secondary;
  Color get secondaryAccent => Theme.of(this).colorScheme.tertiary;
  Color get surfaceColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get borderColor => Theme.of(this).dividerColor;
  Color get textPrimary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get textSecondary => Theme.of(this).textTheme.bodyMedium!.color!;

  Color get successColor => AppStatusColors.success;
  Color get dangerColor => AppStatusColors.danger;
  Color get warningColor => AppStatusColors.warning;
}
