import 'package:edp_netops/core/platform/native_io.dart';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../domain/ping_result.dart';

/// PingExecutor — menjalankan ping via Process.run dan menyimpan CSV.
///
/// Lokasi: features/network_tools/ping/data/ping_executor.dart
///
/// Tanggung jawab:
///   - Eksekusi `ping` OS-level ke satu IP
///   - Simpan hasil ke file CSV
///
/// TIDAK BOLEH:
///   - Import Flutter/Material
///   - Extend ChangeNotifier
///   - Menampilkan Snackbar
///   - Query Supabase
///
class PingExecutor {
  /// Ping satu IP dan return [PingResult].
  ///
  /// Mengganti `_pingSingleIP` dari PingService lama.
  /// Return type sekarang typed (bukan List<dynamic>).
  Future<PingResult> pingSingleIP(PingTarget target,
      {int timeoutMs = 3000}) async {
    bool isAlive = false;

    try {
      final result = await Process.run(
        'ping',
        ['-n', '1', '-w', '$timeoutMs', target.ip],
      );
      if (result.stdout.toString().toLowerCase().contains('ttl=')) {
        isAlive = true;
      }
    } catch (_) {
      isAlive = false;
    }

    return PingResult(
      storeName: target.storeName,
      deviceType: target.deviceType,
      ip: target.ip,
      isAlive: isAlive,
      timestamp: DateTime.now(),
    );
  }

  /// Simpan hasil ping ke file CSV.
  ///
  /// Return: path file CSV yang tersimpan.
  /// Throws: Exception jika gagal menulis file.
  Future<String> saveToCsv({
    required List<PingResult> results,
    required String outputDir,
    bool isAutoRun = false,
  }) async {
    // Header CSV (sama format dengan versi lama)
    final List<List<dynamic>> csvData = [
      ['Nama Toko', 'Jenis Perangkat', 'IP Address', 'Status', 'Waktu Pengecekan'],
    ];

    // Data rows
    for (final result in results) {
      csvData.add(result.toCsvRow());
    }

    // Pastikan direktori ada
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Generate filename (sama format dengan versi lama)
    final timestamp = DateFormat('ddMMyyyy_HHmm').format(DateTime.now());
    final prefix = isAutoRun ? 'AutoPing_STB' : 'Hasil_Ping';
    final filePath = '${dir.path}\\${prefix}_$timestamp.csv';

    // Tulis CSV
    final csvContent = const ListToCsvConverter().convert(csvData);
    await File(filePath).writeAsString(csvContent);

    return filePath;
  }

  /// Cek apakah output directory bisa diakses.
  ///
  /// Berguna untuk validasi sebelum mulai ping.
  static bool isOutputDirAccessible(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
