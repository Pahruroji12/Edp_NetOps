import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/platform/native_io.dart';
import '../../../../core/utils/notification_mixin.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/tool_helper.dart';
import '../../../settings/data/settings_repository.dart';

class SlaScraperController extends ChangeNotifier with NotificationMixin {
  static final SlaScraperController instance = SlaScraperController._internal();

  final SettingsRepository _settingsRepo = SettingsRepository();

  SlaScraperController._internal();

  // ── States ───────────────────────────────────────────────────
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String reportType = 'dispensasi'; // Opsi: 'dispensasi' / 'detail-cabang'

  bool isRunning = false;
  List<String> logLines = [];
  List<SlaGeneratedFile> generatedFiles = [];

  bool credentialsExist = false;
  String slaUsername = '';
  String slaPassword = '';

  Process? _process;

  // ── Getters ──────────────────────────────────────────────────
  bool get hasRetentionWarning {
    final daysAgo = DateTime.now().difference(startDate).inDays;
    return daysAgo > 4;
  }

  // ── Inisialisasi ────────────────────────────────────────────
  Future<void> init() async {
    await loadCredentials();
    await refreshFiles();
  }

  // ── Form Actions ─────────────────────────────────────────────
  void setStartDate(DateTime date) {
    startDate = date;
    if (endDate.isBefore(startDate)) {
      endDate = startDate;
    }
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    if (date.isBefore(startDate)) {
      notifyWarning('Tanggal Akhir tidak boleh lebih awal dari Tanggal Awal.');
      return;
    }
    endDate = date;
    notifyListeners();
  }

  void setReportType(String type) {
    reportType = type;
    notifyListeners();
  }

  // ── Load Credentials ─────────────────────────────────────────
  Future<void> loadCredentials() async {
    final result = await _settingsRepo.fetchAppSettings();
    result.fold(
      (failure) {
        // Fallback sementara jika koneksi database gagal / VPN aktif
        slaUsername = 'EDP LBK';
        slaPassword = 'EDP123LBK';
        credentialsExist = true;
        notifyListeners();
      },
      (data) {
        final dbUser = data['sla_username'] ?? '';
        final dbPass = data['sla_password'] ?? '';
        if (dbUser.isEmpty || dbPass.isEmpty) {
          // Fallback jika belum di-set di DB
          slaUsername = 'EDP LBK';
          slaPassword = 'EDP123LBK';
        } else {
          slaUsername = dbUser;
          slaPassword = dbPass;
        }
        credentialsExist = true;
        notifyListeners();
      },
    );
  }

  // ── Refresh Files ────────────────────────────────────────────
  Future<void> refreshFiles() async {
    try {
      final dir = Directory(AppConstants.slaReportOutputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final List<FileSystemEntity> list = await dir.list().toList();
      final files = list
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.xlsx'));

      final List<SlaGeneratedFile> mappedList = [];
      for (final file in files) {
        try {
          final stat = await file.stat();
          final name = file.path.split('\\').last;
          mappedList.add(SlaGeneratedFile(
            file: file,
            name: name,
            isDispensasi: name.contains('Dispensasi'),
            modified: stat.modified,
            sizeInBytes: stat.size,
          ));
        } catch (_) {}
      }

      // Urutkan file terbaru ke terlama
      mappedList.sort((a, b) => b.modified.compareTo(a.modified));

      generatedFiles = mappedList;
      notifyListeners();
    } catch (e) {
      debugPrint('[SlaScraperController] Gagal memuat daftar file: $e');
    }
  }

  // ── Clean Logs ───────────────────────────────────────────────
  void clearLogs() {
    logLines.clear();
    notifyListeners();
  }

  // ── Run Scraper ──────────────────────────────────────────────
  Future<void> startScraping() async {
    if (isRunning) return;

    isRunning = true;
    logLines.clear();
    logLines.add('Menyiapkan koneksi dan menjalankan program scraper...');
    notifyListeners();

    try {
      // Load credentials terbaru sebelum jalan
      await loadCredentials();

      if (!credentialsExist) {
        notifyError('Harap lengkapi Kredensial Login SLA di Pengaturan Sistem terlebih dahulu.');
        isRunning = false;
        notifyListeners();
        return;
      }

      // Pastikan folder output ada
      final outputDir = Directory(AppConstants.slaReportOutputDir);
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final exePath = await ToolHelper.getSlaScraperPath();
      final exeFile = File(exePath);
      if (!exeFile.existsSync()) {
        notifyError('Program sla_scraper.exe tidak ditemukan di: $exePath');
        isRunning = false;
        notifyListeners();
        return;
      }

      final df = DateFormat('dd-MM-yyyy');
      final dateStr = DateFormat('yyyyMMdd').format(startDate);
      final dateEndStr = DateFormat('yyyyMMdd').format(endDate);

      final firstDateParam = df.format(startDate);
      final lastDateParam = df.format(endDate);

      final suffix = reportType == 'dispensasi' ? 'Dispensasi' : 'Detail_Cabang';
      final baseFileName = 'Report_${suffix}_G157_${dateStr.replaceAll('-', '')}_${dateEndStr.replaceAll('-', '')}';
      
      String fileName = '$baseFileName.xlsx';
      String outputFilePath = '${AppConstants.slaReportOutputDir}\\$fileName';
      
      int counter = 1;
      while (File(outputFilePath).existsSync()) {
        fileName = '${baseFileName}_$counter.xlsx';
        outputFilePath = '${AppConstants.slaReportOutputDir}\\$fileName';
        counter++;
      }

      final arguments = [
        '--username', slaUsername,
        '--password', slaPassword,
        '--first-date', firstDateParam,
        '--last-date', lastDateParam,
        '--dc-code', 'G157',
        '--output-format', 'xlsx',
        '--report-type', reportType,
        '--output-file', outputFilePath,
      ];

      _process = await Process.start(exePath, arguments);

      // Stream stdout
      _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          logLines.add(line.trim());
          notifyListeners();
        }
      });

      // Stream stderr
      _process!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          logLines.add(line.trim());
          notifyListeners();
        }
      });

      final exitCode = await _process!.exitCode;
      isRunning = false;
      _process = null;

      if (exitCode == 0) {
        notifySuccess('Laporan SLA berhasil digenerate!');
      } else {
        notifyError('Proses scraper gagal dengan exit code $exitCode');
      }

      await refreshFiles();
    } catch (e) {
      isRunning = false;
      _process = null;
      logLines.add('[error] EXCEPTION: $e');
      notifyError('Terjadi kesalahan: $e');
      notifyListeners();
    }
  }

  // ── Cancel/Kill Process ───────────────────────────────────────
  void cancelScraping() {
    if (_process != null) {
      _process!.kill();
      _process = null;
      isRunning = false;
      logLines.add('Proses dibatalkan oleh pengguna.');
      notifyWarning('Proses dibatalkan.');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _process?.kill();
    super.dispose();
  }
}

/// SlaGeneratedFile — Model data penampung metadata berkas hasil rekap secara asinkron.
class SlaGeneratedFile {
  final File file;
  final String name;
  final bool isDispensasi;
  final DateTime modified;
  final int sizeInBytes;

  SlaGeneratedFile({
    required this.file,
    required this.name,
    required this.isDispensasi,
    required this.modified,
    required this.sizeInBytes,
  });
}
