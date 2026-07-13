import 'package:flutter/material.dart';
import '../../../../core/utils/notification_mixin.dart';
import '../../../../features/settings/data/settings_repository.dart';
import '../data/stb24jam_service.dart';
import '../data/stb24jam_repository.dart';

/// Stb24JamController — mengelola state dan business logic untuk Stb24JamPage.
///
/// Lokasi: features/network_tools/stb24jam/presentation/stb24jam_controller.dart
///
/// Tanggung jawab:
///   - Mengelola state tanggal terpilih, loading status, dan hasil generate terakhir.
///   - Menghubungkan UI ke Stb24JamService.
///   - Mengirim report ke Telegram via script PowerShell.
///   - Menyampaikan notifikasi (success/error/warning/info) secara global via NotificationMixin.
///
class Stb24JamController extends ChangeNotifier with NotificationMixin {
  final Stb24JamService service = Stb24JamService();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final Stb24JamRepository _historyRepo = Stb24JamRepository();

  // ── Static flags: bertahan meski controller di-dispose/recreate ──
  static bool _isGenerating = false;
  static bool _isReporting = false;

  // ── State ───────────────────────────────────────────────────
  DateTime tanggal = DateTime.now();
  bool loading = _isGenerating; // Sync dari static saat instance baru dibuat
  bool reporting = _isReporting; // Sync dari static saat instance baru dibuat
  GenerateResult? lastResult;
  List<Stb24JamHistoryItem> historyItems = [];
  bool historyLoading = false;

  // ── Cached file paths (resolved async, not in build) ──
  String monthlyPath = '';
  Map<String, String?> pingPaths = {};
  bool hasMissingPingFiles = true; // Default true sampai paths di-resolve
  bool pathsResolved = false;



  // ── History ─────────────────────────────────────────────────

  /// Memuat riwayat aktivitas dari Supabase.
  /// Silent fail - tidak akan crash atau freeze UI jika gagal.
  Future<void> loadHistory() async {
    historyLoading = true;
    try {
      notifyListeners();
    } catch (_) {}

    try {
      final result = await _historyRepo.fetchHistory();
      result.fold(
        (failure) {
          // Silent fail - history bersifat non-critical
          historyItems = [];
        },
        (items) {
          historyItems = items;
        },
      );
    } catch (e) {
      // Catch any unexpected error dan set items kosong
      historyItems = [];
    }

    historyLoading = false;
    try {
      notifyListeners();
    } catch (_) {}
  }

  /// Simpan entri history ke Supabase (silent, non-blocking).
  Future<void> _saveHistory(
    String actionType,
    DateTime tanggal,
    GenerateResult result,
  ) async {
    try {
      await _historyRepo.insertHistory(
        actionType: actionType,
        tanggal: tanggal,
        success: result.success,
        totalToko: result.totalToko,
        totalOk: result.totalOk,
        totalNok: result.totalNok,
        message: result.message,
      );
      await loadHistory();
    } catch (_) {
      // History bersifat non-critical — abaikan error
    }
  }

