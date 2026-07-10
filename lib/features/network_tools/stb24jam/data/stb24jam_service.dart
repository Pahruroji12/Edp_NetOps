// ============================================================================
// STB 24 JAM - SERVICE
// ----------------------------------------------------------------------------
// Modul ini menggabungkan:
//   1. Data master toko (dari sheet "Master" di file STB 24 Jam bulanan)
//   2. 4 file hasil ping (jam 00, 01, 02, 03) dari folder Hasil Ping
//   3. Data 3 hari sebelumnya (kolom CEK) yang sudah ada di sheet² sebelumnya
//      di file bulanan yang sama
//   4. OPR & Keterangan di-carry-over dari sheet hari kemarin (H-1)
//
// Hasil akhirnya: sheet baru (nama sheet = tanggal, misal "10") ditulis
// LANGSUNG SEBAGAI VALUE (bukan formula) ke file bulanan yang sudah ada,
// supaya tidak merusak external link/formula yang sudah ada di sheet lain.
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';

/// ============================== MODELS =====================================

class TokoMaster {
  final String kodeToko;
  final String namaToko;
  final String koneksiUtama;
  final String koneksiBackup;
  final String ipAddress;

  TokoMaster({
    required this.kodeToko,
    required this.namaToko,
    required this.koneksiUtama,
    required this.koneksiBackup,
    required this.ipAddress,
  });
}

class DayCarryOver {
  final Map<String, String> cekByToko; // Toko -> CEK (OK/NOK)
  final Map<String, String> oprByToko; // Toko -> OPR
  final Map<String, String> ketByToko; // Toko -> Keterangan

  DayCarryOver({
    required this.cekByToko,
    required this.oprByToko,
    required this.ketByToko,
  });

  static DayCarryOver empty() =>
      DayCarryOver(cekByToko: {}, oprByToko: {}, ketByToko: {});
}

class GenerateResult {
  final bool success;
  final String message;
  final int totalToko;
  final int totalOk;
  final int totalNok;
  final List<String> tokoTanpaDataPing;

  GenerateResult({
    required this.success,
    required this.message,
    this.totalToko = 0,
    this.totalOk = 0,
    this.totalNok = 0,
    this.tokoTanpaDataPing = const [],
  });
}

/// ============================== SERVICE =====================================

