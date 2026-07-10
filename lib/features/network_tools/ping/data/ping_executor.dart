import 'package:edp_netops/core/platform/native_io.dart';

import 'package:excel/excel.dart' hide Border;
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
      storeCode: target.storeCode,
      storeName: target.storeName,
      deviceType: target.deviceType,
      ip: target.ip,
      isAlive: isAlive,
      timestamp: DateTime.now(),
    );
  }

  /// Simpan hasil ping ke file Excel (.xlsx).
  ///
  /// Return: path file Excel yang tersimpan.
  /// Throws: Exception jika gagal menulis file.
  Future<String> saveToExcel({
    required List<PingResult> results,
    required String outputDir,
    bool isAutoRun = false,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Hasil Ping'];
    excel.setDefaultSheet('Hasil Ping');

    // Hapus sheet default bawaan library jika ada
    excel.delete('Sheet1');

    // Style header reusable
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('000000'),
      backgroundColorHex: ExcelColor.fromHexString('D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // List header kolom
    final headers = ['No', 'Kode Toko', 'Nama Toko', 'Jenis Perangkat', 'IP Address', 'Status', 'Waktu Pengecekan'];

    // Tulis header ke sheet
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    final centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
    );

    // Tulis baris data
    final timeFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    for (int r = 0; r < results.length; r++) {
      final res = results[r];
      final row = [
        '${r + 1}',
        res.storeCode,
        res.storeName,
        res.deviceType,
        res.ip,
        res.statusLabel,
        timeFmt.format(res.timestamp.toLocal()),
      ];

      for (int c = 0; c < row.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        cell.value = TextCellValue(row[c]);

        // Berikan styling khusus berdasarkan kolom (No, Kode Toko, IP Address, Status, Waktu Pengecekan diratakan tengah)
        if (c == 0 || c == 1 || c == 4 || c == 5 || c == 6) {
          cell.cellStyle = centerStyle;
        }
      }
    }

    // Atur lebar kolom agar tidak terpotong dan terlihat rapi
    final colWidths = [6.0, 12.0, 30.0, 20.0, 16.0, 12.0, 22.0];
    for (int i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i]);
    }

    // Pastikan direktori tujuan ekspor ada
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Generate nama file
    final timestamp = DateFormat('ddMMyyyy_HHmm').format(DateTime.now());
    final prefix = isAutoRun ? 'AutoPing_STB' : 'Hasil_Ping';
    final filePath = '${dir.path}\\${prefix}_$timestamp.xlsx';

    // Simpan bytes file Excel
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Gagal generate file Excel');
    }
    await File(filePath).writeAsBytes(bytes);

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
