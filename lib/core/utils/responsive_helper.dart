import 'package:flutter/material.dart';

/// ResponsiveHelper — sistem responsive layout untuk multi-resolusi desktop.
///
/// Lokasi: core/utils/responsive_helper.dart
///
/// Fitur:
///   - Breakpoint system (compact / medium / expanded / large)
///   - Scale factor otomatis berdasarkan resolusi layar
///   - Adaptive font, padding, spacing, dan dialog size
///   - Reusable di seluruh aplikasi via BuildContext extension
///
/// Referensi resolusi target:
///   - 1366×768   → compact  (scaleFactor ≈ 0.82)
///   - 1600×900   → medium   (scaleFactor ≈ 0.92)
///   - 1920×1080  → expanded (scaleFactor = 1.0, baseline)
///   - 2560×1440  → large    (scaleFactor ≈ 1.15)
///   - 3840×2160  → large    (scaleFactor ≈ 1.25)
///

// ══════════════════════════════════════════════════════════════
// BREAKPOINTS
// ══════════════════════════════════════════════════════════════

enum ScreenBreakpoint { compact, medium, expanded, large }

// ══════════════════════════════════════════════════════════════
// RESPONSIVE HELPER (static utility)
// ══════════════════════════════════════════════════════════════

class ResponsiveHelper {
  ResponsiveHelper._();

  // ── Breakpoint thresholds ──────────────────────────────────
  static const double compactMax = 1200;   // < 1200 → compact
  static const double mediumMax = 1600;    // 1200–1600 → medium
  static const double expandedMax = 2200;  // 1600–2200 → expanded
  // > 2200 → large

  /// Tentukan breakpoint dari lebar layar.
  static ScreenBreakpoint breakpointOf(double screenWidth) {
    if (screenWidth < compactMax) return ScreenBreakpoint.compact;
    if (screenWidth < mediumMax) return ScreenBreakpoint.medium;
    if (screenWidth < expandedMax) return ScreenBreakpoint.expanded;
    return ScreenBreakpoint.large;
  }

  /// Scale factor proporsional berdasarkan lebar layar.
  ///
  /// Baseline = 1920px → factor 1.0
  /// Formula: clamp(width / 1920, 0.75, 1.35)
  ///
  /// Ini memastikan:
  ///   - 1366px → 0.82 (lebih kecil, proporsional)
  ///   - 1600px → 0.92
  ///   - 1920px → 1.0  (baseline)
  ///   - 2560px → 1.15
  ///   - 3840px → 1.35 (cap agar tidak terlalu besar)
  static double scaleFactor(double screenWidth) {
    return (screenWidth / 1920).clamp(0.75, 1.35);
  }

  // ── Sidebar ────────────────────────────────────────────────

  /// Sidebar width adaptive berdasarkan breakpoint.
  static double sidebarWidth(double screenWidth) {
    final bp = breakpointOf(screenWidth);
    switch (bp) {
      case ScreenBreakpoint.compact:
        return 220;
      case ScreenBreakpoint.medium:
        return 248;
      case ScreenBreakpoint.expanded:
        return 270;
      case ScreenBreakpoint.large:
        return 290;
    }
  }

  /// Apakah sidebar harus muncul permanen (tidak drawer).
  static bool showPermanentSidebar(double screenWidth) => screenWidth >= 850;

  // ── Dialogs ────────────────────────────────────────────────

  /// Max width dialog, proporsional terhadap layar.
  static double dialogMaxWidth(double screenWidth, {double base = 460}) {
    final bp = breakpointOf(screenWidth);
    switch (bp) {
      case ScreenBreakpoint.compact:
        // Di layar kecil, dialog max 85% lebar layar
        return (screenWidth * 0.85).clamp(300, base - 40);
      case ScreenBreakpoint.medium:
        return base - 20;
      case ScreenBreakpoint.expanded:
      case ScreenBreakpoint.large:
        return base;
    }
  }

  /// Dialog horizontal margin.
  static double dialogMargin(double screenWidth) {
    final bp = breakpointOf(screenWidth);
    switch (bp) {
      case ScreenBreakpoint.compact:
        return 12;
      case ScreenBreakpoint.medium:
        return 16;
      case ScreenBreakpoint.expanded:
      case ScreenBreakpoint.large:
        return 20;
    }
  }

  // ── Grid columns ───────────────────────────────────────────

  /// Jumlah kolom stats grid berdasarkan lebar container.
  static int statsColumns(double containerWidth) {
    if (containerWidth >= 800) return 6;
    if (containerWidth >= 600) return 6;
    if (containerWidth >= 350) return 3;
    return 2;
  }
}

// ══════════════════════════════════════════════════════════════
// BUILDCONTEXT EXTENSION — akses cepat responsive values
// ══════════════════════════════════════════════════════════════

extension ResponsiveContext on BuildContext {
  // ── Screen info ────────────────────────────────────────────
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ── Breakpoint ─────────────────────────────────────────────
  ScreenBreakpoint get breakpoint =>
      ResponsiveHelper.breakpointOf(screenWidth);

  bool get isCompact => breakpoint == ScreenBreakpoint.compact;
  bool get isMedium => breakpoint == ScreenBreakpoint.medium;
  bool get isExpanded => breakpoint == ScreenBreakpoint.expanded;
  bool get isLarge => breakpoint == ScreenBreakpoint.large;

  bool get isDesktop => ResponsiveHelper.showPermanentSidebar(screenWidth);

  // ── Scale factor ───────────────────────────────────────────
  double get scaleFactor => ResponsiveHelper.scaleFactor(screenWidth);

  // ── Scaled values ──────────────────────────────────────────

  /// Scale sebuah nilai berdasarkan resolusi layar.
  /// Contoh: `context.scaled(16)` → 13.12 di 1366px, 16.0 di 1920px
  double scaled(double value) => value * scaleFactor;

  /// Scale font size (dengan minimum floor agar tetap terbaca).
  double scaledFont(double baseFontSize, {double minSize = 9}) {
    return (baseFontSize * scaleFactor).clamp(minSize, baseFontSize * 1.35);
  }

  /// Scale padding (dengan minimum floor).
  double scaledPadding(double basePadding, {double minPadding = 6}) {
    return (basePadding * scaleFactor).clamp(minPadding, basePadding * 1.35);
  }

  // ── Page padding ───────────────────────────────────────────

  /// Padding utama halaman (kiri-kanan).
  double get pagePaddingH {
    switch (breakpoint) {
      case ScreenBreakpoint.compact:
        return 12;
      case ScreenBreakpoint.medium:
        return 16;
      case ScreenBreakpoint.expanded:
        return 20;
      case ScreenBreakpoint.large:
        return 24;
    }
  }

  /// Padding utama halaman EdgeInsets.
  EdgeInsets get pageEdgeInsets => EdgeInsets.symmetric(
        horizontal: pagePaddingH,
        vertical: scaledPadding(20),
      );

  // ── Sidebar ────────────────────────────────────────────────
  double get sidebarWidth => ResponsiveHelper.sidebarWidth(screenWidth);

  // ── Dialog ─────────────────────────────────────────────────
  double dialogMaxWidth({double base = 460}) =>
      ResponsiveHelper.dialogMaxWidth(screenWidth, base: base);

  double get dialogMargin => ResponsiveHelper.dialogMargin(screenWidth);
}
