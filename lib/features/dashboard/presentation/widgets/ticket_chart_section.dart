import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../dashboard_controller.dart';

/// Ticket analytics chart section with area chart + insights + quick filters.
class TicketChartSection extends StatelessWidget {
  const TicketChartSection({super.key, required this.ctrl});
  final DashboardController ctrl;

  static const _filters = [
    (7, '7D'), (30, '30D'), (90, '3M'), (365, '1Y'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = ctrl.dailyChartData;
    final change = ctrl.ticketChangePercent;
    final isUp = change > 0;

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
          // ── Header + filters ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 450;
              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 16, color: context.accentColor),
                        const SizedBox(width: 8),
                        Text('TICKET ANALYTICS', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: context.textSecondary, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _filters.map((f) => _FilterChip(
                        label: f.$2,
                        isActive: ctrl.chartDays == f.$1,
                        onTap: () => ctrl.setChartDays(f.$1),
                      )).toList(),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 16, color: context.accentColor),
                  const SizedBox(width: 8),
                  Text('TICKET ANALYTICS', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: context.textSecondary, letterSpacing: 1.5)),
                  const Spacer(),
                  ..._filters.map((f) => _FilterChip(
                    label: f.$2,
                    isActive: ctrl.chartDays == f.$1,
                    onTap: () => ctrl.setChartDays(f.$1),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Insight row ──
          _InsightRow(ctrl: ctrl, change: change, isUp: isUp),
          const SizedBox(height: 20),

          // ── Chart ──
          SizedBox(
            height: 220,
            child: data.isEmpty
                ? Center(child: Text('Tidak ada data', style: TextStyle(
                    color: context.textSecondary, fontSize: 12)))
                : _buildChart(context, data),
          ),

          const SizedBox(height: 12),

          // ── Legend ──
          _ChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<Map<String, dynamic>> data) {
    final openColor = const Color(0xFFFF6B6B);
    final progressColor = const Color(0xFFFFA726);
    final resolvedColor = const Color(0xFF00E676);

    // Sample data to avoid too many points
    final sampled = _sampleData(data, maxPoints: 30);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(
            color: context.borderColor.withOpacity(0.15),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: TextStyle(fontSize: 9, color: context.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (sampled.length / 6).ceilToDouble().clamp(1, 100),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= sampled.length) return const SizedBox.shrink();
                final date = sampled[i]['date'] as String;
                final parts = date.split('-');
                return Text('${parts[2]}/${parts[1]}',
                  style: TextStyle(fontSize: 8, color: context.textSecondary));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => context.cardColor.withOpacity(0.95),
            tooltipBorder: BorderSide(color: context.borderColor.withOpacity(0.3)),
            getTooltipItems: (spots) => spots.map((s) {
              final colors = [openColor, progressColor, resolvedColor];
              final labels = ['Open', 'Progress', 'Resolved'];
              return LineTooltipItem(
                '${labels[s.barIndex]}: ${s.y.toInt()}',
                TextStyle(fontSize: 10, color: colors[s.barIndex], fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          _buildLine(sampled, 'open', openColor),
          _buildLine(sampled, 'progress', progressColor),
          _buildLine(sampled, 'resolved', resolvedColor),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  LineChartBarData _buildLine(List<Map<String, dynamic>> data, String key, Color color) {
    return LineChartBarData(
      spots: List.generate(data.length, (i) =>
        FlSpot(i.toDouble(), (data[i][key] as int).toDouble())),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }

  List<Map<String, dynamic>> _sampleData(List<Map<String, dynamic>> data, {int maxPoints = 30}) {
    if (data.length <= maxPoints) return data;
    final step = data.length / maxPoints;
    return List.generate(maxPoints, (i) => data[(i * step).floor().clamp(0, data.length - 1)]);
  }
}

// ── Filter chip ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? context.accentColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? context.accentColor.withOpacity(0.4) : context.borderColor.withOpacity(0.3)),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? context.accentColor : context.textSecondary)),
        ),
      ),
    );
  }
}

// ── Insight row ─────────────────────────────────────────────────────────────
class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.ctrl, required this.change, required this.isUp});
  final DashboardController ctrl;
  final double change;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _InsightCard(
                label: 'Open',
                value: '${ctrl.openTickets}',
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(width: 10),
              _InsightCard(
                label: 'In Progress',
                value: '${ctrl.inProgressTickets}',
                color: const Color(0xFFFFA726),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InsightCard(
                label: 'Resolved',
                value: '${ctrl.resolvedTickets}',
                color: const Color(0xFF00E676),
              ),
              const SizedBox(width: 10),
              _InsightCard(
                label: 'Trend',
                value: '${change.abs().toStringAsFixed(0)}%',
                color: isUp ? const Color(0xFFFF6B6B) : const Color(0xFF00E676),
                icon: isUp ? Icons.trending_up : Icons.trending_down,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _InsightCard(
          label: 'Open',
          value: '${ctrl.openTickets}',
          color: const Color(0xFFFF6B6B),
        ),
        const SizedBox(width: 10),
        _InsightCard(
          label: 'In Progress',
          value: '${ctrl.inProgressTickets}',
          color: const Color(0xFFFFA726),
        ),
        const SizedBox(width: 10),
        _InsightCard(
          label: 'Resolved',
          value: '${ctrl.resolvedTickets}',
          color: const Color(0xFF00E676),
        ),
        const SizedBox(width: 10),
        _InsightCard(
          label: 'Trend',
          value: '${change.abs().toStringAsFixed(0)}%',
          color: isUp ? const Color(0xFFFF6B6B) : const Color(0xFF00E676),
          icon: isUp ? Icons.trending_up : Icons.trending_down,
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.label, required this.value, required this.color, this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
            fontSize: 9, color: context.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(value, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ]),
        ]),
      ),
    );
  }
}

// ── Legend ───────────────────────────────────────────────────────────────────
class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: const Color(0xFFFF6B6B), label: 'Open'),
        const SizedBox(width: 16),
        _LegendDot(color: const Color(0xFFFFA726), label: 'In Progress'),
        const SizedBox(width: 16),
        _LegendDot(color: const Color(0xFF00E676), label: 'Resolved'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w500)),
    ]);
  }
}
