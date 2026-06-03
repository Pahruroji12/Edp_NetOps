import '../platform/native_io.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../features/store/domain/store_model.dart';
import '../services/activity_logger.dart';
import '../platform/platform_helper.dart';

/// ExportHelper — export data ke file Excel (.xlsx).
///
/// Lokasi: core/utils/export_helper.dart
///
class ExportHelper {
  // ── Style header reusable ────────────────────────────────────
  static CellStyle get _headerStyle => CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('000000'),
    backgroundColorHex: ExcelColor.fromHexString('D9D9D9'),
    horizontalAlign: HorizontalAlign.Center,
  );

  // ── Helper: tulis baris header ke sheet ─────────────────────
  static void _writeHeaders(Sheet sheet, List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _headerStyle;
    }
  }

  // ── Helper: simpan bytes Excel (Windows: Downloads, Mobile: Share) ──
  static Future<String> _saveExcel({
    required Excel excelFile,
    required String fileName,
    required int itemCount,
    required String logDescription,
  }) async {
    excelFile.delete('Sheet1');
    final bytes = excelFile.save();
    if (bytes == null) throw Exception('Gagal generate file Excel');

    final uint8Bytes = Uint8List.fromList(bytes);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fullName = '${fileName}_$timestamp';

    if (PlatformHelper.isWindows) {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null)
        throw Exception('Folder Downloads tidak ditemukan');
      final filePath = '${downloadsDir.path}\\$fullName.xlsx';
      await File(filePath).writeAsBytes(uint8Bytes);
      await ActivityLogger.logAction(
        actionType: 'EXPORT_DATA',
        description: logDescription,
      );
      Process.run('explorer.exe', ['/select,', filePath]);
      return 'Berhasil! File disimpan di folder Downloads';
    } else {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fullName.xlsx';
      await File(filePath).writeAsBytes(uint8Bytes);
      await ActivityLogger.logAction(
        actionType: 'EXPORT_DATA',
        description: logDescription,
      );
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Berikut lampiran export data terbaru.');
      return 'Menu bagikan (Share) dibuka';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // EXPORT DATA TOKO
  // ══════════════════════════════════════════════════════════════
  static Future<String> exportToCSV(List<StoreModel> stores) async {
    try {
      final excelFile = Excel.createExcel();
      final sheet = excelFile['Data Toko'];
      excelFile.setDefaultSheet('Data Toko');

      _writeHeaders(sheet, [
        'Kode Toko',
        'Nama Toko',
        'Koneksi Utama',
        'Koneksi Backup',
        'IP Gateway',
        'IP VSAT',
        'IP RB WDCP',
        'IP Station 1',
        'IP Station 2',
        'IP Station 3',
        'IP Station 4',
        'IP Station 5',
        'IP STB',
        'IP iKiosk',
        'IP Timbangan',
        'IP CCTV 1',
        'IP CCTV 2',
      ]);

      for (int r = 0; r < stores.length; r++) {
        final s = stores[r];
        final row = [
          s.storeCode,
          s.storeName,
          s.connectionType ?? '-',
          s.connectionBackup ?? '-',
          s.ipGateway ?? '-',
          s.ipVsat ?? '-',
          s.ipRbWdcp ?? '-',
          s.ipStation1 ?? '-',
          s.ipStation2 ?? '-',
          s.ipStation3 ?? '-',
          s.ipStation4 ?? '-',
          s.ipStation5 ?? '-',
          s.ipStb ?? '-',
          s.ipIkiosk ?? '-',
          s.ipTimbangan ?? '-',
          s.ipCctv1 ?? '-',
          s.ipCctv2 ?? '-',
        ];
        for (int c = 0; c < row.length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
              .value = TextCellValue(
            row[c],
          );
        }
      }

      final colWidths = [
        10.0,
        30.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
        14.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        sheet.setColumnWidth(i, colWidths[i]);
      }

      return _saveExcel(
        excelFile: excelFile,
        fileName: 'Data_Toko',
        itemCount: stores.length,
        logDescription: 'Mengekspor ${stores.length} toko ke Excel',
      );
    } catch (e) {
      throw Exception('Gagal mengekspor data: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // EXPORT HISTORY TIKET  (2 sheet: History + Sering Gangguan)
  // ══════════════════════════════════════════════════════════════
  static Future<String> exportTicketHistory({
    required List<Map<String, dynamic>> filtered,
    required List<Map<String, dynamic>> allTickets,
    required List<Map<String, dynamic>> ranking,
  }) async {
    try {
      final excelFile = Excel.createExcel();
      final fmt = DateFormat('dd/MM/yyyy HH:mm');

      // ── Sheet 1: History Tiket ───────────────────────────────
      final s1 = excelFile['History Tiket'];
      excelFile.setDefaultSheet('History Tiket');
      _writeHeaders(s1, [
        'No',
        'Tgl Open',
        'Kode Toko',
        'Nama Toko',
        'Provider',
        'Nomor Tiket',
        'Status',
        'Oleh',
        'Keterangan',
      ]);
      for (int r = 0; r < filtered.length; r++) {
        final t = filtered[r];
        final row = [
          '${r + 1}',
          t['created_at'] != null
              ? fmt.format(DateTime.parse(t['created_at']).toLocal())
              : '',
          t['store_code'] ?? '',
          t['store_name'] ?? '',
          t['provider'] ?? '',
          t['nomor_tiket'] ?? '-',
          t['status'] ?? '',
          ((t['created_by'] ?? '') as String).contains('@')
              ? (t['created_by'] as String).split('@').first
              : (t['created_by'] ?? ''),
          t['keterangan'] ?? '-',
        ];
        for (int c = 0; c < row.length; c++) {
          s1
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
              .value = TextCellValue(
            row[c],
          );
        }
      }
      final s1Widths = [5.0, 18.0, 12.0, 30.0, 12.0, 20.0, 14.0, 14.0, 25.0];
      for (int i = 0; i < s1Widths.length; i++) {
        s1.setColumnWidth(i, s1Widths[i]);
      }

      // ── Sheet 2: Sering Gangguan ─────────────────────────────
      final s2 = excelFile['Sering Gangguan'];
      _writeHeaders(s2, [
        'Rank',
        'Kode Toko',
        'Nama Toko',
        'Total',
        'Open',
        'In Progress',
        'Resolved',
      ]);
      for (int r = 0; r < ranking.length; r++) {
        final item = ranking[r];
        final row2 = [
          '${r + 1}',
          item['store_code'] as String,
          item['store_name'] as String,
          '${item['total']}',
          '${item['open']}',
          '${item['in_progress']}',
          '${item['resolved']}',
        ];
        for (int c = 0; c < row2.length; c++) {
          s2
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
              .value = TextCellValue(
            row2[c],
          );
        }
      }
      final s2Widths = [6.0, 12.0, 32.0, 8.0, 8.0, 14.0, 10.0];
      for (int i = 0; i < s2Widths.length; i++) {
        s2.setColumnWidth(i, s2Widths[i]);
      }

      return _saveExcel(
        excelFile: excelFile,
        fileName: 'Rekap_Tiket',
        itemCount: filtered.length,
        logDescription:
            'Mengekspor ${filtered.length} tiket ke Excel (2 sheet)',
      );
    } catch (e) {
      throw Exception('Gagal mengekspor tiket: $e');
    }
  }
}
