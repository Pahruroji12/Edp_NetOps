import 'package:flutter/material.dart';

import '../../presentation/ticket_controller.dart';
import 'ticket_card.dart';
import 'ticket_filter_panel.dart';
import 'ranking/ranking_summary.dart';
import 'ranking/ranking_insight.dart';
import 'ranking/ranking_list.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab Ranking (Sering Gangguan) — orchestrator
//
// Widget-widget utama dipecah ke folder ranking/:
//   - ranking_summary.dart  → RankingSummaryRow, RankingSummaryCard
//   - ranking_insight.dart  → RankingInsightBar
//   - ranking_list.dart     → RankingHeaderBar, CompactRankCard, TableRankView
//   - ranking_detail.dart   → RankingExpandedDetail, RankingStatChip
// ─────────────────────────────────────────────────────────────────────────────
class TicketRankingTab extends StatelessWidget {
  const TicketRankingTab({
    super.key,
    required this.ctrl,
    required this.onFilterChanged,
  });
  final TicketController ctrl;
  final VoidCallback onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final dataForRanking = (ctrl.rankingPeriodStart == null ||
            ctrl.rankingPeriodEnd == null)
        ? ctrl.allTickets
        : ctrl.allTickets.where((t) {
            if (t.createdAt == null) return false;
            final dt = t.createdAt!;
            final start = DateTime(
              ctrl.rankingPeriodStart!.year,
              ctrl.rankingPeriodStart!.month,
              ctrl.rankingPeriodStart!.day,
            );
            final end = DateTime(
              ctrl.rankingPeriodEnd!.year,
              ctrl.rankingPeriodEnd!.month,
              ctrl.rankingPeriodEnd!.day,
              23,
              59,
              59,
            );
            return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                dt.isBefore(end.add(const Duration(seconds: 1)));
          }).toList();

    final ranking = ctrl.buildRanking(dataForRanking);

    final isMobile = MediaQuery.of(context).size.width < 600;
    final viewMode = isMobile ? RankingViewMode.compact : ctrl.rankingViewMode;

    return Column(
      children: [
        TicketRankingMonthBar(
          ctrl: ctrl,
          allTickets: ctrl.allTickets,
          onChanged: onFilterChanged,
        ),
        Expanded(
          child: ranking.isEmpty
              ? const TicketEmptyState(
                  message: 'Tidak ada data ranking',
                  subtitle: 'Belum ada tiket pada periode ini',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    RankingSummaryRow(data: dataForRanking),
                    const SizedBox(height: 10),
                    RankingInsightBar(
                      ranking: ranking,
                      totalTickets: dataForRanking.length,
                      // Pass screen width or just check inside if needed
                    ),
                    const SizedBox(height: 14),
                    RankingHeaderBar(ctrl: ctrl),
                    const SizedBox(height: 10),
                    if (viewMode == RankingViewMode.compact)
                      ...ranking.asMap().entries.map(
                            (e) => CompactRankCard(
                              index: e.key,
                              item: e.value,
                              ctrl: ctrl,
                            ),
                          )
                    else
                      TableRankView(ranking: ranking, ctrl: ctrl),
                  ],
                ),
        ),
      ],
    );
  }
}
