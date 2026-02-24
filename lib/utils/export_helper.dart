import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/store_model.dart';
import 'activity_logger.dart';
import 'package:intl/intl.dart';

class ExportHelper {
  // Sekarang fungsinya mengembalikan String pesan sukses
  static Future<String> exportToCSV(List<StoreModel> stores) async {
    try {
      // 1. Buat Baris Header
      List<List<dynamic>> rows = [];
      rows.add([
        "Kode Toko",
        "Nama Toko",
        "Koneksi Utama",
        "Koneksi Backup",
        "IP Gateway",
        "IP VSAT",
        "IP RB WDCP",
        "IP Station 1",
        "IP Station 2",
        "IP Station 3",
        "IP Station 4",
        "IP Station 5",
        "IP STB",
        "IP iKiosk",
        "IP Timbangan",
        "IP CCTV 1",
        "IP CCTV 2",
      ]);

      // 2. Masukkan Data Toko
      for (var store in stores) {
        rows.add([
          store.storeCode,
          store.storeName,
          store.connectionType ?? '-',
          store.connectionBackup ?? '-',
          store.ipGateway ?? '-',
          store.ipVsat ?? '-',
          store.ipRbWdcp ?? '-',
          store.ipStation1 ?? '-',
          store.ipStation2 ?? '-',
          store.ipStation3 ?? '-',
          store.ipStation4 ?? '-',
          store.ipStation5 ?? '-',
          store.ipStb ?? '-',
          store.ipIkiosk ?? '-',
          store.ipTimbangan ?? '-',
          store.ipCctv1 ?? '-',
          store.ipCctv2 ?? '-',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());

      // 3. DETEKSI PERANGKAT (Windows atau HP)
      if (Platform.isWindows) {
        // --- LOGIKA WINDOWS (Desktop) ---
        final Directory? downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null)
          throw Exception("Folder Downloads tidak ditemukan");

        // Simpan ke folder Downloads
        final String filePath =
            '${downloadsDir.path}\\Data Toko_$timestamp.csv';
        final File file = File(filePath);
        await file.writeAsString(csvData);

        await ActivityLogger.logAction(
          actionType: "EXPORT_DATA",
          description: "Mengekspor ${stores.length} toko ke folder Downloads",
        );

        // Fitur Sultan: Buka Windows Explorer dan sorot file yang baru dibuat
        Process.run('explorer.exe', ['/select,', filePath]);

        return "Berhasil! File disimpan di folder Downloads";
      } else {
        // --- LOGIKA MOBILE (Android/iOS) ---
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/Data Toko_$timestamp.csv';

        final File file = File(filePath);
        await file.writeAsString(csvData);

        await ActivityLogger.logAction(
          actionType: "EXPORT_DATA",
          description: "Mengekspor data ${stores.length} toko ke format CSV",
        );

        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Berikut lampiran Export Data Toko terbaru.');

        return "Menu bagikan (Share) dibuka";
      }
    } catch (e) {
      throw Exception("Gagal mengekspor data: $e");
    }
  }
}