  /// Menghapus entri riwayat berdasarkan ID.
  Future<bool> deleteHistory(String id) async {
    final result = await _historyRepo.deleteHistory(id);
    return result.fold(
      (failure) {
        notifyError('Gagal menghapus riwayat: ${failure.message}');
        return false;
      },
      (_) {
        notifySuccess('Riwayat berhasil dihapus');
        loadHistory();
        return true;
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Resolve file paths secara asinkron agar tidak memblokir UI thread.
  /// Dipanggil saat init dan saat tanggal berubah.
  Future<void> refreshFilePaths() async {
    pathsResolved = false;
    try {
      notifyListeners();
    } catch (_) {}

    try {
      final date = tanggal;

      // Yield ke event loop dulu agar UI sempat render frame loading
      await Future.delayed(const Duration(milliseconds: 50));

      monthlyPath = service.getMonthlyFilePath(date);
      pingPaths = await service.resolvePingFilePaths(date);
      hasMissingPingFiles = pingPaths.values.any((path) => path == null);
    } catch (e) {
      // Jika gagal resolve, set default aman
      monthlyPath = service.getMonthlyFilePath(tanggal);
      pingPaths = {
        'JAM 00.00': null,
        'JAM 01.00': null,
        'JAM 02.00': null,
        'JAM 03.00': null,
      };
      hasMissingPingFiles = true;
    }

    pathsResolved = true;
    try {
      notifyListeners();
    } catch (_) {}
  }

  /// Mengubah tanggal terpilih.
  void setTanggal(DateTime newDate) {
    tanggal = newDate;
    lastResult = null; // Reset hasil sebelumnya saat tanggal diganti
    notifyListeners();
    refreshFilePaths(); // Re-resolve paths untuk tanggal baru
  }

  /// Memicu proses generate laporan Excel harian STB 24 Jam.
  /// Proses tetap berjalan di background meskipun user pindah halaman.
  Future<void> generate() async {
    if (_isGenerating) return;

    _isGenerating = true;
    loading = true;
    lastResult = null;
    try {
      notifyListeners();
    } catch (_) {}

    // Salin tanggal ke variabel lokal agar tidak menangkap `this` yang unsendable
    final localTanggal = tanggal;

    try {
      notifyInfo('Sedang memproses rekapitulasi data Excel...');

      // Beri kesempatan kepada Flutter untuk menggambar frame indikator loading terlebih dahulu
      await Future.delayed(const Duration(milliseconds: 150));

      // Jalankan proses pembacaan & penulisan Excel secara langsung
      // karena generateDailySheet sudah berjalan asinkron menggunakan Process.run (non-blocking)
      final result = await service.generateDailySheet(localTanggal);

      lastResult = result;
      await _saveHistory('generate', localTanggal, result);

      if (result.success) {
        notifySuccess(result.message);
      } else {
        notifyError(result.message);
      }
    } catch (e) {
      notifyError('Terjadi kesalahan: $e');
    } finally {
      _isGenerating = false;
      loading = false;
      try {
        notifyListeners();
      } catch (_) {}
    }
  }

  /// Mengirim report STB 24 Jam ke grup Telegram.
  /// Proses ini tetap berjalan di background meskipun user pindah halaman.
  /// Notifikasi global (snackbar) tetap muncul berkat NotificationMixin
  /// yang sudah di-guard terhadap dispose.
  Future<void> report() async {
    if (_isReporting) return;

    _isReporting = true;
    reporting = true;
    try {
      notifyListeners();
    } catch (_) {}

    final localTanggal = tanggal;

    try {
      notifyInfo('Mengambil konfigurasi Telegram...');
      await Future.delayed(const Duration(milliseconds: 150));

      // Ambil Bot Token & Chat ID dari Supabase settings
      final settingsResult = await _settingsRepo.fetchAppSettings();

      // Gunakan variabel untuk menangkap hasil fold (bukan return di closure)
      String? errorMsg;
      String botToken = '';
      String chatId = '';

      settingsResult.fold(
        (failure) {
          errorMsg = 'Gagal mengambil konfigurasi: ${failure.message}';
        },
        (data) {
          botToken = data['telegram_bot_token'] ?? '';
          chatId = data['telegram_chat_id'] ?? '';
        },
      );

      // Cek apakah fetch gagal
      if (errorMsg != null) {
        notifyError(errorMsg!);
        return;
      }

      if (botToken.isEmpty || chatId.isEmpty) {
        notifyError(
          'Bot Token atau Chat ID belum dikonfigurasi.\n'
          'Silakan isi di halaman Settings → Konfigurasi Telegram Bot.',
        );
        return;
      }

      notifyInfo('📤 Mengirim report ke Telegram...');

      final result = await service.reportToTelegram(
        tanggal: localTanggal,
        botToken: botToken,
        chatId: chatId,
      );

      await _saveHistory('report', localTanggal, result);

      // Tetap tampilkan notifikasi meskipun user sudah pindah halaman
      if (result.success) {
        notifySuccess(result.message);
      } else {
        notifyError(result.message);
      }
    } catch (e) {
      notifyError('Terjadi kesalahan: $e');
    } finally {
      _isReporting = false;
      reporting = false;
      try {
        notifyListeners();
      } catch (_) {}
    }
  }
}
