import 'dart:async';
import 'package:edp_netops/core/platform/native_io.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/activity_logger.dart';
import '../../../../core/utils/notification_mixin.dart';
import '../data/ping_repository.dart';
import '../data/ping_executor.dart';
import '../domain/ping_config.dart';
import '../domain/ping_result.dart';

/// PingController — satu-satunya ChangeNotifier untuk fitur Ping.
///
/// Lokasi: features/network_tools/ping/presentation/ping_controller.dart
///
/// Tanggung jawab:
///   - Kelola state UI (isScanning, progress, OK/NOK counts)
///   - Kelola checkbox config via PingConfig
///   - Orchestrate: PingRepository (fetch data) → PingExecutor (jalankan ping)
///   - Auto-ping scheduler
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung (gunakan callback/state)
///   - Import widget UI
///   - Query Supabase langsung (harus via repository)
///
class PingController extends ChangeNotifier with NotificationMixin {
  // ── Singleton ────────────────────────────────────────────────
  static final PingController instance = PingController._internal();

  // ── Dependencies ─────────────────────────────────────────────
  final PingRepository _repo;
  final PingExecutor _executor;

  // Singleton menggunakan default instance.
  PingController._internal()
      : _repo = PingRepository(),
        _executor = PingExecutor();

  /// Constructor untuk testing — inject mock dependencies.
  @visibleForTesting
  PingController.test({
    required PingRepository repo,
    required PingExecutor executor,
  })  : _repo = repo,
        _executor = executor;

  bool _initialized = false;

  // ── State: Checkbox Config ───────────────────────────────────
  PingConfig config = const PingConfig();

  // ── State: Scanning Progress ─────────────────────────────────
  bool isScanning = false;
  String statusText = 'Siap untuk memulai pemindaian...';
  double progressValue = 0.0;
  int okCount = 0;
  int nokCount = 0;
  int totalTarget = 0;
  String? lastFilePath;
  DateTime? scanStartTime;
  DateTime? scanEndTime;

  // ── State: Auto-Ping ─────────────────────────────────────────
  bool isAutoPingSTBActive = false;
  Timer? _schedulerTimer;
  bool _isAutoPingRunning = false;

  // ── State: Notification (via NotificationMixin) ──────────────

