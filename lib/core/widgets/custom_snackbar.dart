import 'package:flutter/material.dart';

import '../globals.dart';

/// CustomSnackBar — snackbar bergaya konsisten di seluruh aplikasi.
///
/// Lokasi: core/widgets/custom_snackbar.dart
///
/// ══════════════════════════════════════════════════════════════
/// CARA PAKAI (3 cara — dari yang paling disarankan):
///
///   // 1. ✅ RECOMMENDED — Semantic API (tanpa context, tanpa color)
///   CustomSnackBar.success('Data berhasil disimpan!');
///   CustomSnackBar.error('Gagal mengirim email');
///   CustomSnackBar.warning('Periksa format input');
///   CustomSnackBar.info('Data disalin ke clipboard');
///
///   // 2. ✅ Dengan GlobalKey (untuk lintas navigasi / service layer)
///   CustomSnackBar.showFromKey(globalMessengerKey, 'Pesan', Colors.green);
///
///   // 3. ⚠️ Dengan BuildContext (legacy — hindari di async handler)
///   CustomSnackBar.show(context, 'Pesan', Colors.green);
/// ══════════════════════════════════════════════════════════════
class CustomSnackBar {
  // ── 1. SEMANTIC API — recommended ─────────────────────────────
  // Tanpa perlu context, tanpa perlu Color.
  // Menggunakan globalMessengerKey secara otomatis.

  /// Notifikasi berhasil — hijau.
  static void success(String message) =>
      _showGlobal(message, _SnackLevel.success);

  /// Notifikasi error — merah.
  static void error(String message) =>
      _showGlobal(message, _SnackLevel.error);

  /// Notifikasi peringatan — oranye.
  static void warning(String message) =>
      _showGlobal(message, _SnackLevel.warning);

  /// Notifikasi informasi — biru.
  static void info(String message) =>
      _showGlobal(message, _SnackLevel.info);

  // ── Deduplication / Throttling ────────────────────────────────
  static String? _lastMessage;
  static DateTime? _lastShownTime;

  static bool _shouldThrottle(String message) {
    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!).inMilliseconds < 1000) {
      return true;
    }
    _lastMessage = message;
    _lastShownTime = now;
    return false;
  }

  // ── 2. Legacy API — backward compatible ───────────────────────

  /// Versi dengan BuildContext — untuk halaman yang belum migrasi.
  ///
  /// ⚠️ Hindari di async handler karena context bisa stale.
  /// Gunakan [success], [error], [warning], [info] sebagai gantinya.
  static void show(BuildContext context, String message, Color color) {
    if (_shouldThrottle(message)) return;
    final cfg = _resolveFromColor(color);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_buildSnackBar(cfg, message));
  }

  /// Versi dengan GlobalKey — untuk service layer tanpa context.
  static void showFromKey(
    GlobalKey<ScaffoldMessengerState> key,
    String message,
    Color color,
  ) {
    if (_shouldThrottle(message)) return;
    final state = key.currentState;
    if (state == null) return;
    final cfg = _resolveFromColor(color);
    state
      ..clearSnackBars()
      ..showSnackBar(_buildSnackBar(cfg, message));
  }

  // ── Internal ──────────────────────────────────────────────────

  /// Show via globalMessengerKey — untuk semantic API.
  static void _showGlobal(String message, _SnackLevel level) {
    if (_shouldThrottle(message)) return;
    final state = globalMessengerKey.currentState;
    if (state == null) return;
    final cfg = _resolveFromLevel(level);
    state
      ..clearSnackBars()
      ..showSnackBar(_buildSnackBar(cfg, message));
  }

  // ── Resolve config dari semantic level ────────────────────────
  static _SnackConfig _resolveFromLevel(_SnackLevel level) {
    switch (level) {
      case _SnackLevel.success:
        return const _SnackConfig(
          icon: Icons.check_circle_rounded,
          title: 'Berhasil!',
          accentColor: Color(0xFF4CAF50),
          iconBg: Color(0xFF1B3A26),
          leftBarColor: Color(0xFF4CAF50),
        );
      case _SnackLevel.error:
        return const _SnackConfig(
          icon: Icons.error_rounded,
          title: 'Gagal!',
          accentColor: Color(0xFFEF5350),
          iconBg: Color(0xFF3A1B1B),
          leftBarColor: Color(0xFFEF5350),
        );
      case _SnackLevel.warning:
        return const _SnackConfig(
          icon: Icons.warning_rounded,
          title: 'Perhatian!',
          accentColor: Color(0xFFFFA726),
          iconBg: Color(0xFF3A2E1B),
          leftBarColor: Color(0xFFFFA726),
        );
      case _SnackLevel.info:
        return const _SnackConfig(
          icon: Icons.info_rounded,
          title: 'Info',
          accentColor: Color(0xFF29B6F6),
          iconBg: Color(0xFF1B2E3A),
          leftBarColor: Color(0xFF29B6F6),
        );
    }
  }

  // ── Resolve config dari warna (legacy — backward compatible) ──
  static _SnackConfig _resolveFromColor(Color color) {
    if (color == Colors.red || color == const Color(0xFFFF6B6B)) {
      return _resolveFromLevel(_SnackLevel.error);
    } else if (color == Colors.green ||
        color == const Color(0xFF00E676) ||
        color == const Color(0xFF00C853)) {
      return _resolveFromLevel(_SnackLevel.success);
    } else if (color == Colors.orange ||
        color == const Color(0xFFFFB347) ||
        color == const Color(0xFFFFA726)) {
      return _resolveFromLevel(_SnackLevel.warning);
    } else {
      return _resolveFromLevel(_SnackLevel.info);
    }
  }

  // ── Build widget SnackBar ────────────────────────────────────
  static SnackBar _buildSnackBar(_SnackConfig cfg, String message) {
    return SnackBar(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      // Desktop: limit lebar. Mobile: full width with margin.
      width: 480,
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
      content: Container(
        constraints: const BoxConstraints(minHeight: 62),
        decoration: BoxDecoration(
          // Dark-theme-aware: latar gelap navy, bukan putih
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cfg.accentColor.withOpacity(0.25),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: cfg.accentColor.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 62),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cfg.leftBarColor,
                      cfg.leftBarColor.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Icon box
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cfg.iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cfg.accentColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(cfg.icon, color: cfg.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Teks
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cfg.title,
                        style: TextStyle(
                          color: cfg.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Dismiss button
              _SnackDismissButton(accentColor: cfg.accentColor),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol dismiss (X) di snackbar.
class _SnackDismissButton extends StatelessWidget {
  final Color accentColor;
  const _SnackDismissButton({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: accentColor.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

/// Level semantik snackbar.
enum _SnackLevel { success, error, warning, info }

/// Config internal snackbar.
class _SnackConfig {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Color iconBg;
  final Color leftBarColor;

  const _SnackConfig({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.iconBg,
    required this.leftBarColor,
  });
}
