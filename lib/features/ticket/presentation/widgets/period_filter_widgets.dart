import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../presentation/ticket_controller.dart';
import 'custom_calendar_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PeriodDateFilter — "PERIOD START" / "PERIOD END" + Apply button
// Uses custom dark-themed calendar popup
// ─────────────────────────────────────────────────────────────────────────────
class PeriodDateFilter extends StatefulWidget {
  const PeriodDateFilter({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  State<PeriodDateFilter> createState() => _PeriodDateFilterState();
}

class _PeriodDateFilterState extends State<PeriodDateFilter> {
  late DateTime _periodStart;
  late DateTime _periodEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = widget.ctrl.periodStart ?? now;
    _periodEnd = widget.ctrl.periodEnd ?? now;
  }

  @override
  void didUpdateWidget(covariant PeriodDateFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ctrl.periodStart != null) _periodStart = widget.ctrl.periodStart!;
    if (widget.ctrl.periodEnd != null) _periodEnd = widget.ctrl.periodEnd!;
  }

  void _applyFilter() {
    widget.ctrl.setPeriodRange(_periodStart, _periodEnd);
    widget.onChanged();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _periodStart : _periodEnd;
    final picked = await CustomCalendarPopup.show(
      context: context,
      initialDate: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
          if (_periodStart.isAfter(_periodEnd)) _periodEnd = _periodStart;
        } else {
          _periodEnd = picked;
          if (_periodEnd.isBefore(_periodStart)) _periodStart = _periodEnd;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/dd/yyyy');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DateInputField(
          label: 'PERIOD START',
          value: fmt.format(_periodStart),
          onTap: () => _pickDate(true),
        ),
        const SizedBox(width: 10),
        _DateInputField(
          label: 'PERIOD END',
          value: fmt.format(_periodEnd),
          onTap: () => _pickDate(false),
        ),
        const SizedBox(width: 10),
        _ApplyButton(onTap: _applyFilter),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PeriodDateFilterCompact — for mobile/narrow layouts (stacked)
// ─────────────────────────────────────────────────────────────────────────────
class PeriodDateFilterCompact extends StatefulWidget {
  const PeriodDateFilterCompact({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  State<PeriodDateFilterCompact> createState() => _PeriodDateFilterCompactState();
}

class _PeriodDateFilterCompactState extends State<PeriodDateFilterCompact> {
  late DateTime _periodStart;
  late DateTime _periodEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = widget.ctrl.periodStart ?? now;
    _periodEnd = widget.ctrl.periodEnd ?? now;
  }

  @override
  void didUpdateWidget(covariant PeriodDateFilterCompact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ctrl.periodStart != null) _periodStart = widget.ctrl.periodStart!;
    if (widget.ctrl.periodEnd != null) _periodEnd = widget.ctrl.periodEnd!;
  }

  void _applyFilter() {
    widget.ctrl.setPeriodRange(_periodStart, _periodEnd);
    widget.onChanged();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _periodStart : _periodEnd;
    final picked = await CustomCalendarPopup.show(
      context: context,
      initialDate: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
          if (_periodStart.isAfter(_periodEnd)) _periodEnd = _periodStart;
        } else {
          _periodEnd = picked;
          if (_periodEnd.isBefore(_periodStart)) _periodStart = _periodEnd;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/dd/yyyy');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        _DateInputField(
          label: 'PERIOD START',
          value: fmt.format(_periodStart),
          onTap: () => _pickDate(true),
        ),
        _DateInputField(
          label: 'PERIOD END',
          value: fmt.format(_periodEnd),
          onTap: () => _pickDate(false),
        ),
        _ApplyButton(onTap: _applyFilter),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RankingPeriodDateFilter — independent period filter for ranking tab
// ─────────────────────────────────────────────────────────────────────────────
class RankingPeriodDateFilter extends StatefulWidget {
  const RankingPeriodDateFilter({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  State<RankingPeriodDateFilter> createState() => _RankingPeriodDateFilterState();
}

class _RankingPeriodDateFilterState extends State<RankingPeriodDateFilter> {
  late DateTime _periodStart;
  late DateTime _periodEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = widget.ctrl.rankingPeriodStart ?? now;
    _periodEnd = widget.ctrl.rankingPeriodEnd ?? now;
  }

  @override
  void didUpdateWidget(covariant RankingPeriodDateFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ctrl.rankingPeriodStart != null) _periodStart = widget.ctrl.rankingPeriodStart!;
    if (widget.ctrl.rankingPeriodEnd != null) _periodEnd = widget.ctrl.rankingPeriodEnd!;
  }

  void _applyFilter() {
    widget.ctrl.setRankingPeriodRange(_periodStart, _periodEnd);
    widget.onChanged();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _periodStart : _periodEnd;
    final picked = await CustomCalendarPopup.show(
      context: context,
      initialDate: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
          if (_periodStart.isAfter(_periodEnd)) _periodEnd = _periodStart;
        } else {
          _periodEnd = picked;
          if (_periodEnd.isBefore(_periodStart)) _periodStart = _periodEnd;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/dd/yyyy');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DateInputField(
          label: 'PERIOD START',
          value: fmt.format(_periodStart),
          onTap: () => _pickDate(true),
        ),
        const SizedBox(width: 10),
        _DateInputField(
          label: 'PERIOD END',
          value: fmt.format(_periodEnd),
          onTap: () => _pickDate(false),
        ),
        const SizedBox(width: 10),
        _ApplyButton(onTap: _applyFilter),
      ],
    );
  }
}

// ─── Date input field ───────────────────────────────────────────────────────
class _DateInputField extends StatefulWidget {
  const _DateInputField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  State<_DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<_DateInputField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: context.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isHovered
                      ? context.accentColor.withOpacity(0.5)
                      : context.borderColor.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.value, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: context.textPrimary, fontFamily: 'monospace')),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_rounded, size: 13,
                  color: _isHovered ? context.accentColor : context.textSecondary),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Apply button ───────────────────────────────────────────────────────────
