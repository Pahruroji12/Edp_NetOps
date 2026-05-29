import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../dashboard_controller.dart';

/// Compact incident ranking section for dashboard.
class RankingSection extends StatelessWidget {
  const RankingSection({super.key, required this.ctrl});
  final DashboardController ctrl;

  @override
  Widget build(BuildContext context) {
    final ranking = ctrl.incidentRanking;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: const Color(0xFFFFA726)),
            const SizedBox(width: 8),
            Text('RANKING GANGGUAN', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: context.textSecondary, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 16),

          if (ranking.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Tidak ada gangguan', style: TextStyle(
                color: context.textSecondary, fontSize: 12))),
            )
          else
            ...ranking.asMap().entries.map((e) => _RankItem(
              rank: e.key + 1,
              item: e.value,
            )),
        ],
      ),
    );
  }
}

class _RankItem extends StatelessWidget {
  const _RankItem({required this.rank, required this.item});
  final int rank;
  final Map<String, dynamic> item;

  Color _severityColor(int total, int open) {
    final ratio = total > 0 ? open / total : 0.0;
    if (total >= 5 || ratio > 0.6) return const Color(0xFFFF6B6B);
    if (total >= 3 || ratio > 0.3) return const Color(0xFFFFA726);
    return const Color(0xFF00E676);
  }

  Color _medalColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF4A5568);
  }

  @override
  Widget build(BuildContext context) {
    final total = item['total'] as int;
    final open = item['open'] as int;
    final progress = item['progress'] as int;
    final resolved = item['resolved'] as int;
    final storeCode = item['store_code'] as String;
    final storeName = item['store_name'] as String;
    final sevColor = _severityColor(total, open);
    final medal = _medalColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: medal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: medal.withOpacity(0.3)),
            ),
            child: Center(child: Text('$rank', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: medal))),
          ),
          const SizedBox(width: 8),

          // Severity bar
          Container(width: 3, height: 24, decoration: BoxDecoration(
            color: sevColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),

          // Store info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$storeCode — $storeName', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: context.textPrimary),
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              // Segmented mini progress
              _MiniProgress(open: open, progress: progress, resolved: resolved, total: total),
            ],
          )),
          const SizedBox(width: 8),

          // Total badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4)),
            child: Text('$total', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: sevColor)),
          ),
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.open, required this.progress, required this.resolved, required this.total});
  final int open, progress, resolved, total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Row(children: [
          if (open > 0) Expanded(flex: open,
            child: Container(color: const Color(0xFFFF6B6B))),
          if (progress > 0) Expanded(flex: progress,
            child: Container(color: const Color(0xFFFFA726))),
          if (resolved > 0) Expanded(flex: resolved,
            child: Container(color: const Color(0xFF00E676))),
        ]),
      ),
    );
  }
}
