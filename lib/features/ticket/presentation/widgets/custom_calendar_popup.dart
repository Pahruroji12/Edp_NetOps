import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Professional dark-themed calendar popup with month/year picker.
class CustomCalendarPopup {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CalendarDialog(
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
        parentContext: context,
      ),
    );
  }
}

enum _ViewMode { day, month, year }

class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.parentContext,
  });
  final DateTime initialDate, firstDate, lastDate;
  final BuildContext parentContext;

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog>
    with SingleTickerProviderStateMixin {
  late DateTime _viewMonth;
  late DateTime _selected;
  late int _yearPageStart;
  _ViewMode _mode = _ViewMode.day;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  static const _dayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  static const _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _viewMonth = DateTime(_selected.year, _selected.month);
    _yearPageStart = (_selected.year ~/ 12) * 12;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color get _accent => widget.parentContext.accentColor;
  Color get _bg => widget.parentContext.cardColor;
  Color get _border => widget.parentContext.borderColor;
  Color get _textP => widget.parentContext.textPrimary;
  Color get _textS => widget.parentContext.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4),
                    blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (_mode == _ViewMode.day) ...[
                  _buildDayLabels(),
                  _buildDayGrid(),
                ] else if (_mode == _ViewMode.month)
                  _buildMonthGrid()
                else
                  _buildYearGrid(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    String title;
    switch (_mode) {
      case _ViewMode.day:
        title = '${_monthShort[_viewMonth.month - 1]} ${_viewMonth.year}';
      case _ViewMode.month:
        title = '${_viewMonth.year}';
      case _ViewMode.year:
        title = '$_yearPageStart — ${_yearPageStart + 11}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _onHeaderTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: TextStyle(
                    color: _textP, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down, size: 18, color: _textS),
              ]),
            ),
          ),
          const Spacer(),
          _navBtn(Icons.keyboard_arrow_up_rounded, _onNavUp),
          const SizedBox(width: 2),
          _navBtn(Icons.keyboard_arrow_down_rounded, _onNavDown),
        ],
      ),
    );
  }

  void _onHeaderTap() {
    setState(() {
      if (_mode == _ViewMode.day) {
        _mode = _ViewMode.month;
      } else if (_mode == _ViewMode.month) {
        _mode = _ViewMode.year;
      } else {
        _mode = _ViewMode.day;
      }
    });
  }

  void _onNavUp() {
    setState(() {
      switch (_mode) {
        case _ViewMode.day:
          _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
        case _ViewMode.month:
          _viewMonth = DateTime(_viewMonth.year - 1, _viewMonth.month);
        case _ViewMode.year:
          _yearPageStart -= 12;
      }
    });
  }

  void _onNavDown() {
    setState(() {
      switch (_mode) {
        case _ViewMode.day:
          _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
        case _ViewMode.month:
          _viewMonth = DateTime(_viewMonth.year + 1, _viewMonth.month);
        case _ViewMode.year:
          _yearPageStart += 12;
      }
    });
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _textS),
      ),
    );
  }

  // ── Month grid (3x4) ───────────────────────────────────────────────────
  Widget _buildMonthGrid() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: List.generate(4, (row) {
          return Row(
            children: List.generate(3, (col) {
              final m = row * 3 + col + 1;
              final isCurrent = _viewMonth.year == now.year && m == now.month;
              final isSelected = _viewMonth.month == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _viewMonth = DateTime(_viewMonth.year, m);
                    _mode = _ViewMode.day;
                  }),
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent.withOpacity(0.9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent && !isSelected
                          ? Border.all(color: _accent.withOpacity(0.6), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(_monthShort[m - 1], style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : _textP,
                      )),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // ── Year grid (3x4 = 12 years) ────────────────────────────────────────
  Widget _buildYearGrid() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: List.generate(4, (row) {
          return Row(
            children: List.generate(3, (col) {
              final y = _yearPageStart + row * 3 + col;
              final isCurrent = y == now.year;
              final isSelected = _viewMonth.year == y;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _viewMonth = DateTime(y, _viewMonth.month);
                    _yearPageStart = (y ~/ 12) * 12;
                    _mode = _ViewMode.month;
                  }),
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent.withOpacity(0.9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent && !isSelected
                          ? Border.all(color: _accent.withOpacity(0.6), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text('$y', style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : _textP,
                      )),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // ── Day labels ─────────────────────────────────────────────────────────
  Widget _buildDayLabels() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: _dayLabels.map((d) => Expanded(
          child: Center(child: Text(d, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: _textS.withOpacity(0.7)))),
        )).toList(),
      ),
    );
  }

  // ── Day grid ───────────────────────────────────────────────────────────
  Widget _buildDayGrid() {
    final today = DateTime.now();
    final firstOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final startWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final prevDays = DateTime(_viewMonth.year, _viewMonth.month, 0).day;

    final cells = <Widget>[];
    for (int i = startWeekday - 1; i >= 0; i--) {
      cells.add(_dayCell('${prevDays - i}', _textS.withOpacity(0.3), false, false, null));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_viewMonth.year, _viewMonth.month, d);
      final sel = _isSameDay(date, _selected);
      final isToday = _isSameDay(date, today);
      cells.add(_dayCell('$d', _textP, sel, isToday, () {
        Navigator.of(context).pop(date);
      }));
    }
    final rem = 7 - (cells.length % 7);
    if (rem < 7) {
      for (int d = 1; d <= rem; d++) {
        cells.add(_dayCell('$d', _textS.withOpacity(0.3), false, false, null));
      }
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        child: Row(children: cells.sublist(i, i + 7)),
      ));
    }
    return Column(children: rows);
  }

  Widget _dayCell(String text, Color color, bool sel, bool isToday, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: sel ? _accent.withOpacity(0.9) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday && !sel
                ? Border.all(color: _accent.withOpacity(0.6), width: 1.5)
                : null,
          ),
          child: Center(child: Text(text, style: TextStyle(
            fontSize: 13,
            fontWeight: sel || isToday ? FontWeight.w700 : FontWeight.w500,
            color: sel ? Colors.white : color,
          ))),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(null),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('Clear', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _textS)),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(today),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('Today', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
            ),
          ),
        ],
      ),
    );
  }
}
