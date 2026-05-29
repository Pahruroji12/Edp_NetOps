import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NETWORK ACTION BUTTONS
// Widget tombol aksi jaringan yang dipakai bersama di:
//   - store_detail_page.dart
//   - scan_wdcp_page.dart
//
// Cara pakai:
//   import '../../widgets/network_action_buttons.dart';
//
//   MiniActionButton(label: 'WINBOX', color: context.accentColor, onTap: ...)
//   SolidActionButton(label: 'Winbox', icon: Icons.router, color: ..., onTap: ...)
//   OutlineActionButton(label: 'Ping', icon: Icons.wifi, color: ..., onTap: ...)
// ══════════════════════════════════════════════════════════════════════════════

// ── 1. MiniActionButton ───────────────────────────────────────────────────────
// Tombol kecil (chip) yang dipakai di card list toko / scan WDCP.
// Contoh: WINBOX · PING · OPEN · TELNET · FTP · VNC · VIEW
class MiniActionButton extends StatelessWidget {
  const MiniActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.isOutline = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  /// true  → border saja, background transparan
  /// false → background color.withOpacity(0.12) + border tipis (default)
  final bool isOutline;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withOpacity(isOutline ? 0.3 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2. SolidActionButton ──────────────────────────────────────────────────────
// Tombol besar solid dengan gradient, dipakai di bagian bawah store_detail_page.
// Contoh: Winbox · VNC
class SolidActionButton extends StatelessWidget {
  const SolidActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: context.primaryColor, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: context.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3. OutlineActionButton ────────────────────────────────────────────────────
// Tombol besar outline (tanpa fill), dipakai di bagian bawah store_detail_page.
// Contoh: Ping · View · FTP
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
