import 'dart:async';
import 'package:flutter/material.dart';
import '../data/dashboard_repository.dart';
import '../../store/domain/store_model.dart';
import '../../ticket/data/ticket_repository.dart';
import '../../ticket/domain/ticket_model.dart';

/// DashboardController — state & logic for the analytics dashboard.
class DashboardController extends ChangeNotifier {
  final _repo = DashboardRepository();
  final _ticketRepo = TicketRepository();

  // ── Store state ───────────────────────────────────────────────
  List<StoreModel> allStores = [];
  List<StoreModel> filteredStores = [];
  bool isLoading = true;

  // ── Stats ─────────────────────────────────────────────────────
  int totalStores = 0;
  int foStores = 0;
  int backupVsat = 0;
  int singleVsat = 0;
  int gsmStores = 0;
  int xlStores = 0;

  // ── Ticket data ───────────────────────────────────────────────
  List<TicketModel> allTickets = [];

  // ── Chart filter ──────────────────────────────────────────────
  int chartDays = 30; // 7, 30, 90, 365
  int? filterMonth; // null = use quick filter (chartDays)
  int filterYear = DateTime.now().year;

  void setFilterMonth(int? month) {
    filterMonth = month;
    notifyListeners();
  }

  void setFilterYear(int year) {
    filterYear = year;
    notifyListeners();
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  // ── Clock ─────────────────────────────────────────────────────
  String timeString = '';
  String dateString = '';
  Timer? _timer;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // ── Init & dispose ────────────────────────────────────────────

  void init() {
    fetchData();
    _startClock();
    searchController.addListener(() => runFilter(searchController.text));
  }

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
    _timer?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    // Fetch stores & tickets in parallel
    final results = await Future.wait([
      _repo.fetchStats(),
      _ticketRepo.fetchAll(),
    ]);

    results[0].fold(
      (failure) => debugPrint('Dashboard store fetch error: ${failure.message}'),
      (stats) {
        final s = stats as dynamic;
        allStores = s.stores;
        filteredStores = s.stores;
        totalStores = s.total;
        foStores = s.fo;
        backupVsat = s.backupVsat;
        singleVsat = s.singleVsat;
        gsmStores = s.gsm;
        xlStores = s.xl;
      },
    );

    results[1].fold(
      (failure) => debugPrint('Dashboard ticket fetch error: ${failure.message}'),
      (tickets) {
        allTickets = tickets as List<TicketModel>;
      },
    );

    isLoading = false;
    notifyListeners();
  }

  void runFilter(String keyword) {
    filteredStores = keyword.isEmpty
        ? allStores
        : allStores
              .where(
                (s) =>
                    s.storeName.toLowerCase().contains(keyword.toLowerCase()) ||
                    s.storeCode.toLowerCase().contains(keyword.toLowerCase()),
              )
              .toList();
    notifyListeners();
  }

  void setChartDays(int days) {
    chartDays = days;
    filterMonth = null; // Clear monthly filter to show quick filter
    notifyListeners();
  }

  // ── Ticket computed properties ────────────────────────────────

  List<TicketModel> get _ticketsInRange {
    if (filterMonth != null) {
      return allTickets.where((t) =>
        t.createdAt != null &&
        t.createdAt!.year == filterYear &&
        t.createdAt!.month == filterMonth).toList();
    } else {
      final cutoff = DateTime.now().subtract(Duration(days: chartDays));
      return allTickets.where((t) =>
        t.createdAt != null && t.createdAt!.isAfter(cutoff)).toList();
    }
  }

  int get openTickets => _ticketsInRange.where((t) => t.status == 'Open').length;
  int get inProgressTickets => _ticketsInRange.where((t) => t.status == 'In Progress').length;
  int get resolvedTickets => _ticketsInRange.where((t) => t.status == 'Resolved').length;
  int get totalTicketsInRange => _ticketsInRange.length;

