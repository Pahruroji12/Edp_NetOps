import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/constants/app_constants.dart';
import 'package:edp_netops/core/services/auto_update_service.dart';
import 'version_info_card.dart';
import 'changelog_section.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onStartDownload;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onStartDownload,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _animReady = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _animReady = true);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _animReady ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _animReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            width: 460,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.accentColor.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: context.accentColor.withOpacity(0.08),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildVersionComparison(context),
                ChangelogSection(changelog: widget.updateInfo.changelog),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER: Gradient banner with animated glow ──────────────────
  Widget _buildHeader(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = 0.06 + (_glowController.value * 0.08);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.accentColor.withOpacity(glowOpacity + 0.04),
                const Color(0xFF6C63FF).withOpacity(glowOpacity),
                context.cardColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated icon with pulsing glow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.accentColor.withOpacity(0.25),
                      const Color(0xFF6C63FF).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.accentColor.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: context.accentColor.withOpacity(0.2 + (_glowController.value * 0.15)),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(Icons.rocket_launch_rounded, color: context.accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'Pembaruan Tersedia',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versi terbaru siap diunduh dan dipasang.',
                      style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              // Close button
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: context.textSecondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: context.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── VERSION COMPARISON ─────────────────────────────────────────
  Widget _buildVersionComparison(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: VersionInfoCard(
              label: 'VERSI SAAT INI',
              version: 'v${AppConstants.appVersion}',
              color: context.textSecondary,
              icon: Icons.inventory_2_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: context.accentColor.withOpacity(0.25)),
              ),
              child: Icon(Icons.double_arrow_rounded, size: 14, color: context.accentColor),
            ),
          ),
          Expanded(
            child: VersionInfoCard(
              label: 'VERSI TERBARU',
              version: 'v${widget.updateInfo.latestVersion}',
              color: context.accentColor,
              icon: Icons.new_releases_outlined,
              isNew: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS ─────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // Nanti Saja
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: context.textSecondary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Center(
                  child: Text(
                    'Nanti Saja',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Unduh & Pasang
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: widget.onStartDownload,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.accentColor, const Color(0xFF6C63FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.accentColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Unduh & Pasang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
