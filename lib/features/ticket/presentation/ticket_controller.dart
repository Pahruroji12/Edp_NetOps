import 'dart:async';
import 'package:flutter/material.dart';

import '../domain/ticket_model.dart';
import '../data/ticket_repository.dart';
import '../../../core/error/failures.dart';

import '../domain/ticket_ranking_result.dart';
import '../domain/services/ticket_ranking_calculator.dart';

/// Sort column identifiers for ticket table.
enum TicketSortColumn {
  storeCode,
  storeName,
  status,
  createdAt,
  provider,
  nomorTiket,
}

/// View mode for ranking tab.
enum RankingViewMode { compact, table }

/// Quick filter preset periods.
enum QuickFilterPeriod {
  today,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisYear,
}

/// TicketController — semua state dan logic untuk TicketHistoryPage.
///
/// Lokasi: features/ticket/presentation/ticket_controller.dart
///
class TicketController extends ChangeNotifier {
  final _repo = TicketRepository();

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    searchCtrl.dispose();
    super.dispose();
  }

  // ── State ─────────────────────────────────────────────────────
  List<TicketModel> allTickets = [];
  List<TicketModel> filteredTickets = [];
  bool isLoading = true;

  String filterStatus = 'Semua';
  String filterProvider = 'Semua';
  bool filterNoTiket = false; // true = only show tickets without nomor_tiket

  // Period filter — month/year/date range
  DateTime? selectedMonth; // legacy compat — used by ranking tab
  int? filterMonth; // 1-12 or null for all
  int? filterYear; // 2024, 2025, etc. or null for all
  DateTimeRange? customDateRange; // custom range
  QuickFilterPeriod? activeQuickFilter; // active quick filter

  // Period start/end filter (new date picker style) — history tab
  DateTime? periodStart;
  DateTime? periodEnd;

  // Period start/end filter — ranking tab (independent)
  DateTime? rankingPeriodStart;
  DateTime? rankingPeriodEnd;

  // Sorting
  TicketSortColumn sortColumn = TicketSortColumn.createdAt;
  bool sortAscending = false;

  // Ranking
  RankingViewMode rankingViewMode = RankingViewMode.compact;
  final Set<String> expandedRankItems = {};

  final searchCtrl = TextEditingController();

  // ── Constants ─────────────────────────────────────────────────
  static const statuses = ['Semua', 'Open', 'In Progress', 'Resolved'];
  static const providers = ['Semua', 'Astinet', 'ICON', 'Fiberstar'];
  static const monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const monthNamesShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  // ── Colors (soft enterprise palette) ──────────────────────────
  static Color statusColor(String s) => switch (s) {
    'Open' => const Color(0xFFE57373),
    'In Progress' => const Color(0xFFFFB74D),
    'Resolved' => const Color(0xFF81C784),
    _ => const Color(0xFF78909C),
  };

  static SeverityLevel calculateSeverity(int total, int open) =>
      TicketRankingCalculator.calculateSeverity(total, open);

  static Color severityColor(SeverityLevel level) => switch (level) {
    SeverityLevel.critical => const Color(0xFFE57373),
    SeverityLevel.warning => const Color(0xFFFFB74D),
    SeverityLevel.stable => const Color(0xFF81C784),
  };

  static String severityLabel(SeverityLevel level) => switch (level) {
    SeverityLevel.critical => 'Critical',
    SeverityLevel.warning => 'Warning',
    SeverityLevel.stable => 'Stable',
  };

  // ── Data ──────────────────────────────────────────────────────

  Future<void> loadTickets() async {
    isLoading = true;
    notifyListeners();

    final result = await _repo.fetchAll();
    result.fold(
      (Failure failure) => debugPrint('Error load tickets: ${failure.message}'),
      (tickets) {
        allTickets = tickets;
        applyFilter();
      },
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateTicket({
    required String id,
    required String nomorTiket,
    required String status,
    required String keterangan,
  }) async {
    String finalStatus = status;
    final trimmedNo = nomorTiket.trim();
    if (trimmedNo.isNotEmpty && finalStatus == 'Open') {
      finalStatus = 'In Progress';
    } else if (trimmedNo.isEmpty && finalStatus == 'In Progress') {
      finalStatus = 'Open';
    }

    final result = await _repo.update(
      id: id,
      nomorTiket: trimmedNo,
      status: finalStatus,
      keterangan: keterangan.trim(),
    );
    await result.fold(
      (Failure failure) async =>
          debugPrint('Error update ticket: ${failure.message}'),
      (_) async => await loadTickets(),
    );
  }

  Future<void> deleteTicket(String id) async {
    final result = await _repo.delete(id);
    await result.fold(
      (Failure failure) async =>
          debugPrint('Error delete ticket: ${failure.message}'),
      (_) async => await loadTickets(),
    );
  }

  // ── Filter ────────────────────────────────────────────────────

  void applyFilter() {
    final q = searchCtrl.text.toLowerCase();
    filteredTickets = allTickets.where((t) {
      final matchStatus = filterStatus == 'Semua' || t.status == filterStatus;
      final matchProvider =
          filterProvider == 'Semua' || t.provider == filterProvider;
      final matchSearch =
          q.isEmpty ||
          t.storeCode.toLowerCase().contains(q) ||
          t.storeName.toLowerCase().contains(q) ||
          (t.nomorTiket ?? '').toLowerCase().contains(q);
      final matchPeriod = _matchesPeriod(t);
      final matchNoTiket =
          !filterNoTiket ||
          (t.nomorTiket == null || t.nomorTiket!.trim().isEmpty);
      return matchStatus &&
          matchProvider &&
          matchSearch &&
          matchPeriod &&
          matchNoTiket;
    }).toList();
    _applySorting();
    notifyListeners();
  }

  /// Unified period matching: periodStart/End > custom range > quick filter > month+year > month only > year only
  bool _matchesPeriod(TicketModel t) {
    if (t.createdAt == null) {
      // If no date and any filter is active, exclude
      return periodStart == null &&
          periodEnd == null &&
          customDateRange == null &&
          activeQuickFilter == null &&
          filterMonth == null &&
          filterYear == null &&
          selectedMonth == null;
    }

    final dt = t.createdAt!;

    // 0. Period start/end range takes top priority
    if (periodStart != null && periodEnd != null) {
      final start = DateTime(
        periodStart!.year,
        periodStart!.month,
        periodStart!.day,
      );
      final end = DateTime(
        periodEnd!.year,
        periodEnd!.month,
        periodEnd!.day,
        23,
        59,
        59,
      );
      return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(end.add(const Duration(seconds: 1)));
    }

    // 1. Custom date range takes priority
    if (customDateRange != null) {
      final start = DateTime(
        customDateRange!.start.year,
        customDateRange!.start.month,
        customDateRange!.start.day,
      );
      final end = DateTime(
        customDateRange!.end.year,
        customDateRange!.end.month,
        customDateRange!.end.day,
        23,
        59,
        59,
      );
      return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(end.add(const Duration(seconds: 1)));
    }

    // 2. Quick filter
    if (activeQuickFilter != null) {
      return _matchesQuickFilter(dt, activeQuickFilter!);
    }

    // 3. Month + Year
    if (filterMonth != null && filterYear != null) {
      return dt.month == filterMonth && dt.year == filterYear;
    }

    // 4. Month only (any year)
    if (filterMonth != null) {
      return dt.month == filterMonth;
    }

    // 5. Year only
    if (filterYear != null) {
      return dt.year == filterYear;
    }

    // 6. Legacy selectedMonth (used by ranking tab)
    if (selectedMonth != null) {
      return dt.year == selectedMonth!.year && dt.month == selectedMonth!.month;
    }

    return true;
  }

  bool _matchesQuickFilter(DateTime dt, QuickFilterPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case QuickFilterPeriod.today:
        return dt.year == today.year &&
            dt.month == today.month &&
            dt.day == today.day;
      case QuickFilterPeriod.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return dt.isAfter(start.subtract(const Duration(seconds: 1)));
      case QuickFilterPeriod.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return dt.isAfter(start.subtract(const Duration(seconds: 1)));
      case QuickFilterPeriod.thisMonth:
        return dt.year == now.year && dt.month == now.month;
      case QuickFilterPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        return dt.year == lastMonth.year && dt.month == lastMonth.month;
      case QuickFilterPeriod.thisYear:
        return dt.year == now.year;
    }
  }

  // ── Period setters ────────────────────────────────────────────

  void setFilterMonth(int? month) {
    filterMonth = month;
    activeQuickFilter = null;
    customDateRange = null;
    _syncSelectedMonth();
    applyFilter();
  }

  void toggleNoTiketFilter(bool value) {
    filterNoTiket = value;
    applyFilter();
  }

  void setFilterYear(int? year) {
    filterYear = year;
    activeQuickFilter = null;
    customDateRange = null;
    _syncSelectedMonth();
    applyFilter();
  }

  void setCustomDateRange(DateTimeRange? range) {
    customDateRange = range;
    activeQuickFilter = null;
    filterMonth = null;
    filterYear = null;
    selectedMonth = null;
    periodStart = null;
    periodEnd = null;
    applyFilter();
  }

  void setQuickFilter(QuickFilterPeriod? period) {
    activeQuickFilter = period;
    customDateRange = null;
    filterMonth = null;
    filterYear = null;
    selectedMonth = null;
    periodStart = null;
    periodEnd = null;
    applyFilter();
  }

  /// Set period range from the new PERIOD START / PERIOD END picker
  void setPeriodRange(DateTime start, DateTime end) {
    periodStart = start;
    periodEnd = end;
    // Clear other period filters
    activeQuickFilter = null;
    customDateRange = null;
    filterMonth = null;
    filterYear = null;
    selectedMonth = null;
    applyFilter();
  }

  void clearPeriodFilter() {
    filterMonth = null;
    filterYear = null;
    customDateRange = null;
    activeQuickFilter = null;
    selectedMonth = null;
    periodStart = null;
    periodEnd = null;
    applyFilter();
  }

  // ── Ranking tab period (independent from history tab) ─────────
  void setRankingPeriodRange(DateTime start, DateTime end) {
    rankingPeriodStart = start;
    rankingPeriodEnd = end;
    notifyListeners();
  }

  void clearRankingPeriodFilter() {
    rankingPeriodStart = null;
    rankingPeriodEnd = null;
    notifyListeners();
  }

  bool get hasRankingPeriodFilter =>
      rankingPeriodStart != null && rankingPeriodEnd != null;

  String get displayRankingPeriodLabel {
    if (rankingPeriodStart != null && rankingPeriodEnd != null) {
      return '${rankingPeriodStart!.day} ${monthNamesShort[rankingPeriodStart!.month - 1]} ${rankingPeriodStart!.year} — '
          '${rankingPeriodEnd!.day} ${monthNamesShort[rankingPeriodEnd!.month - 1]} ${rankingPeriodEnd!.year}';
    }
    return 'Semua Periode';
  }

  /// Sync selectedMonth for ranking tab backward compatibility
  void _syncSelectedMonth() {
    if (filterMonth != null && filterYear != null) {
      selectedMonth = DateTime(filterYear!, filterMonth!);
    } else {
      selectedMonth = null;
    }
  }

  bool get hasPeriodFilter =>
      filterMonth != null ||
      filterYear != null ||
      customDateRange != null ||
      activeQuickFilter != null ||
      (periodStart != null && periodEnd != null);

  bool get hasAnyFilter =>
      hasPeriodFilter ||
      filterStatus != 'Semua' ||
      filterProvider != 'Semua' ||
      filterNoTiket ||
      searchCtrl.text.isNotEmpty;

  // ── Period display label ──────────────────────────────────────

  String get displayPeriodLabel {
    if (periodStart != null && periodEnd != null) {
      return '${periodStart!.day} ${monthNamesShort[periodStart!.month - 1]} ${periodStart!.year} — '
          '${periodEnd!.day} ${monthNamesShort[periodEnd!.month - 1]} ${periodEnd!.year}';
    }
    if (customDateRange != null) {
      final s = customDateRange!.start;
      final e = customDateRange!.end;
      return '${s.day} ${monthNamesShort[s.month - 1]} ${s.year} — '
          '${e.day} ${monthNamesShort[e.month - 1]} ${e.year}';
    }
    if (activeQuickFilter != null) {
      return switch (activeQuickFilter!) {
        QuickFilterPeriod.today => 'Hari Ini',
        QuickFilterPeriod.last7Days => '7 Hari Terakhir',
        QuickFilterPeriod.last30Days => '30 Hari Terakhir',
        QuickFilterPeriod.thisMonth =>
          '${monthNames[DateTime.now().month - 1]} ${DateTime.now().year}',
        QuickFilterPeriod.lastMonth => () {
          final lm = DateTime(DateTime.now().year, DateTime.now().month - 1);
          return '${monthNames[lm.month - 1]} ${lm.year}';
        }(),
        QuickFilterPeriod.thisYear => 'Tahun ${DateTime.now().year}',
      };
    }
    if (filterMonth != null && filterYear != null) {
      return '${monthNames[filterMonth! - 1]} $filterYear';
    }
    if (filterMonth != null) {
      return 'Bulan ${monthNames[filterMonth! - 1]}';
    }
    if (filterYear != null) {
      return 'Tahun $filterYear';
    }
    if (selectedMonth != null) {
      return '${monthNames[selectedMonth!.month - 1]} ${selectedMonth!.year}';
    }
    return 'Semua Periode';
  }

  // ── Available years/months from data ──────────────────────────

  List<int> availableYears() {
    final years = <int>{};
    for (final t in allTickets) {
      if (t.createdAt != null) years.add(t.createdAt!.year);
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  List<DateTime> availableMonths() {
    final seen = <String>{};
    final months = <DateTime>[];
    for (final t in allTickets) {
      if (t.createdAt == null) continue;
      final key =
          '${t.createdAt!.year}-${t.createdAt!.month.toString().padLeft(2, '0')}';
      if (seen.add(key)) {
        months.add(DateTime(t.createdAt!.year, t.createdAt!.month));
      }
    }
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  String monthLabel(DateTime m) => '${monthNames[m.month - 1]} ${m.year}';

  // ── Legacy month helpers (for ranking tab) ────────────────────

  void setMonth(DateTime? m) {
    selectedMonth = m;
    if (m != null) {
      filterMonth = m.month;
      filterYear = m.year;
    } else {
      filterMonth = null;
      filterYear = null;
    }
    activeQuickFilter = null;
    customDateRange = null;
    applyFilter();
  }

  void prevMonth() {
    final months = availableMonths();
    if (months.isEmpty) return;
    if (selectedMonth == null) {
      setMonth(months.first);
      return;
    }
    final idx = months.indexWhere(
      (m) => m.year == selectedMonth!.year && m.month == selectedMonth!.month,
    );
    if (idx < months.length - 1) setMonth(months[idx + 1]);
  }

  void nextMonth() {
    final months = availableMonths();
    if (months.isEmpty) return;
    if (selectedMonth == null) {
      setMonth(months.first);
      return;
    }
    final idx = months.indexWhere(
      (m) => m.year == selectedMonth!.year && m.month == selectedMonth!.month,
    );
    if (idx > 0) setMonth(months[idx - 1]);
  }

  // ── Sorting ───────────────────────────────────────────────────

  void _applySorting() {
    filteredTickets.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case TicketSortColumn.storeCode:
          cmp = a.storeCode.compareTo(b.storeCode);
        case TicketSortColumn.storeName:
          cmp = a.storeName.compareTo(b.storeName);
        case TicketSortColumn.status:
          cmp = a.status.compareTo(b.status);
        case TicketSortColumn.createdAt:
          cmp = (a.createdAt ?? DateTime(2000)).compareTo(
            b.createdAt ?? DateTime(2000),
          );
        case TicketSortColumn.provider:
          cmp = a.provider.compareTo(b.provider);
        case TicketSortColumn.nomorTiket:
          cmp = (a.nomorTiket ?? '').compareTo(b.nomorTiket ?? '');
      }
      return sortAscending ? cmp : -cmp;
    });
  }

  void setSort(TicketSortColumn column) {
    if (sortColumn == column) {
      sortAscending = !sortAscending;
    } else {
      sortColumn = column;
      sortAscending = true;
    }
    applyFilter();
  }

  // ── Ranking ───────────────────────────────────────────────────

  void toggleRankingView() {
    rankingViewMode = rankingViewMode == RankingViewMode.compact
        ? RankingViewMode.table
        : RankingViewMode.compact;
    notifyListeners();
  }

  void toggleRankExpansion(String storeCode) {
    if (expandedRankItems.contains(storeCode)) {
      expandedRankItems.remove(storeCode);
    } else {
      expandedRankItems.add(storeCode);
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> buildRanking(List<TicketModel> data) {
    final rankings = TicketRankingCalculator.calculateRanking(data);
    return rankings.map((r) => r.toMap()).toList();
  }

  /// Konversi ke List<Map> untuk ExportHelper (masih pakai Map)
  List<Map<String, dynamic>> get filteredAsMaps =>
      filteredTickets.map((t) => t.toJson()).toList();

  List<Map<String, dynamic>> get allAsMaps =>
      allTickets.map((t) => t.toJson()).toList();

}
