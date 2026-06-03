import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/ticket_model.dart';
import '../../presentation/ticket_controller.dart';
import 'period_filter_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TicketFilterPanel — enterprise filter bar with period date picker
// ─────────────────────────────────────────────────────────────────────────────
class TicketFilterPanel extends StatelessWidget {
  const TicketFilterPanel({
    super.key,
    required this.ctrl,
    required this.allTickets,
    required this.onChanged,
  });

  final TicketController ctrl;
  final List<TicketModel> allTickets;
  final VoidCallback onChanged;

  void _resetAll() {
    ctrl.filterStatus = 'Semua';
    ctrl.filterProvider = 'Semua';
    ctrl.filterNoTiket = false;
    ctrl.clearPeriodFilter();
    ctrl.searchCtrl.clear();
    ctrl.applyFilter();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.screenWidth < 850;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(color: context.borderColor.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Search + Period Date Filter (right-aligned) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: isMobile
                ? _buildMobileTopRow(context)
                : _buildDesktopTopRow(context),
          ),
          const SizedBox(height: 8),

          // ── Row 2: Status + Provider + Active indicator ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isMobile
                ? _buildMobileFilters(context)
                : _buildDesktopFilters(context),
          ),

          // ── Row 4: Period indicator ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: _buildSummaryRow(context),
          ),
        ],
      ),
    );
  }

  // ── Desktop: Search left + Period date filter right ──
  Widget _buildDesktopTopRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _SearchField(ctrl: ctrl)),
        if (ctrl.hasAnyFilter) ...[
          const SizedBox(width: 10),
          _ResetButton(onTap: _resetAll),
        ],
        const SizedBox(width: 16),
        PeriodDateFilter(ctrl: ctrl, onChanged: onChanged),
      ],
    );
  }

  // ── Mobile: Search on top, period filter below ──
  Widget _buildMobileTopRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SearchField(ctrl: ctrl)),
            if (ctrl.hasAnyFilter) ...[
              const SizedBox(width: 10),
              _ResetButton(onTap: _resetAll),
            ],
          ],
        ),
        const SizedBox(height: 8),
        PeriodDateFilterCompact(ctrl: ctrl, onChanged: onChanged),
      ],
    );
  }

  // ── Desktop filters: status chips + provider inline
  Widget _buildDesktopFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TicketController.statuses.map((s) {
                return _StatusChip(
                  label: s,
                  isSelected: ctrl.filterStatus == s,
                  color: s == 'Semua'
                      ? context.accentColor
                      : TicketController.statusColor(s),
                  onTap: () {
                    ctrl.filterStatus = s;
                    ctrl.applyFilter();
                    onChanged();
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _NoTiketChip(ctrl: ctrl, onChanged: onChanged),
        const SizedBox(width: 8),
        _ProviderDropdown(ctrl: ctrl, onChanged: onChanged),
      ],
    );
  }

  // ── Mobile filters: stacked
  Widget _buildMobileFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: TicketController.statuses.map((s) {
                return _StatusChip(
                  label: s,
                  isSelected: ctrl.filterStatus == s,
                  color: s == 'Semua'
                      ? context.accentColor
                      : TicketController.statusColor(s),
                  onTap: () {
                    ctrl.filterStatus = s;
                    ctrl.applyFilter();
                    onChanged();
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _NoTiketChip(ctrl: ctrl, onChanged: onChanged),
            const SizedBox(width: 8),
            _ProviderDropdown(ctrl: ctrl, onChanged: onChanged),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Summary row with period indicator + active badges
  Widget _buildSummaryRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PeriodIndicator(ctrl: ctrl, onChanged: onChanged),
          if (ctrl.filterStatus != 'Semua') ...[
            const SizedBox(width: 6),
            _ActiveBadge(
              label: ctrl.filterStatus,
              icon: Icons.flag_outlined,
              color: TicketController.statusColor(ctrl.filterStatus),
              onRemove: () {
                ctrl.filterStatus = 'Semua';
                ctrl.applyFilter();
                onChanged();
              },
            ),
          ],
          if (ctrl.filterProvider != 'Semua') ...[
            const SizedBox(width: 6),
            _ActiveBadge(
              label: ctrl.filterProvider,
              icon: Icons.router_outlined,
              color: const Color(0xFF5C9CE6),
              onRemove: () {
                ctrl.filterProvider = 'Semua';
                ctrl.applyFilter();
                onChanged();
              },
            ),
          ],
          if (ctrl.filterNoTiket) ...[
            const SizedBox(width: 6),
            _ActiveBadge(
              label: 'No Tiket Kosong',
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFFFA726),
              onRemove: () {
                ctrl.toggleNoTiketFilter(false);
                onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Search field ───────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField({required this.ctrl});
  final TicketController ctrl;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: context.accentColor.withOpacity(0.3),
          cursorColor: context.accentColor,
          selectionHandleColor: context.accentColor,
        ),
      ),
      child: TextField(
        controller: ctrl.searchCtrl,
        cursorColor: context.accentColor,
        style: TextStyle(fontSize: 12, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari kode toko, nama toko, nomor tiket...',
          hintStyle: TextStyle(fontSize: 11, color: context.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, size: 16, color: context.textSecondary),
          suffixIcon: ctrl.searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 14, color: context.textSecondary),
                  onPressed: () { ctrl.searchCtrl.clear(); ctrl.applyFilter(); },
                )
              : null,
          filled: true,
          fillColor: context.primaryColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.borderColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.accentColor.withOpacity(0.6)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          isDense: true,
        ),
      ),
    );
  }
}

