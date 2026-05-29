import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';

/// StatsGrid — grid statistik jaringan di DashboardPage.
///
/// Lokasi: features/dashboard/presentation/widgets/stats_grid.dart
///
class StatsGrid extends StatelessWidget {
  final int totalStores;
  final int foStores;
  final int backupVsat;
  final int singleVsat;
  final int gsmStores;
  final int xlStores;

  const StatsGrid({
    super.key,
    required this.totalStores,
    required this.foStores,
    required this.backupVsat,
    required this.singleVsat,
    required this.gsmStores,
    required this.xlStores,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        'Total Toko',
        totalStores,
        Icons.store_outlined,
        context.accentColor,
        const Color(0xFF0A2030),
      ),
      _StatItem(
        'Fiber Optic',
        foStores,
        Icons.cable_outlined,
        const Color(0xFF00E676),
        const Color(0xFF0A2018),
      ),
      _StatItem(
        'Backup VSAT',
        backupVsat,
        Icons.satellite_alt_outlined,
        const Color(0xFF6C63FF),
        const Color(0xFF150F2A),
      ),
      _StatItem(
        'Single VSAT',
        singleVsat,
        Icons.satellite_outlined,
        const Color(0xFFFFB347),
        const Color(0xFF241D10),
      ),
      _StatItem(
        'GSM/Orbit',
        gsmStores,
        Icons.cell_tower_outlined,
        const Color(0xFFFF6B6B),
        const Color(0xFF2A1015),
      ),
      _StatItem(
        'XL',
        xlStores,
        Icons.signal_cellular_alt_outlined,
        const Color(0xFFBB86FC),
        const Color(0xFF1A102A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        
        // Responsive columns
        final int cols = w >= 900
            ? 6
            : w >= 600
                ? 3
                : 2;

        const spacing = 12.0;

        // Calculate child aspect ratio dynamically to keep sizing stable
        final double cardHeight = w >= 600 ? 102.0 : 88.0;
        final double cardWidth = (w - (spacing * (cols - 1))) / cols;
        final double aspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio.clamp(0.6, 2.0),
          children: stats.map((s) => _StatCard(stat: s)).toList(),
        );
      },
    );
  }
}

// ── Private model ─────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  const _StatItem(
    this.label,
    this.value,
    this.icon,
    this.accentColor,
    this.bgColor,
  );
}

// ── Private card widget ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final sf = context.scaleFactor;
    return Container(
      padding: EdgeInsets.all(12 * sf),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: stat.accentColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: stat.bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stat.accentColor.withOpacity(0.2)),
                ),
                child: Icon(stat.icon, color: stat.accentColor, size: 12 * sf),
              ),
              Text(
                '${stat.value}',
                style: TextStyle(
                  color: stat.accentColor,
                  fontSize: context.scaledFont(18),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * sf),
          Text(
            stat.label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: context.scaledFont(9, minSize: 8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
