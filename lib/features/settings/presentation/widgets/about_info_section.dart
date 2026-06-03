import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/constants/app_constants.dart';

class AboutInfoSection extends StatelessWidget {
  final bool isCheckingUpdate;
  final bool isDownloadingInline;
  final double inlineDownloadProgress;
  final String inlineUpdateStatus;
  final VoidCallback onCheckForUpdates;

  const AboutInfoSection({
    super.key,
    required this.isCheckingUpdate,
    required this.isDownloadingInline,
    required this.inlineDownloadProgress,
    required this.inlineUpdateStatus,
    required this.onCheckForUpdates,
  });

  @override
  Widget build(BuildContext context) {
    final infoItems = [
      (Icons.apps_rounded, 'Nama Aplikasi', 'EDP NetOps', context.accentColor),
      (
        Icons.tag_rounded,
        'Versi',
        'v${AppConstants.appVersion} (Enterprise Build)',
        context.accentColor,
      ),
      (Icons.build_circle_outlined, 'Build', '2026.02', context.textSecondary),
      (
        Icons.storage_outlined,
        'Database',
        'Supabase PostgreSQL',
        const Color(0xFF3ECF8E),
      ),
      (
        Icons.devices_outlined,
        'Platform',
        'Flutter (Cross-Platform)',
        const Color(0xFF54C5F8),
      ),
      (
        Icons.palette_outlined,
        'UI Framework',
        'Material Design 3',
        const Color(0xFFFFB347),
      ),
      (Icons.person_outline, 'Developer', 'PAHRUROJI', const Color(0xFFBB86FC)),
      (
        Icons.copyright_outlined,
        'Hak Cipta',
        '© 2026  All Rights Reserved.',
        context.textSecondary,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── TOP BANNER ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor.withOpacity(0.15),
                  context.secondaryAccent.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lan_outlined,
                    size: 26,
                    color: context.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'EDP',
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: ' NetOps',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Network Operations Center',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    'v${AppConstants.appVersion}',
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── STATUS PILLS + UPDATE BUTTON ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildStatusPill(
                            Icons.cloud_done_outlined,
                            'Connected',
                            const Color(0xFF00E676),
                          ),
                          _buildStatusPill(
                            Icons.security_outlined,
                            'Encrypted',
                            context.accentColor,
                          ),
                          _buildStatusPill(
                            Icons.verified_outlined,
                            'Stable',
                            const Color(0xFFFFB347),
                          ),
                        ],
                      ),
                      // ── Tombol Kecil Periksa Pembaruan ────────
                      InkWell(
                        onTap: (isCheckingUpdate || isDownloadingInline)
                            ? null
                            : onCheckForUpdates,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isCheckingUpdate
                                ? context.accentColor.withOpacity(0.15)
                                : context.accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCheckingUpdate)
                                SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: context.accentColor,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.update_rounded,
                                  size: 11,
                                  color: context.accentColor,
                                ),
                              const SizedBox(width: 5),
                              Text(
                                isCheckingUpdate
                                    ? 'Memeriksa...'
                                    : 'Cek Update',
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Progress Bar Inline (saat mengunduh) ─────
                if (isDownloadingInline) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: inlineDownloadProgress,
                            backgroundColor: context.borderColor,
                            color: context.accentColor,
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(inlineDownloadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      inlineUpdateStatus,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── INFO ROWS ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              children: List.generate(infoItems.length, (i) {
                final item = infoItems[i];
                final icon = item.$1;
                final label = item.$2;
                final value = item.$3;
                final color = item.$4;
                final isLast = i == infoItems.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(icon, size: 15, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              softWrap: true,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: context.borderColor.withOpacity(0.5),
                        indent: 44,
                      ),
                  ],
                );
              }),
            ),
          ),

          // ── FOOTER ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'System Online  ·  © 2026 Developed by Pahruroji',
                  style: TextStyle(
                    color: context.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: status pill
  Widget _buildStatusPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
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
    );
  }
}
