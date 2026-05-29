import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_helper.dart';

/// ConfirmDialog — dialog konfirmasi reusable.
///
/// Lokasi: core/widgets/confirm_dialog.dart
///
/// Menggantikan 5+ duplicate confirm dialog inline di:
///   - store_detail_page (delete store, error dialog)
///   - profile_page (delete user)
///   - ftp_page (cancel upload)
///   - wdcp_control_page (confirm reboot)
///
/// Cara pakai:
///   final result = await showConfirmDialog(
///     context,
///     title: 'Hapus Toko?',
///     message: 'Data akan dihapus permanen.',
///     confirmLabel: 'Hapus',
///     confirmColor: Colors.red,
///     icon: Icons.delete_outline,
///   );
///   if (result == true) { ... }
///

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  Color? confirmColor,
  Color? iconColor,
  IconData icon = Icons.help_outline_rounded,
  bool isDanger = false,
}) {
  final dangerColor = const Color(0xFFFF6B6B);
  final effectiveConfirmColor =
      confirmColor ?? (isDanger ? dangerColor : context.accentColor);
  final effectiveIconColor =
      iconColor ?? (isDanger ? dangerColor : context.accentColor);

  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth(base: 420)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.dialogMargin),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(context.scaledPadding(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveIconColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 28),
                ),
                const SizedBox(height: 16),

                // ── Title ───────────────────────────────────────
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // ── Message ─────────────────────────────────────
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Buttons ─────────────────────────────────────
                Row(
                  children: [
                    // Batal
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: effectiveConfirmColor,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dialog info sederhana (OK button only).
///
/// Cara pakai:
///   await showInfoDialog(context, title: 'Error', message: '...');
///
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_outline_rounded,
  Color? iconColor,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth(base: 380)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.dialogMargin),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(context.scaledPadding(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconColor != null || icon != Icons.info_outline_rounded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Icon(
                      icon,
                      color: iconColor ?? context.accentColor,
                      size: 32,
                    ),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentColor,
                      foregroundColor: context.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
