import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ranking insight bar — contextual insight text from ranking data
// ─────────────────────────────────────────────────────────────────────────────

class RankingInsightBar extends StatelessWidget {
  const RankingInsightBar({
    super.key,
    required this.ranking,
    required this.totalTickets,
  });
  final List<Map<String, dynamic>> ranking;
  final int totalTickets;

  @override
  Widget build(BuildContext context) {
    if (ranking.isEmpty) return const SizedBox.shrink();

    final topStore = ranking.first;
    final topCode = topStore['store_code'] as String;
    final topName = topStore['store_name'] as String;
    final topTotal = topStore['total'] as int;
    final topOpen = topStore['open'] as int;
    final storeCount = ranking.length;

    // Build insight text
    final String insight;
    if (storeCount == 1) {
      insight =
          'Hanya $topCode ($topName) yang mengalami gangguan — $topTotal tiket.';
    } else {
      insight = '$topCode ($topName) paling sering gangguan dengan $topTotal tiket'
          '${topOpen > 0 ? ' ($topOpen masih open)' : ''}.'
          ' Total $storeCount toko terdampak dari $totalTickets tiket.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.accentColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded,
              size: 14, color: context.accentColor.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