class _ApplyButton extends StatefulWidget {
  const _ApplyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _isHovered
                    ? [context.accentColor, context.accentColor.withOpacity(0.8)]
                    : [context.accentColor.withOpacity(0.9), context.accentColor.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isHovered
                    ? [BoxShadow(color: context.accentColor.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.filter_alt_rounded, size: 13, color: Colors.white),
                SizedBox(width: 5),
                Text('Apply', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Period indicator badge ─────────────────────────────────────────────────
class PeriodIndicator extends StatelessWidget {
  const PeriodIndicator({super.key, required this.ctrl, required this.onChanged});
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('${ctrl.filteredTickets.length}', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800, color: context.accentColor)),
        const SizedBox(width: 6),
        Text(ctrl.displayPeriodLabel, style: TextStyle(
          fontSize: 10, color: context.textSecondary, fontStyle: FontStyle.italic)),
        if (ctrl.hasPeriodFilter) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () { ctrl.clearPeriodFilter(); onChanged(); },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, size: 10, color: Colors.red.shade400),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Legacy: MonthDropdown (kept for ranking tab) ───────────────────────────
class MonthDropdown extends StatelessWidget {
  const MonthDropdown({super.key, required this.ctrl, required this.onChanged});
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final active = ctrl.filterMonth != null;
    final label = active ? TicketController.monthNamesShort[ctrl.filterMonth! - 1] : 'Bulan';
    return _FilterDropdown(
      icon: Icons.calendar_today_outlined, label: label,
      isActive: active, activeColor: context.accentColor,
      items: [
        _dropItem(context, null, 'Semua Bulan', ctrl.filterMonth == null),
        ...List.generate(12, (i) => _dropItem(
          context, i + 1, TicketController.monthNames[i], ctrl.filterMonth == i + 1)),
      ],
      onSelected: (v) { ctrl.setFilterMonth(v as int?); onChanged(); },
    );
  }

  PopupMenuEntry<Object?> _dropItem(BuildContext ctx, int? value, String label, bool selected) {
    return PopupMenuItem<Object?>(value: value, height: 36, child: Row(children: [
      if (value != null) SizedBox(width: 20, child: Text('$value', style: TextStyle(fontSize: 10, color: ctx.textSecondary))),
      if (value != null) const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: selected ? ctx.accentColor : ctx.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
      if (selected) Icon(Icons.check_rounded, size: 14, color: ctx.accentColor),
    ]));
  }
}

// ─── Legacy: YearDropdown (kept for ranking tab) ────────────────────────────
class YearDropdown extends StatelessWidget {
  const YearDropdown({super.key, required this.ctrl, required this.onChanged});
  final TicketController ctrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final active = ctrl.filterYear != null;
    final label = active ? '${ctrl.filterYear}' : 'Tahun';
    final years = ctrl.availableYears();
    return _FilterDropdown(
      icon: Icons.date_range_outlined, label: label,
      isActive: active, activeColor: context.accentColor,
      items: [
        PopupMenuItem<Object?>(value: null, height: 36, child: Row(children: [
          Expanded(child: Text('Semua Tahun', style: TextStyle(fontSize: 12, color: ctrl.filterYear == null ? context.accentColor : context.textPrimary, fontWeight: ctrl.filterYear == null ? FontWeight.w700 : FontWeight.w500))),
          if (ctrl.filterYear == null) Icon(Icons.check_rounded, size: 14, color: context.accentColor),
        ])),
        ...years.map((y) => PopupMenuItem<Object?>(value: y, height: 36, child: Row(children: [
          Expanded(child: Text('$y', style: TextStyle(fontSize: 12, color: ctrl.filterYear == y ? context.accentColor : context.textPrimary, fontWeight: ctrl.filterYear == y ? FontWeight.w700 : FontWeight.w500))),
          if (ctrl.filterYear == y) Icon(Icons.check_rounded, size: 14, color: context.accentColor),
        ]))),
      ],
      onSelected: (v) { ctrl.setFilterYear(v as int?); onChanged(); },
    );
  }
}

// ─── Shared filter dropdown shell ───────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.icon, required this.label, required this.isActive,
    required this.activeColor, required this.items, required this.onSelected,
  });
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final List<PopupMenuEntry<Object?>> items;
  final void Function(Object?) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object?>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      color: context.cardColor, elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.borderColor.withOpacity(0.5))),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.06) : context.primaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? activeColor.withOpacity(0.3) : context.borderColor.withOpacity(0.5))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: isActive ? activeColor : context.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: isActive ? activeColor : context.textPrimary)),
          const SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14,
            color: isActive ? activeColor : context.textSecondary),
        ]),
      ),
    );
  }
}
