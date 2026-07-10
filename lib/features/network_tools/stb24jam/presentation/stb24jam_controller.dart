import 'package:flutter/material.dart';
import '../../../../core/utils/notification_mixin.dart';
import '../data/stb24jam_service.dart';

/// Stb24JamController — mengelola state dan business logic untuk Stb24JamPage.
///
/// Lokasi: features/network_tools/stb24jam/presentation/stb24jam_controller.dart
///
/// Tanggung jawab:
///   - Mengelola state tanggal terpilih, loading status, dan hasil generate terakhir.
///   - Menghubungkan UI ke Stb24JamService.
///   - Menyampaikan notifikasi (success/error/warning/info) secara global via NotificationMixin.
///
class Stb24JamController extends ChangeNotifier with NotificationMixin {
  final Stb24JamService service = Stb24JamService();

  // ── State ───────────────────────────────────────────────────
  DateTime tanggal = DateTime.now();
  bool loading = false;
  GenerateResult? lastResult;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  /// Mengubah tanggal terpilih.
  void setTanggal(DateTime newDate) {
    tanggal = newDate;
    lastResult = null; // Reset hasil sebelumnya saat tanggal diganti
    notifyListeners();
  }

  /// Memicu proses generate laporan Excel harian STB 24 Jam.
  Future<void> generate() async {
    if (loading) return;

    loading = true;
    lastResult = null;
    notifyListeners();

    // Salin tanggal ke variabel lokal agar tidak menangkap `this` yang unsendable
    final localTanggal = tanggal;

    try {
      notifyInfo('Sedang memproses rekapitulasi data Excel...');

      // Beri kesempatan kepada Flutter untuk menggambar frame indikator loading terlebih dahulu
      await Future.delayed(const Duration(milliseconds: 150));

      // Jalankan proses pembacaan & penulisan Excel secara langsung
      // karena generateDailySheet sudah berjalan asinkron menggunakan Process.run (non-blocking)
      final result = await service.generateDailySheet(localTanggal);

      if (_disposed) return;

      lastResult = result;

      if (result.success) {
        notifySuccess(result.message);
      } else {
        notifyError(result.message);
      }
    } catch (e) {
      if (_disposed) return;
      notifyError('Terjadi kesalahan: $e');
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }
}
