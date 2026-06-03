import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../dashboard_controller.dart';

/// Provider disruption chart — bar chart showing ticket counts per provider
/// with a month/year filter selector.
class ProviderChartSection extends StatefulWidget {
  const ProviderChartSection({super.key, required this.ctrl});
  final DashboardController ctrl;

  @override
  State<ProviderChartSection> createState() => _ProviderChartSectionState();
}

class _ProviderChartSectionState extends State<ProviderChartSection> {
  int? _selectedMonth; // null = semua bulan
  int _selectedYear = DateTime.now().year;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const _monthNamesFull = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // Provider colors — consistent with the rest of the app
  static const _providerColors = {
    'Astinet': Color(0xFF4FC3F7),
    'ICON': Color(0xFFBA68C8),
    'Fiberstar': Color(0xFFFFB74D),
  };

  static const _providerIcons = {
    'Astinet': Icons.language_rounded,
    'ICON': Icons.cable_rounded,
    'Fiberstar': Icons.star_rounded,
  };

  /// Calculate smart Y-axis interval to avoid label overlap
  double _smartInterval(double maxVal) {
    if (maxVal <= 5) return 1;
    if (maxVal <= 10) return 2;
    if (maxVal <= 25) return 5;
    if (maxVal <= 50) return 10;
    if (maxVal <= 100) return 20;
    return (maxVal / 5).ceilToDouble();
  }

  /// Get available years from ticket data
  List<int> get _availableYears {
    final years = <int>{};
    for (final t in widget.ctrl.allTickets) {
      if (t.createdAt != null) years.add(t.createdAt!.year);
    }
    if (years.isEmpty) years.add(DateTime.now().year);
    final sorted = years.toList()..sort();
    return sorted;
  }

  /// Build provider stats for the selected period
  Map<String, _ProviderStats> get _providerData {
    final stats = <String, _ProviderStats>{
      'Astinet': _ProviderStats(),
      'ICON': _ProviderStats(),
      'Fiberstar': _ProviderStats(),
    };

    for (final t in widget.ctrl.allTickets) {
      if (t.createdAt == null) continue;
      if (t.createdAt!.year != _selectedYear) continue;
      if (_selectedMonth != null && t.createdAt!.month != _selectedMonth) continue;

      final provider = t.provider;
      if (!stats.containsKey(provider)) continue;

      stats[provider]!.total++;
      switch (t.status) {
        case 'Open':
          stats[provider]!.open++;
        case 'In Progress':
          stats[provider]!.progress++;
        case 'Resolved':
          stats[provider]!.resolved++;
        default:
          stats[provider]!.open++;
      }
    }

    return stats;
  }