  /// Daily ticket counts for the chart — returns list of {date, open, progress, resolved}
  List<Map<String, dynamic>> get dailyChartData {
    final tickets = _ticketsInRange;
    final dayMap = <String, Map<String, int>>{};

    if (filterMonth != null) {
      // Initialize all days of the selected month
      final days = _daysInMonth(filterYear, filterMonth!);
      for (int i = 1; i <= days; i++) {
        final key = '$filterYear-${filterMonth!.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}';
        dayMap[key] = {'open': 0, 'progress': 0, 'resolved': 0};
      }
    } else {
      // Initialize all days based on quick filter (chartDays)
      final now = DateTime.now();
      final cutoff = now.subtract(Duration(days: chartDays));
      for (int i = 0; i <= chartDays; i++) {
        final d = cutoff.add(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        dayMap[key] = {'open': 0, 'progress': 0, 'resolved': 0};
      }
    }

    for (final t in tickets) {
      if (t.createdAt == null) continue;
      final d = t.createdAt!;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (!dayMap.containsKey(key)) continue;
      switch (t.status) {
        case 'Open': dayMap[key]!['open'] = (dayMap[key]!['open'] ?? 0) + 1;
        case 'In Progress': dayMap[key]!['progress'] = (dayMap[key]!['progress'] ?? 0) + 1;
        case 'Resolved': dayMap[key]!['resolved'] = (dayMap[key]!['resolved'] ?? 0) + 1;
        default: dayMap[key]!['open'] = (dayMap[key]!['open'] ?? 0) + 1;
      }
    }

    final sortedKeys = dayMap.keys.toList()..sort();
    return sortedKeys.map((k) => {
      'date': k,
      'open': dayMap[k]!['open']!,
      'progress': dayMap[k]!['progress']!,
      'resolved': dayMap[k]!['resolved']!,
    }).toList();
  }

  /// Top incident stores — ranking by ticket count
  List<Map<String, dynamic>> get incidentRanking {
    final tickets = _ticketsInRange;
    final storeMap = <String, Map<String, dynamic>>{};

    for (final t in tickets) {
      final code = t.storeCode;
      storeMap.putIfAbsent(code, () => {
        'store_code': code,
        'store_name': t.storeName,
        'total': 0, 'open': 0, 'progress': 0, 'resolved': 0,
        'last_incident': t.createdAt,
      });
      storeMap[code]!['total'] = (storeMap[code]!['total'] as int) + 1;
      switch (t.status) {
        case 'Open': storeMap[code]!['open'] = (storeMap[code]!['open'] as int) + 1;
        case 'In Progress': storeMap[code]!['progress'] = (storeMap[code]!['progress'] as int) + 1;
        case 'Resolved': storeMap[code]!['resolved'] = (storeMap[code]!['resolved'] as int) + 1;
        default: storeMap[code]!['open'] = (storeMap[code]!['open'] as int) + 1;
      }
      final existing = storeMap[code]!['last_incident'] as DateTime?;
      if (existing == null || (t.createdAt != null && t.createdAt!.isAfter(existing))) {
        storeMap[code]!['last_incident'] = t.createdAt;
      }
    }

    final list = storeMap.values.toList()
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return list.take(10).toList();
  }

  /// Recent unresolved/critical tickets — max 10
  List<TicketModel> get recentCriticalTickets {
    final unresolved = allTickets
        .where((t) => t.status != 'Resolved')
        .toList()
      ..sort((a, b) {
        final da = a.createdAt ?? DateTime(2000);
        final db = b.createdAt ?? DateTime(2000);
        return db.compareTo(da);
      });
    return unresolved.take(10).toList();
  }

  /// Insight: percentage change vs previous period
  double get ticketChangePercent {
    final now = DateTime.now();
    final currentCutoff = now.subtract(Duration(days: chartDays));
    final prevCutoff = currentCutoff.subtract(Duration(days: chartDays));

    final current = allTickets.where((t) =>
        t.createdAt != null && t.createdAt!.isAfter(currentCutoff)).length;
    final previous = allTickets.where((t) =>
        t.createdAt != null &&
        t.createdAt!.isAfter(prevCutoff) &&
        t.createdAt!.isBefore(currentCutoff)).length;

    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous * 100);
  }

  // ── Clock ─────────────────────────────────────────────────────

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    timeString = '$h:$m:$s';
    dateString =
        '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    notifyListeners();
  }
}