class Stb24JamService {
  // ---------------------------------------------------------------------
  // KONFIGURASI PATH — Dinamis dan konsisten dengan PingController
  // ---------------------------------------------------------------------
  String get hasilPingFolder {
    const preferred = AppConstants.pingOutputDir;
    if (Directory(r'D:\').existsSync()) return preferred;
    return '${Platform.environment['USERPROFILE']}\\Documents\\Edp NetOps\\Hasil Ping';
  }

  String get rekapFolderRoot {
    const preferred = AppConstants.stb24JamRekapDir;
    if (Directory(r'D:\').existsSync()) return preferred;
    return '${Platform.environment['USERPROFILE']}\\Documents\\Rekap Ping STB 24 Jam';
  }

  static const List<String> _namaBulan = [
    'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
    'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER',
  ];

  /// Contoh: D:\Rekap Ping STB 24 Jam\2026\STB 24 JAM JULI.xlsx
  String getMonthlyFilePath(DateTime tanggal) {
    final tahun = tanggal.year.toString();
    final bulan = _namaBulan[tanggal.month - 1];
    return '$rekapFolderRoot\\$tahun\\STB 24 JAM $bulan.xlsx';
  }

  /// Mencari file ping secara dinamis di [hasilPingFolder] berdasarkan [tanggal].
  /// Mengembalikan Map yang berisi nama jam dan path file asli yang ditemukan.
  /// 4 file hasil ping untuk 1 tanggal — di-SCAN dari folder, bukan ditebak
  /// nama persisnya. Nama file punya pola: AutoPing_STB_{ddMMyyyy}_XXYY.xlsx
  /// di mana XX = jam (00/01/02/03) dan YY = nomor run/attempt yang BISA
  /// BERUBAH-UBAH tiap hari (tidak selalu "01"). Jadi kita cocokkan cuma
  /// berdasarkan 2 digit jam di depan, dan kalau ada beberapa file untuk
  /// jam yang sama, ambil yang terakhir dimodifikasi.
  ///
  /// Return value: null kalau file untuk jam tsb tidak ditemukan.
  Map<String, String?> resolvePingFilePaths(DateTime tanggal) {
    final ddMMyyyy = DateFormat('ddMMyyyy').format(tanggal);
    final result = <String, String?>{
      'JAM 00.00': null,
      'JAM 01.00': null,
      'JAM 02.00': null,
      'JAM 03.00': null,
    };

    final dir = Directory(hasilPingFolder);
    if (!dir.existsSync()) return result;

    final pattern = RegExp(
      '^AutoPing_STB_${ddMMyyyy}_(\\d{2})\\d{2}\\.xlsx\$',
      caseSensitive: false,
    );

    final candidates = <String, File>{}; // jamKey -> file terpilih sejauh ini

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final match = pattern.firstMatch(name);
      if (match == null) continue;

      final jamPrefix = match.group(1)!; // '00' / '01' / '02' / '03'
      final jamKey = _jamKeyFromPrefix(jamPrefix);
      if (jamKey == null) continue;

      final existing = candidates[jamKey];
      if (existing == null ||
          entity.lastModifiedSync().isAfter(existing.lastModifiedSync())) {
        candidates[jamKey] = entity;
      }
    }

    candidates.forEach((jamKey, file) => result[jamKey] = file.path);
    return result;
  }

  String? _jamKeyFromPrefix(String prefix) {
    switch (prefix) {
      case '00':
        return 'JAM 00.00';
      case '01':
        return 'JAM 01.00';
      case '02':
        return 'JAM 02.00';
      case '03':
        return 'JAM 03.00';
      default:
        return null;
    }
  }
  String _resolveScriptPath() {
    final sep = Platform.pathSeparator;
    // 1. Cek di samping executable (release / production)
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final exeScript = File('$exeDir${sep}assets${sep}generate_stb24jam.ps1');
    if (exeScript.existsSync()) return exeScript.path;
    
    // 2. Cek di root project (development / debug)
    final cwdDir = Directory.current.path;
    final cwdScript = File('$cwdDir${sep}assets${sep}generate_stb24jam.ps1');
    if (cwdScript.existsSync()) return cwdScript.path;
    
    // Fallback
    return '$cwdDir${sep}assets${sep}generate_stb24jam.ps1';
  }

  Future<GenerateResult> generateDailySheet(DateTime tanggal) async {
    final scriptPath = _resolveScriptPath();
    if (!File(scriptPath).existsSync()) {
      return GenerateResult(
        success: false,
        message: 'Script generator tidak ditemukan di:\n$scriptPath',
      );
    }

    final monthlyPath = getMonthlyFilePath(tanggal);
    final monthlyFile = File(monthlyPath);
    if (!monthlyFile.existsSync()) {
      return GenerateResult(
        success: false,
        message: 'File bulanan tidak ditemukan:\n$monthlyPath',
      );
    }

    final formattedDate = '${tanggal.day.toString().padLeft(2, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.year}';

    try {
      final processResult = await Process.run(
        'powershell.exe',
        [
          '-ExecutionPolicy', 'Bypass',
          '-File', scriptPath,
          '-TanggalStr', formattedDate,
          '-MonthlyFile', monthlyPath,
          '-HasilPingFolder', hasilPingFolder,
        ],
        runInShell: true,
      );

      final stdout = processResult.stdout.toString().trim();
      final stderr = processResult.stderr.toString().trim();

      if (processResult.exitCode != 0) {
        // Coba cari JSON di output jika ada
        try {
          final lines = stdout.split('\n');
          final lastLine = lines.lastWhere((l) => l.trim().startsWith('{') && l.trim().endsWith('}'));
          final jsonMap = jsonDecode(lastLine) as Map<String, dynamic>;
          return GenerateResult(
            success: false,
            message: jsonMap['message'] ?? 'PowerShell process failed with code ${processResult.exitCode}',
          );
        } catch (_) {}
        
        return GenerateResult(
          success: false,
          message: 'Gagal menjalankan script Excel COM.\n'
              'Exit Code: ${processResult.exitCode}\n'
              'Error: ${stderr.isNotEmpty ? stderr : stdout}',
        );
      }

      // Parse JSON dari output
      try {
        final lines = stdout.split('\r\n').expand((l) => l.split('\n')).toList();
        final lastLine = lines.lastWhere((l) => l.trim().startsWith('{') && l.trim().endsWith('}'));
        final jsonMap = jsonDecode(lastLine.trim()) as Map<String, dynamic>;

        final bool success = jsonMap['success'] ?? false;
        final String message = jsonMap['message'] ?? '';

        if (!success) {
          return GenerateResult(success: false, message: message);
        }

        final List<dynamic> tanpaDataRaw = jsonMap['tokoTanpaDataPing'] ?? [];
        final List<String> tanpaData = tanpaDataRaw.map((e) => e.toString()).toList();

        return GenerateResult(
          success: true,
          message: message,
          totalToko: jsonMap['totalToko'] ?? 0,
          totalOk: jsonMap['totalOk'] ?? 0,
          totalNok: jsonMap['totalNok'] ?? 0,
          tokoTanpaDataPing: tanpaData,
        );
      } catch (e) {
        return GenerateResult(
          success: false,
          message: 'Gagal menafsirkan output JSON dari script.\n'
              'Detail: $e\n'
              'Raw Output: $stdout',
        );
      }
    } catch (e) {
      return GenerateResult(
        success: false,
        message: 'Gagal memanggil proses PowerShell: $e',
      );
    }
  }
}
