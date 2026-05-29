import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../domain/ticket_model.dart';
import '../data/ticket_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../auth/domain/auth_state.dart';

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

/// Severity level for ranking items.
enum SeverityLevel { critical, warning, stable }

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

  // ── State ─────────────────────────────────────────────────────
  List<TicketModel> allTickets = [];
  List<TicketModel> filteredTickets = [];
  bool isLoading = true;

  // Background Worker State
  Map<String, dynamic>? workerStatus;
  bool isWorkerLoading = false;
  bool isSyncingWorker = false;
  bool isWorkerApiReachable = false;
  bool isHostMachine = false;

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
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  // ── Colors (soft enterprise palette) ──────────────────────────
  static Color statusColor(String s) => switch (s) {
    'Open' => const Color(0xFFE57373),
    'In Progress' => const Color(0xFFFFB74D),
    'Resolved' => const Color(0xFF81C784),
    _ => const Color(0xFF78909C),
  };

  static SeverityLevel calculateSeverity(int total, int open) {
    if (open >= 3 || total >= 5) return SeverityLevel.critical;
    if (open >= 1 || total >= 3) return SeverityLevel.warning;
    return SeverityLevel.stable;
  }

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
      (Failure failure) =>
          debugPrint('Error load tickets: ${failure.message}'),
      (tickets) {
        allTickets = tickets;
        applyFilter();
      },
    );

    isLoading = false;
    notifyListeners();
  }

  /// Ambil status monitoring dari Background Worker di Supabase dan cek apakah API aktif
  Future<void> fetchWorkerStatus() async {
    isWorkerLoading = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      
      // 1. Ambil status dari database Supabase
      final res = await client
          .from('worker_status')
          .select()
          .eq('id', 'ticket-sync-worker')
          .maybeSingle();
      
      Map<String, dynamic>? statusMap = res != null ? Map<String, dynamic>.from(res) : null;

      // 2. Ambil URL API worker untuk dicek keaktifannya secara langsung
      final rows = await client
          .from('app_settings')
          .select('key, value')
          .eq('key', 'worker_api_url')
          .maybeSingle();
      
      String workerUrl = 'http://localhost:8080';
      if (rows != null && rows['value'] != null) {
        workerUrl = rows['value'].toString().trim();
      }
      if (workerUrl.endsWith('/')) {
        workerUrl = workerUrl.substring(0, workerUrl.length - 1);
      }

      // 3. Deteksi peran komputer ini: HOST (Komputer Utama) atau CLIENT (Komputer Lain)
      final workerDir = await getWorkerPath();
      isHostMachine = await Directory(workerDir).exists();
      final bool isLocalhostUrl = workerUrl.contains('localhost') || workerUrl.contains('127.0.0.1');

      // 4. Ping endpoint /status untuk memastikan proses worker benar-benar hidup secara fisik
      isWorkerApiReachable = false;
      if (!kIsWeb) {
        // Kita hanya ping jika:
        // A. Komputer ini adalah HOST (memiliki folder worker), ATAU
        // B. URL API worker menggunakan IP remote (sehingga Client pun bisa ping komputer utama)
        if (isHostMachine || !isLocalhostUrl) {
          try {
            final uri = Uri.parse('$workerUrl/status');
            final httpClient = HttpClient();
            httpClient.connectionTimeout = const Duration(milliseconds: 1500);
            final request = await httpClient.getUrl(uri);
            final response = await request.close();
            if (response.statusCode == 200) {
              isWorkerApiReachable = true;
            }
          } catch (_) {
            isWorkerApiReachable = false;
          }
        } else {
          // Jika komputer ini adalah CLIENT dan URL worker disetel ke localhost (default),
          // client tidak bisa ping localhost-nya sendiri (karena worker ada di komputer utama).
          // Maka kita asumsikan reachable agar status dari database Supabase asli tidak ter-override.
          isWorkerApiReachable = true;
        }
      }

      // 5. Override status Supabase ke 'unknown' (offline) jika host mendeteksi local api mati,
      // atau jika client mendeteksi remote IP worker mati.
      if (!isWorkerApiReachable) {
        if (statusMap == null) {
          statusMap = {'status': 'unknown'};
        } else {
          statusMap['status'] = 'unknown';
        }
      }

      workerStatus = statusMap;
    } catch (e) {
      debugPrint('Error fetching worker status: $e');
    } finally {
      isWorkerLoading = false;
      notifyListeners();
    }
  }

  /// Pemicu sinkronisasi manual langsung ke Background Worker (Deno Server)
  Future<void> triggerWorkerSync() async {
    if (isSyncingWorker) return;
    isSyncingWorker = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('app_settings')
          .select('key, value')
          .eq('key', 'worker_api_url')
          .maybeSingle();
      
      String workerUrl = 'http://localhost:8080';
      if (rows != null && rows['value'] != null) {
        workerUrl = rows['value'].toString().trim();
      }

      if (workerUrl.endsWith('/')) {
        workerUrl = workerUrl.substring(0, workerUrl.length - 1);
      }

      final uri = Uri.parse('$workerUrl/sync');
      debugPrint('[Worker Trigger] Hitting sync endpoint: $uri');

      if (kIsWeb) {
        CustomSnackBar.info('Pemicu manual worker tidak didukung langsung dari Web. Silakan trigger endpoint /sync di server.');
        return;
      }

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 15);
      
      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final response = await request.close();
      
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final count = decoded['updated_tickets_count'] ?? 0;
        CustomSnackBar.success('Worker Sync Sukses! $count tiket baru disinkronisasi.');
        await loadTickets();
        await fetchWorkerStatus();
      } else {
        final err = decoded['error'] ?? 'Terjadi kesalahan internal server';
        CustomSnackBar.error('Worker Sync Gagal: $err');
      }
    } catch (e) {
      debugPrint('[Worker Trigger Error] $e');
      CustomSnackBar.error('Gagal menghubungi Background Worker. Pastikan service Deno aktif di $e');
    }
  }

  /// Mendapatkan path folder worker secara dinamis (dev/production)
  static Future<String> getWorkerPath() async {
    try {
      final exeFile = File(Platform.resolvedExecutable);
      final exeDir = exeFile.parent.path;
      final prodPath = Directory('$exeDir/worker-ticket-sync');
      if (await prodPath.exists()) {
        return prodPath.path;
      }
    } catch (_) {}

    final defaultProd = Directory(r'D:\Edp NetOps\worker-ticket-sync');
    if (await defaultProd.exists()) {
      return defaultProd.path;
    }

    final devPath = Directory(r'd:\DartProject\edp_netops\worker-ticket-sync');
    if (await devPath.exists()) {
      return devPath.path;
    }

    return r'D:\Edp NetOps\worker-ticket-sync';
  }

  /// Menjalankan Background Worker secara terpisah (detached & silent)
  /// Menggunakan VBScript wrapper agar jendela CMD benar-benar tersembunyi di Windows.
  Future<void> startBackgroundWorker() async {
    if (kIsWeb) {
      CustomSnackBar.info('Menyalakan worker tidak didukung dari web browser.');
      return;
    }

    final workerDir = await getWorkerPath();
    debugPrint('[Worker Manager] Starting worker at directory: $workerDir');

    if (!await Directory(workerDir).exists()) {
      CustomSnackBar.error('Folder worker tidak ditemukan di: $workerDir');
      return;
    }

    try {
      // Buat file VBScript pendukung jika belum ada
      final vbsFile = File('$workerDir\\start_hidden.vbs');
      final vbsContent = '''
Set objFSO = CreateObject("Scripting.FileSystemObject")
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
Set objShell = CreateObject("WScript.Shell")
objShell.CurrentDirectory = strPath
objShell.Run "cmd /c npm run start", 0, False
''';
      await vbsFile.writeAsString(vbsContent);

      // Jalankan VBScript secara detached — ini akan menyembunyikan jendela CMD sepenuhnya
      final process = await Process.start(
        'wscript.exe',
        [vbsFile.path],
        mode: ProcessStartMode.detached,
      );

      debugPrint('[Worker Manager] Started hidden worker via VBS, PID: ${process.pid}');
      CustomSnackBar.success('Background Worker berhasil dijalankan di latar belakang (silent)!');

      // Tunggu 4 detik agar server booting, lalu ambil statusnya
      await Future.delayed(const Duration(seconds: 4));
      await fetchWorkerStatus();
    } catch (e) {
      debugPrint('[Worker Manager Error] $e');
      CustomSnackBar.error('Gagal menyalakan worker secara otomatis: $e');
    }
  }

  /// Mengecek apakah worker sudah jalan secara lokal, jika belum akan dijalankan secara otomatis (Silent).
  /// Dipanggil otomatis pasca login sukses ke aplikasi.
  static Future<void> autoStartWorkerIfNeeded() async {
    if (kIsWeb) return;

    if (!AuthState.instance.isAdmin) {
      debugPrint('[Background Worker] User is not admin/administrator. Skip worker auto-start.');
      return;
    }

    try {
      final client = Supabase.instance.client;

      // 1. Dapatkan URL API worker
      final rows = await client
          .from('app_settings')
          .select('key, value')
          .eq('key', 'worker_api_url')
          .maybeSingle();

      String workerUrl = 'http://localhost:8080';
      if (rows != null && rows['value'] != null) {
        workerUrl = rows['value'].toString().trim();
      }
      if (workerUrl.endsWith('/')) {
        workerUrl = workerUrl.substring(0, workerUrl.length - 1);
      }

      // 2. Ping endpoint status local worker
      bool isRunning = false;
      try {
        final uri = Uri.parse('$workerUrl/status');
        final httpClient = HttpClient();
        httpClient.connectionTimeout = const Duration(milliseconds: 1000);
        final request = await httpClient.getUrl(uri);
        final response = await request.close();
        if (response.statusCode == 200) {
          isRunning = true;
        }
      } catch (_) {
        isRunning = false;
      }

      // 3. Jika sudah jalan, tidak perlu dijalankan ulang
      if (isRunning) {
        debugPrint('[Background Worker] Worker is already running. Skip auto-start.');
        return;
      }

      // 4. Jika mati, jalankan via wscript.exe
      final workerDir = await getWorkerPath();
      if (!await Directory(workerDir).exists()) {
        debugPrint('[Background Worker] Folder worker tidak ditemukan di: $workerDir. Skip auto-start.');
        return;
      }

      final vbsFile = File('$workerDir\\start_hidden.vbs');
      final vbsContent = '''
Set objFSO = CreateObject("Scripting.FileSystemObject")
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
Set objShell = CreateObject("WScript.Shell")
objShell.CurrentDirectory = strPath
objShell.Run "cmd /c npm run start", 0, False
''';
      await vbsFile.writeAsString(vbsContent);

      await Process.start(
        'wscript.exe',
        [vbsFile.path],
        mode: ProcessStartMode.detached,
      );

      debugPrint('[Background Worker] Auto-started background worker successfully at $workerDir');
    } catch (e) {
      debugPrint('[Background Worker] Error in autoStartWorkerIfNeeded: $e');
    }
  }

  /// Menghentikan Background Worker secara graceful melalui endpoint /shutdown
  Future<void> stopBackgroundWorker() async {
    if (kIsWeb) {
      CustomSnackBar.info('Menghentikan worker tidak didukung dari web browser.');
      return;
    }

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('app_settings')
          .select('key, value')
          .eq('key', 'worker_api_url')
          .maybeSingle();

      String workerUrl = 'http://localhost:8080';
      if (rows != null && rows['value'] != null) {
        workerUrl = rows['value'].toString().trim();
      }
      if (workerUrl.endsWith('/')) {
        workerUrl = workerUrl.substring(0, workerUrl.length - 1);
      }

      final uri = Uri.parse('$workerUrl/shutdown');
      debugPrint('[Worker Manager] Sending shutdown to: $uri');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);

      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final response = await request.close();

      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 && decoded['success'] == true) {
        CustomSnackBar.success('Worker berhasil dihentikan.');
      } else {
        CustomSnackBar.error('Gagal menghentikan worker: ${decoded['error'] ?? 'Unknown'}');
      }

      // Tunggu sebentar lalu refresh status
      await Future.delayed(const Duration(seconds: 2));
      await fetchWorkerStatus();
    } catch (e) {
      debugPrint('[Worker Stop Error] $e');
      CustomSnackBar.error('Worker tidak merespon (mungkin sudah mati). Error: $e');
      // Tetap refresh status
      await fetchWorkerStatus();
    }
  }


  Future<void> updateTicket({
    required String id,
    required String nomorTiket,
    required String status,
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
      final matchStatus =
          filterStatus == 'Semua' || t.status == filterStatus;
      final matchProvider =
          filterProvider == 'Semua' || t.provider == filterProvider;
      final matchSearch =
          q.isEmpty ||
          t.storeCode.toLowerCase().contains(q) ||
          t.storeName.toLowerCase().contains(q) ||
          (t.nomorTiket ?? '').toLowerCase().contains(q);
      final matchPeriod = _matchesPeriod(t);
      final matchNoTiket = !filterNoTiket ||
          (t.nomorTiket == null || t.nomorTiket!.trim().isEmpty);
      return matchStatus && matchProvider && matchSearch && matchPeriod && matchNoTiket;
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
        periodStart!.year, periodStart!.month, periodStart!.day,
      );
      final end = DateTime(
        periodEnd!.year, periodEnd!.month, periodEnd!.day,
        23, 59, 59,
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
        23, 59, 59,
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
      return dt.year == selectedMonth!.year &&
          dt.month == selectedMonth!.month;
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
      (m) =>
          m.year == selectedMonth!.year &&
          m.month == selectedMonth!.month,
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
      (m) =>
          m.year == selectedMonth!.year &&
          m.month == selectedMonth!.month,
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
    final map = <String, Map<String, dynamic>>{};
    for (final t in data) {
      map.putIfAbsent(
        t.storeCode,
        () => {
          'store_code': t.storeCode,
          'store_name': t.storeName,
          'total': 0,
          'open': 0,
          'in_progress': 0,
          'resolved': 0,
          'last_incident': null,
          'tickets': <TicketModel>[],
        },
      );
      map[t.storeCode]!['total'] =
          (map[t.storeCode]!['total'] as int) + 1;

      // Track last incident
      final currentLast =
          map[t.storeCode]!['last_incident'] as DateTime?;
      if (t.createdAt != null &&
          (currentLast == null || t.createdAt!.isAfter(currentLast))) {
        map[t.storeCode]!['last_incident'] = t.createdAt;
      }

      // Collect tickets for expandable detail
      (map[t.storeCode]!['tickets'] as List<TicketModel>).add(t);

      switch (t.status) {
        case 'Open':
          map[t.storeCode]!['open'] =
              (map[t.storeCode]!['open'] as int) + 1;
        case 'In Progress':
          map[t.storeCode]!['in_progress'] =
              (map[t.storeCode]!['in_progress'] as int) + 1;
        case 'Resolved':
          map[t.storeCode]!['resolved'] =
              (map[t.storeCode]!['resolved'] as int) + 1;
      }
    }
    final list = map.values.toList()
      ..sort(
        (a, b) => (b['total'] as int).compareTo(a['total'] as int),
      );
    return list;
  }

  /// Konversi ke List<Map> untuk ExportHelper (masih pakai Map)
  List<Map<String, dynamic>> get filteredAsMaps =>
      filteredTickets.map((t) => t.toJson()).toList();

  List<Map<String, dynamic>> get allAsMaps =>
      allTickets.map((t) => t.toJson()).toList();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}
