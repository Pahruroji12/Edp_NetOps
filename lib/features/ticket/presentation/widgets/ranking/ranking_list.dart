import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/ticket_model.dart';
import '../../../presentation/ticket_controller.dart';
import 'ranking_detail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ranking header with view toggle
// ─────────────────────────────────────────────────────────────────────────────

class RankingHeaderBar extends StatelessWidget {
  const RankingHeaderBar({super.key, required this.ctrl});
  final TicketController ctrl;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      children: [
        Icon(
          Icons.emoji_events_outlined,
          size: 13,
          color: context.accentColor.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          'RANKING TOKO',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        if (ctrl.hasRankingPeriodFilter) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              ctrl.displayRankingPeriodLabel,
              style: TextStyle(
                fontSize: 9,
                color: context.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: context.borderColor.withOpacity(0.3),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          // View toggle
          _ViewToggle(
            isCompact: ctrl.rankingViewMode == RankingViewMode.compact,
            onToggle: () => ctrl.toggleRankingView(),
          ),
        ],
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.isCompact, required this.onToggle});
  final bool isCompact;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.borderColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompact
                    ? Icons.view_agenda_outlined
                    : Icons.table_rows_outlined,
                size: 12,
                color: context.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                isCompact ? 'Compact' : 'Table',
                style: TextStyle(
                  fontSize: 10,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact rank card with expandable detail
// ─────────────────────────────────────────────────────────────────────────────
class CompactRankCard extends StatefulWidget {
  const CompactRankCard({
    super.key,
    required this.index,
    required this.item,
    required this.ctrl,
  });
  final int index;
  final Map<String, dynamic> item;
  final TicketController ctrl;

  @override
  State<CompactRankCard> createState() => _CompactRankCardState();
}

class _CompactRankCardState extends State<CompactRankCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    final rank = widget.index + 1;
    final total = widget.item['total'] as int;
    final open = widget.item['open'] as int;
    final inProg = widget.item['in_progress'] as int;
    final resolved = widget.item['resolved'] as int;
    final storeCode = widget.item['store_code'] as String;
    final storeName = widget.item['store_name'] as String;
    final lastIncident = widget.item['last_incident'] as DateTime?;
    final severity = TicketController.calculateSeverity(total, open);
    final sevColor = TicketController.severityColor(severity);
    final medal = _medalColor(rank, context);
    final isExpanded = widget.ctrl.expandedRankItems.contains(storeCode);
    final tickets = widget.item['tickets'] as List<TicketModel>? ?? [];
    final resolvedPct = total > 0 ? (resolved / total * 100).round() : 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _isHovered
              ? context.accentColor.withOpacity(0.03)
              : context.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: rank <= 3
                ? medal.withOpacity(0.2)
                : context.borderColor.withOpacity(0.4),
          ),
        ),
        child: Column(
          children: [
            // Main row
            InkWell(
              onTap: () => widget.ctrl.toggleRankExpansion(storeCode),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Rank badge
                    _RankBadge(rank: rank, medal: medal),
                    const SizedBox(width: 10),

                    // Severity indicator
                    Tooltip(
                      message: TicketController.severityLabel(severity),
                      child: Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sevColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Store info + progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$storeCode — $storeName',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Insight badge
                              if (rank == 1)
                                _InsightBadge(
                                  label: isMobile ? 'Top Issue' : 'Most issue',
                                  color: const Color(0xFFE57373),
                                ),
                              if (open >= 3)
                                _InsightBadge(
                                  label: isMobile ? 'Unstable' : 'Frequently unstable',
                                  color: const Color(0xFFFFB74D),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Thin segmented progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 3,
                              child: Row(
                                children: [
                                  if (open > 0)
                                    Flexible(
                                      flex: open,
                                      child: Container(
                                        color: const Color(0xFFE57373),
                                      ),
                                    ),
                                  if (inProg > 0)
                                    Flexible(
                                      flex: inProg,
                                      child: Container(
                                        color: const Color(0xFFFFB74D),
                                      ),
                                    ),
                                  if (resolved > 0)
                                    Flexible(
                                      flex: resolved,
                                      child: Container(
                                        color: const Color(0xFF81C784),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _DotLabel(
                                  'Open: $open', const Color(0xFFE57373)),
                              _DotLabel(
                                'Progress: $inProg',
                                const Color(0xFFFFB74D),
                              ),
                              _DotLabel(
                                'Resolved: $resolved',
                                const Color(0xFF81C784),
                              ),
                              if (lastIncident != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'Last: ${DateFormat('dd MMM').format(lastIncident)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Total badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$total',
                            style: TextStyle(
                              color: context.accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'tiket',
                            style: TextStyle(
                              color: context.accentColor.withOpacity(0.7),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Expand icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: context.textSecondary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable detail section
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: RankingExpandedDetail(
                item: widget.item,
                tickets: tickets,
                resolvedPct: resolvedPct,
                ctrl: widget.ctrl,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }

  static Color _medalColor(int rank, BuildContext context) => switch (rank) {
        1 => const Color(0xFFFFD54F),
        2 => const Color(0xFFB0BEC5),
        3 => const Color(0xFFCD7F32),
        _ => context.textSecondary.withOpacity(0.5),
      };
}

// ── Rank badge ──────────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.medal});
  final int rank;
  final Color medal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: medal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: rank <= 3
            ? Icon(Icons.emoji_events_rounded, color: medal, size: 16)
            : Text(
                '$rank',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ── Insight badge ───────────────────────────────────────────────────────────
class _InsightBadge extends StatelessWidget {
  const _InsightBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Dot label ───────────────────────────────────────────────────────────────
class _DotLabel extends StatelessWidget {
  const _DotLabel(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table view for ranking
// ─────────────────────────────────────────────────────────────────────────────
class TableRankView extends StatelessWidget {
  const TableRankView({
    super.key,
    required this.ranking,
    required this.ctrl,
  });
  final List<Map<String, dynamic>> ranking;
  final TicketController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border(
                bottom:
                    BorderSide(color: context.borderColor.withOpacity(0.4)),
              ),
            ),
            child: Row(
              children: [
                _thCell('#', width: 32),
                _thCell('Severity', width: 60),
                Expanded(flex: 3, child: _thText(context, 'Toko')),
                _thCell('Total', width: 50),
                _thCell('Open', width: 50),
                _thCell('Prog', width: 50),
                _thCell('Done', width: 50),
                _thCell('Last', width: 80),
              ],
            ),
          ),
          // Table rows
          ...ranking.asMap().entries.map((e) {
            final rank = e.key + 1;
            final item = e.value;
            final total = item['total'] as int;
            final open = item['open'] as int;
            final inProg = item['in_progress'] as int;
            final resolved = item['resolved'] as int;
            final severity =
                TicketController.calculateSeverity(total, open);
            final sevColor = TicketController.severityColor(severity);
            final lastIncident = item['last_incident'] as DateTime?;

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.borderColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sevColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        TicketController.severityLabel(severity),
                        style: TextStyle(
                          fontSize: 9,
                          color: sevColor,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item['store_code']} — ${item['store_name']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$open',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFE57373),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$inProg',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFFFB74D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$resolved',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF81C784),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      lastIncident != null
                          ? DateFormat('dd MMM yy').format(lastIncident)
                          : '-',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _thCell(String label, {required double width}) {
    return Builder(
      builder: (context) =>
          SizedBox(width: width, child: _thText(context, label)),
    );
  }

  Widget _thText(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: context.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}