  /// Build monthly breakdown for all providers (used in detailed bar chart)
  List<_MonthlyProviderData> get _monthlyBreakdown {
    final data = <int, Map<String, int>>{};

    // Initialize months 1-12
    for (int m = 1; m <= 12; m++) {
      data[m] = {'Astinet': 0, 'ICON': 0, 'Fiberstar': 0};
    }

    for (final t in widget.ctrl.allTickets) {
      if (t.createdAt == null) continue;
      if (t.createdAt!.year != _selectedYear) continue;
      final provider = t.provider;
      if (!data[t.createdAt!.month]!.containsKey(provider)) continue;
      data[t.createdAt!.month]![provider] =
          (data[t.createdAt!.month]![provider] ?? 0) + 1;
    }

    return data.entries
        .map((e) => _MonthlyProviderData(
              month: e.key,
              astinet: e.value['Astinet'] ?? 0,
              icon: e.value['ICON'] ?? 0,
              fiberstar: e.value['Fiberstar'] ?? 0,
            ))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  @override
  Widget build(BuildContext context) {
    final providerData = _providerData;
    final totalAll = providerData.values.fold<int>(0, (s, p) => s + p.total);

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
          // ── Header + Filters ──
          _buildHeader(context),
          const SizedBox(height: 16),

          // ── Provider summary cards ──
          _buildProviderSummary(context, providerData, totalAll),
          const SizedBox(height: 20),

          // ── Bar chart ──
          SizedBox(
            height: 200,
            child: totalAll == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 32,
                            color: context.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text('Tidak ada data gangguan',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                : _selectedMonth != null
                    ? _buildSingleMonthChart(context, providerData)
                    : _buildMonthlyChart(context),
          ),
          const SizedBox(height: 12),

          // ── Legend ──
          _buildLegend(context),
        ],
      ),
    );
  }

  // ── Header with title + month/year filter ──
  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 450;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.router_outlined,
                      size: 16, color: context.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('GANGGUAN PER PROVIDER',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondary,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildFilterRow(context),
              ),
            ],
          );
        }

        return Row(
          children: [
            Icon(Icons.router_outlined, size: 16, color: context.accentColor),
            const SizedBox(width: 8),
            Text('GANGGUAN PER PROVIDER',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    letterSpacing: 1.5)),
            const Spacer(),
            _buildFilterRow(context),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Year selector
        _buildDropdown(
          context: context,
          icon: Icons.calendar_today_rounded,
          value: '$_selectedYear',
          items: _availableYears.map((y) => '$y').toList(),
          onSelected: (v) => setState(() => _selectedYear = int.parse(v)),
        ),
        const SizedBox(width: 6),
        // Month selector
        _buildDropdown(
          context: context,
          icon: Icons.date_range_rounded,
          value:
              _selectedMonth != null ? _monthNames[_selectedMonth! - 1] : 'Semua',
          items: ['Semua', ..._monthNames],
          onSelected: (v) {
            setState(() {
              if (v == 'Semua') {
                _selectedMonth = null;
              } else {
                _selectedMonth = _monthNames.indexOf(v) + 1;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 36),
      color: context.cardColor,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.borderColor.withOpacity(0.5)),
      ),
      constraints: const BoxConstraints(minWidth: 120),
      itemBuilder: (_) => items.map((item) {
        final isSelected = item == value;
        return PopupMenuItem<String>(
          value: item,
          height: 34,
          child: Row(
            children: [
              Expanded(
                child: Text(item,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? context.accentColor
                            : context.textPrimary)),
              ),
              if (isSelected)
                Icon(Icons.check_rounded,
                    size: 14, color: context.accentColor),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: context.accentColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: context.accentColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: context.accentColor),
            const SizedBox(width: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.accentColor)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: context.accentColor),
          ],
        ),
      ),
    );
  }

  // ── Provider summary cards ──
  Widget _buildProviderSummary(
      BuildContext context, Map<String, _ProviderStats> data, int totalAll) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: data.entries.map((e) {
            final name = e.key;
            final stats = e.value;
            final color = _providerColors[name] ?? context.accentColor;
            final icon = _providerIcons[name] ?? Icons.wifi_tethering;
            final pct = totalAll > 0 ? (stats.total / totalAll * 100) : 0.0;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: name != data.keys.last ? 8 : 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 13, color: color),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${stats.total}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: color)),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color.withOpacity(0.7))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Mini status bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 3,
                        child: stats.total > 0
                            ? Row(children: [
                                if (stats.open > 0)
                                  Expanded(
                                      flex: stats.open,
                                      child: Container(
                                          color: const Color(0xFFFF6B6B))),
                                if (stats.progress > 0)
                                  Expanded(
                                      flex: stats.progress,
                                      child: Container(
                                          color: const Color(0xFFFFA726))),
                                if (stats.resolved > 0)
                                  Expanded(
                                      flex: stats.resolved,
                                      child: Container(
                                          color: const Color(0xFF00E676))),
                              ])
                            : Container(
                                color:
                                    context.borderColor.withOpacity(0.2)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Single month bar chart (when a specific month is selected) ──
  Widget _buildSingleMonthChart(
      BuildContext context, Map<String, _ProviderStats> data) {
    final providers = data.keys.toList();
    final maxVal = data.values
        .fold<int>(0, (m, s) => s.total > m ? s.total : m)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: (maxVal + 2).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.cardColor.withOpacity(0.95),
            tooltipBorder:
                BorderSide(color: context.borderColor.withOpacity(0.3)),
            getTooltipItem: (group, gIdx, rod, rIdx) {
              final xInt = group.x.toInt();
              if (xInt < 0 || xInt >= providers.length) return null;
              final provider = providers[xInt];
              final stats = data[provider];
              if (stats == null) return null;
              return BarTooltipItem(
                '$provider\n',
                TextStyle(
                    color: _providerColors[provider] ?? context.accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11),
                children: [
                  TextSpan(
                    text:
                        'Total: ${stats.total}  O:${stats.open} P:${stats.progress} R:${stats.resolved}',
                    style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _smartInterval(maxVal),
              getTitlesWidget: (v, _) {
                if (v != v.roundToDouble()) return const SizedBox.shrink();
                return Text('${v.toInt()}',
                    style:
                        TextStyle(fontSize: 9, color: context.textSecondary));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= providers.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(providers[i],
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _providerColors[providers[i]] ??
                              context.textSecondary)),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _smartInterval(maxVal),
          getDrawingHorizontalLine: (v) => FlLine(
            color: context.borderColor.withOpacity(0.12),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: providers.asMap().entries.map((e) {
          final idx = e.key;
          final name = e.value;
          final stats = data[name]!;
          final color = _providerColors[name] ?? context.accentColor;

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: stats.total.toDouble(),
                width: 28,
                color: color.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (maxVal + 2).ceilToDouble(),
                  color: color.withOpacity(0.04),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      duration: Duration.zero,
    );
  }

  // ── Monthly grouped bar chart (when "Semua" month is selected) ──
  Widget _buildMonthlyChart(BuildContext context) {
    final data = _monthlyBreakdown;
    final maxVal = data.fold<int>(0, (m, d) {
      final monthMax = [d.astinet, d.icon, d.fiberstar]
          .fold<int>(0, (a, b) => b > a ? b : a);
      return monthMax > m ? monthMax : m;
    }).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: (maxVal + 2).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.cardColor.withOpacity(0.95),
            tooltipBorder:
                BorderSide(color: context.borderColor.withOpacity(0.3)),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, gIdx, rod, rIdx) {
              final xInt = group.x.toInt();
              if (xInt < 0 || xInt >= _monthNames.length) return null;
              final month = _monthNames[xInt];
              final providers = ['Astinet', 'ICON', 'Fiberstar'];
              if (rIdx < 0 || rIdx >= providers.length) return null;
              final colors = [
                _providerColors['Astinet']!,
                _providerColors['ICON']!,
                _providerColors['Fiberstar']!,
              ];
              return BarTooltipItem(
                '$month\n',
                TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11),
                children: [
                  TextSpan(
                    text: '${providers[rIdx]}: ${rod.toY.toInt()}',
                    style: TextStyle(
                        color: colors[rIdx],
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _smartInterval(maxVal),
              getTitlesWidget: (v, _) {
                if (v != v.roundToDouble()) return const SizedBox.shrink();
                return Text('${v.toInt()}',
                    style:
                        TextStyle(fontSize: 9, color: context.textSecondary));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= 12) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_monthNames[i],
                      style: TextStyle(
                          fontSize: 8, color: context.textSecondary)),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _smartInterval(maxVal),
          getDrawingHorizontalLine: (v) => FlLine(
            color: context.borderColor.withOpacity(0.12),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.map((d) {
          return BarChartGroupData(
            x: d.month - 1,
            barsSpace: 2,
            barRods: [
              BarChartRodData(
                toY: d.astinet.toDouble(),
                width: 6,
                color: _providerColors['Astinet']!.withOpacity(0.85),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: d.icon.toDouble(),
                width: 6,
                color: _providerColors['ICON']!.withOpacity(0.85),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: d.fiberstar.toDouble(),
                width: 6,
                color: _providerColors['Fiberstar']!.withOpacity(0.85),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }).toList(),
      ),
      duration: Duration.zero,
    );
  }

  // ── Legend ──
  Widget _buildLegend(BuildContext context) {
    final periodLabel = _selectedMonth != null
        ? '${_monthNamesFull[_selectedMonth! - 1]} $_selectedYear'
        : 'Tahun $_selectedYear';

    return Row(
      children: [
        // Period indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.accentColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 10, color: context.accentColor.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(periodLabel,
                  style: TextStyle(
                      fontSize: 9,
                      color: context.accentColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const Spacer(),
        // Provider dots
        ..._providerColors.entries.map((e) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: e.value,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Text(e.key,
                      style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Helper data classes ─────────────────────────────────────────────────────
class _ProviderStats {
  int total = 0;
  int open = 0;
  int progress = 0;
  int resolved = 0;
}

class _MonthlyProviderData {
  final int month;
  final int astinet;
  final int icon;
  final int fiberstar;

  const _MonthlyProviderData({
    required this.month,
    required this.astinet,
    required this.icon,
    required this.fiberstar,
  });
}