  /// Output directory untuk hasil ping.
  /// Environment-aware: coba D: dulu, fallback ke Documents.
  String get outputDir {
    const preferred = r'D:\Edp NetOps\Hasil Ping';
    if (Directory(r'D:\').existsSync()) return preferred;
    return '${Platform.environment['USERPROFILE']}\\Documents\\Edp NetOps\\Hasil Ping';
  }

  // ── INISIALISASI (panggil di main.dart) ──────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    // Default: true (aktif)
    isAutoPingSTBActive = prefs.getBool('auto_ping_stb_active') ?? true;
    
    // Jalankan timer penjadwalan di latar belakang (selalu aktif untuk memantau pukul 23:00)
    _startSchedulerTimer();
    
    notifyListeners();
  }

  // ── UPDATE STATE CHECKBOX ────────────────────────────────────
  void setCheckbox(String type, bool val) {
    config = config.copyWith(
      gateway: type == 'GW' ? val : null,
      station1: type == 'S1' ? val : null,
      stb: type == 'STB' ? val : null,
      rbWdcp: type == 'RB' ? val : null,
      cctv1: type == 'C1' ? val : null,
      cctv2: type == 'C2' ? val : null,
    );
    notifyListeners();
  }

  /// Update manual IPs text.
  void setManualIps(String value) {
    config = config.copyWith(manualIps: value);
    // Tidak perlu notifyListeners() — UI sudah handle via TextField onChange
  }

  // ── TOGGLE AUTO PING ─────────────────────────────────────────
  Future<void> toggleAutoPing(bool isActive, {bool isAutoReset = false}) async {
    isAutoPingSTBActive = isActive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_ping_stb_active', isActive);

    try {
      await ActivityLogger.logAction(
        actionType: isActive ? 'ENABLE_AUTO_PING' : 'DISABLE_AUTO_PING',
        description: isAutoReset
            ? 'Sistem otomatis mengaktifkan kembali jadwal auto-ping (pukul 23:00 reset)'
            : (isActive
                ? 'Pengguna mengaktifkan jadwal auto-ping otomatis secara manual'
                : 'Pengguna MENONAKTIFKAN jadwal auto-ping otomatis'),
      );
    } catch (e) {
      debugPrint('[PingController] Gagal mencatat log aktivitas: $e');
    }

    notifyListeners();
  }

  /// Memulai background timer penjadwalan.
  /// Timer selalu berjalan untuk mendeteksi kapan jam menunjukkan pukul 23:00
  /// sehingga status auto-ping bisa di-reset kembali ke ON secara otomatis.
  void _startSchedulerTimer() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();

      // ─── 1. RESET OTOMATIS KE ON PADA PUKUL 23:00 ───
      if (now.hour == 23 && now.minute == 0) {
        if (!isAutoPingSTBActive) {
          debugPrint('[Auto Ping] Pukul 23:00 terdeteksi. Mereset penjadwalan otomatis menjadi AKTIF.');
          toggleAutoPing(true, isAutoReset: true);
        }
      }

      // ─── 2. EKSEKUSI AUTO PING JIKA AKTIF (Jam 00:00 - 03:59, Menit 0) ───
      if (isAutoPingSTBActive) {
        if (now.hour >= 0 && now.hour <= 3 && now.minute == 0) {
          if (!_isAutoPingRunning && !isScanning) {
            _runAutoPingRoutine();
          }
        }
      }
    });
  }

  // ── RUTIN AUTO PING ──────────────────────────────────────────
  Future<void> _runAutoPingRoutine() async {
    _isAutoPingRunning = true;

    // Simpan config user saat ini
    final backupConfig = config;

    // Paksa ke STB saja
    config = PingConfig.autoPingSTB;
    notifyListeners();

    await startPing(isAutoRun: true);

    // Pulihkan config user
    config = backupConfig;
    notifyListeners();

    _isAutoPingRunning = false;
  }

  // ── PING MASSAL ──────────────────────────────────────────────
  Future<void> startPing({bool isAutoRun = false}) async {
    if (!config.hasSelection) {
      if (!isAutoRun) {
        notifyWarning('Pilih minimal 1 jenis IP atau isi IP Manual!');
      }
      return;
    }

    // Reset state
    isScanning = true;
    progressValue = 0.0;
    okCount = 0;
    nokCount = 0;
    totalTarget = 0;
    lastFilePath = null;
    statusText = 'Mengambil data toko dari database...';
    scanStartTime = DateTime.now();
    scanEndTime = null;
    notifyListeners();

    try {
      // 1. Fetch targets via repository (bukan langsung Supabase)
      final targetsResult = await _repo.fetchTargets(config);

      if (targetsResult.isError) {
        throw Exception(targetsResult.errorOrNull!.message);
      }

      final targets = targetsResult.dataOrNull!;

      if (targets.isEmpty) throw Exception('Tidak ada IP yang valid.');

      totalTarget = targets.length;
      final List<PingResult> allResults = [];
      int completed = 0;

      // 2. Ping secara konkuren dalam batch (10 target sekaligus) untuk mencegah kongesti jaringan
      const batchSize = 10;
      for (int i = 0; i < totalTarget; i += batchSize) {
        final end = (i + batchSize < totalTarget) ? i + batchSize : totalTarget;
        final batchTargets = targets.sublist(i, end);

        // Eksekusi batch secara paralel
        final batchResults = await Future.wait(
          batchTargets.map((target) async {
            final result = await _executor.pingSingleIP(target);
            
            if (result.isAlive) {
              okCount++;
            } else {
              nokCount++;
            }
            completed++;
            progressValue = completed / totalTarget;
            statusText = 'Mengeksekusi Ping... ($completed / $totalTarget IP)';
            notifyListeners();
            
            return result;
          }),
        );
        allResults.addAll(batchResults);
      }

      // 3. Simpan ke Excel via executor
      statusText = 'Menyimpan hasil ke Excel...';
      notifyListeners();

      final filePath = await _executor.saveToExcel(
        results: allResults,
        outputDir: outputDir,
        isAutoRun: isAutoRun,
      );

      lastFilePath = filePath;

      // 4. Log aktivitas
      await ActivityLogger.logAction(
        actionType: isAutoRun ? 'AUTO_PING' : 'PING',
        description: isAutoRun
            ? 'Sistem Shift 3 otomatis mengeksekusi ping ke $totalTarget IP STB'
            : 'Mengeksekusi ping ke $totalTarget IP Perangkat',
      );

      // 5. Update state selesai
      isScanning = false;
      progressValue = 1.0;
      statusText = 'Selesai! $okCount OK · $nokCount NOK · File: $filePath';
      scanEndTime = DateTime.now();
      config = config.copyWith(manualIps: '');
      notifyListeners();

      if (!isAutoRun) {
        notifySuccess('Ping selesai! File tersimpan di $outputDir');
      }
    } catch (e) {
      isScanning = false;
      statusText = 'Terjadi Kesalahan: $e';
      scanEndTime = DateTime.now();
      config = config.copyWith(manualIps: '');
      notifyListeners();
      if (!isAutoRun) {
        notifyError('Error: $e');
      }
    }
  }

  /// Dispose resources — panggil saat app ditutup.
  void shutdown() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }
}
