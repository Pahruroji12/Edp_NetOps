import 'dart:async';
import 'dart:io';

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
    final savedState = prefs.getBool('auto_ping_stb_active') ?? true;
    if (savedState) {
      _enableAutoPing();
    } else {
      _disableAutoPing();
    }
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
  Future<void> toggleAutoPing(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    if (isActive) {
      _enableAutoPing();
    } else {
      _disableAutoPing();
    }
    await prefs.setBool('auto_ping_stb_active', isActive);
    notifyListeners();
  }

  void _enableAutoPing() {
    isAutoPingSTBActive = true;
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      // Rentang jam 00:00 - 03:59, cek menit 0
      if (now.hour >= 0 && now.hour <= 3 && now.minute == 0) {
        if (!_isAutoPingRunning && !isScanning) {
          _runAutoPingRoutine();
        }
      }
    });
  }

  void _disableAutoPing() {
    isAutoPingSTBActive = false;
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
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
    statusText = 'Mengambil data toko dari database...';
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

      // 2. Ping satu per satu via executor
      for (int i = 0; i < totalTarget; i++) {
        final result = await _executor.pingSingleIP(targets[i]);
        allResults.add(result);

        if (result.isAlive) {
          okCount++;
        } else {
          nokCount++;
        }

        completed++;
        progressValue = completed / totalTarget;
        statusText = 'Mengeksekusi Ping... ($completed / $totalTarget IP)';
        notifyListeners();
      }

      // 3. Simpan ke CSV via executor
      statusText = 'Menyimpan hasil ke CSV...';
      notifyListeners();

      final filePath = await _executor.saveToCsv(
        results: allResults,
        outputDir: outputDir,
        isAutoRun: isAutoRun,
      );

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
      notifyListeners();

      if (!isAutoRun) {
        notifySuccess('Ping selesai! File tersimpan di $outputDir');
      }
    } catch (e) {
      isScanning = false;
      statusText = 'Terjadi Kesalahan: $e';
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