// ─── Status chip ────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? color : color.withOpacity(0.7),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
    );
  }
}

// ─── Provider dropdown ──────────────────────────────────────────────────────
class _ProviderDropdown extends StatelessWidget {
  const _ProviderDropdown({required this.ctrl, required this.onChanged});
  final TicketController ctrl;
  final VoidCallback onChanged;
  static const _c = Color(0xFF5C9CE6);

  @override
  Widget build(BuildContext context) {
    final active = ctrl.filterProvider != 'Semua';
    return PopupMenuButton<String>(
      onSelected: (v) { ctrl.filterProvider = v; ctrl.applyFilter(); onChanged(); },
      offset: const Offset(0, 40),
      color: context.cardColor,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.borderColor.withOpacity(0.5)),
      ),
      constraints: const BoxConstraints(minWidth: 160),
      itemBuilder: (_) => TicketController.providers.map((p) {
        final sel = ctrl.filterProvider == p;
        return PopupMenuItem<String>(value: p, height: 36, child: Row(children: [
          Icon(p == 'Semua' ? Icons.router_outlined : Icons.wifi_tethering, size: 13, color: sel ? _c : context.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(p, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? _c : context.textPrimary))),
          if (sel) Icon(Icons.check_rounded, size: 14, color: _c),
        ]));
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _c.withOpacity(0.06) : context.primaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _c.withOpacity(0.3) : context.borderColor.withOpacity(0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.router_outlined, size: 13, color: active ? _c : context.textSecondary),
          const SizedBox(width: 5),
          Text(ctrl.filterProvider, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? _c : context.textPrimary)),
          const SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: active ? _c : context.textSecondary),
        ]),
      ),
    );
  }
}

// ─── Reset button ───────────────────────────────────────────────────────────
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.15)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.filter_alt_off_rounded, size: 12, color: Colors.red.shade400),
            const SizedBox(width: 4),
            Text('Reset', style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ─── Active filter badge ────────────────────────────────────────────────────
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.label, required this.icon, required this.color, required this.onRemove});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 5, 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.close_rounded, size: 9, color: color),
          ),
        ),
      ]),
    );
  }
}

// ─── No Tiket filter chip ───────────────────────────────────────────────────
class _NoTiketChip extends StatelessWidget {
  const _NoTiketChip({required this.ctrl, required this.onChanged});
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = ctrl.filterNoTiket;
    final color = isActive ? const Color(0xFFFFA726) : context.textSecondary;
    final w = context.screenWidth;

    // Responsive label: desktop full, tablet short, mobile icon-only
    final String? label = w >= 1200
        ? 'Belum Ada No. Tiket'
        : w >= 850
            ? 'No Tiket Kosong'
            : null; // icon-only on mobile

    return Tooltip(
      message: 'Filter tiket tanpa nomor tiket',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ctrl.toggleNoTiketFilter(!isActive);
            onChanged();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: label != null ? 10 : 7,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? color.withOpacity(0.4)
                    : context.borderColor.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isActive ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 13, color: color),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ranking period bar — independent filter from history tab
// ─────────────────────────────────────────────────────────────────────────────
class TicketRankingMonthBar extends StatelessWidget {
  const TicketRankingMonthBar({
    super.key,
    required this.ctrl,
    required this.allTickets,
    required this.onChanged,
  });
  final TicketController ctrl;
  final List<TicketModel> allTickets;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isFiltered = ctrl.hasRankingPeriodFilter;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final periodLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(
          color: context.accentColor.withOpacity(0.6), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text('PERIODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textSecondary, letterSpacing: 1)),
      ],
    );

    final resetButton = isFiltered
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () { ctrl.clearRankingPeriodFilter(); onChanged(); },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.close_rounded, size: 11, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text('Reset', style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )
        : null;

    if (isMobile) {
      // ── Mobile: Layout vertikal ─────────────────────────────────
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(bottom: BorderSide(color: context.borderColor.withOpacity(0.4))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                periodLabel,
                const Spacer(),
                if (resetButton != null) resetButton,
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RankingPeriodDateFilter(ctrl: ctrl, onChanged: onChanged),
            ),
          ],
        ),
      );
    }

    // ── Desktop: Layout horizontal (original) ──────────────────
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          periodLabel,
          const Spacer(),
          RankingPeriodDateFilter(ctrl: ctrl, onChanged: onChanged),
          if (resetButton != null) ...[
            const SizedBox(width: 8),
            resetButton,
          ],
        ],
      ),
    );
  }
}

// Keep ActiveFilterBadge public for backward compatibility
class ActiveFilterBadge extends StatelessWidget {
  const ActiveFilterBadge({super.key, required this.label, required this.icon, this.color, required this.onRemove});
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.accentColor;
    return _ActiveBadge(label: label, icon: icon, color: c, onRemove: onRemove);
  }
}
