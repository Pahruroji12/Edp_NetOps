import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../utils/activity_logger.dart';
import '../utils/globals.dart';
import '../utils/custom_snackbar.dart';
import '../utils/app_colors.dart';

// ChangeNotifier ini yang akan memberi tahu layar kalau ada update progress
class PingService extends ChangeNotifier {
  // ── SINGLETON ────────────────────────────────────────────────────────────
  static final PingService instance = PingService._internal();
  PingService._internal();

  // ── STATE ─────────────────────────────────────────────────────────────────
  bool pingGateway = true;
  bool pingStation1 = false;
  bool pingSTB = false;
  bool pingRbWdcp = false;
  bool pingCctv1 = false;
  bool pingCctv2 = false;
  String manualIps = "";

  bool isAutoPingSTBActive = false;
  Timer? _schedulerTimer;
  bool _isAutoPingRunning = false;

  bool isScanning = false;
  String statusText = "Siap untuk memulai pemindaian...";
  double progressValue = 0.0;

  // ── UPDATE STATE ──────────────────────────────────────────────────────────
  void setCheckbox(String type, bool val) {
    if (type == 'GW') pingGateway = val;
    if (type == 'S1') pingStation1 = val;
    if (type == 'STB') pingSTB = val;
    if (type == 'RB') pingRbWdcp = val;
    if (type == 'C1') pingCctv1 = val;
    if (type == 'C2') pingCctv2 = val;
    notifyListeners();
  }

  // ── SNACKBAR GLOBAL — delegate ke CustomSnackBar.showFromKey ────────────────
  void showGlobalNotif(String message, Color color) {
    CustomSnackBar.showFromKey(globalMessengerKey, message, color);
  }

  // ── SCHEDULER SHIFT 3 ─────────────────────────────────────────────────────
  void toggleAutoPing(bool isActive) {
    isAutoPingSTBActive = isActive;
    notifyListeners();

    if (isActive) {
      showGlobalNotif("Auto-Ping STB Diaktifkan!", AppStatusColors.success);
      _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        final now = DateTime.now();
        if (now.hour >= 0 && now.hour <= 3 && now.minute == 0) {
          if (!_isAutoPingRunning && !isScanning) {
            _runAutoPingRoutine();
          }
        }
      });
    } else {
      _schedulerTimer?.cancel();
      showGlobalNotif("Auto-Ping STB Dimatikan.", AppStatusColors.warning);
    }
  }

  Future<void> _runAutoPingRoutine() async {
    _isAutoPingRunning = true;

    // Simpan state sebelumnya
    final backupGtw = pingGateway;
    final backupSt1 = pingStation1;
    final backupStb = pingSTB;
    final backupRb = pingRbWdcp;
    final backupCc1 = pingCctv1;
    final backupCc2 = pingCctv2;

    // Paksa ke STB saja
    pingGateway = false;
    pingStation1 = false;
    pingSTB = true;
    pingRbWdcp = false;
    pingCctv1 = false;
    pingCctv2 = false;
    notifyListeners();

    await startPing(isAutoRun: true);

    // Pulihkan state
    pingGateway = backupGtw;
    pingStation1 = backupSt1;
    pingSTB = backupStb;
    pingRbWdcp = backupRb;
    pingCctv1 = backupCc1;
    pingCctv2 = backupCc2;
    notifyListeners();

    _isAutoPingRunning = false;
  }

  // ── PING MASSAL ───────────────────────────────────────────────────────────
  Future<void> startPing({bool isAutoRun = false}) async {
    if (!pingGateway &&
        !pingStation1 &&
        !pingSTB &&
        !pingRbWdcp &&
        !pingCctv1 &&
        !pingCctv2 &&
        manualIps.trim().isEmpty) {
      if (!isAutoRun) {
        showGlobalNotif(
          "Pilih minimal 1 jenis IP atau isi IP Manual!",
          AppStatusColors.warning,
        );
      }
      return;
    }

    isScanning = true;
    progressValue = 0.0;
    statusText = "Mengambil data toko dari database...";
    notifyListeners();

    try {
      final response = await Supabase.instance.client.from('stores').select();

      final List<Map<String, String>> targetList = [];

      for (final store in response) {
        final namaToko = "${store['store_code']} - ${store['store_name']}";

        void addTarget(String jenis, String? ip) {
          if (ip != null && ip.trim().isNotEmpty && ip != '-') {
            targetList.add({'toko': namaToko, 'jenis': jenis, 'ip': ip.trim()});
          }
        }

        if (pingGateway) addTarget('IP Gateway', store['ip_gateway']);
        if (pingStation1) addTarget('IP Station 1', store['ip_station_1']);
        if (pingSTB) addTarget('IP STB', store['ip_stb']);
        if (pingRbWdcp) addTarget('IP RB WDCP', store['ip_rb_wdcp']);
        if (pingCctv1) addTarget('IP CCTV 1', store['ip_cctv_1']);
        if (pingCctv2) addTarget('IP CCTV 2', store['ip_cctv_2']);
      }

      if (manualIps.trim().isNotEmpty) {
        // Pisahkan teks berdasarkan baris baru (Enter)
        final lines = manualIps.split(RegExp(r'\r?\n'));
        for (var line in lines) {
          final ip = line.trim();
          if (ip.isNotEmpty) {
            targetList.add({
              'toko': 'Input Manual',
              'jenis': 'Custom IP',
              'ip': ip,
            });
          }
        }
      }

      if (targetList.isEmpty) throw Exception("Tidak ada IP yang valid.");

      // Header CSV
      final List<List<dynamic>> csvData = [
        [
          "Nama Toko",
          "Jenis Perangkat",
          "IP Address",
          "Status",
          "Waktu Pengecekan",
        ],
      ];

      final int totalTarget = targetList.length;
      int completed = 0;
      const int batchSize = 1;

      for (int i = 0; i < totalTarget; i += batchSize) {
        final batch = targetList.sublist(i, min(i + batchSize, totalTarget));
        final batchResults = await Future.wait(
          batch.map((target) => _pingSingleIP(target)),
        );
        csvData.addAll(batchResults);

        completed += batch.length;
        progressValue = completed / totalTarget;
        statusText = "Mengeksekusi Ping... ($completed / $totalTarget IP)";
        notifyListeners();
      }

      statusText = "Menyimpan hasil ke CSV...";
      notifyListeners();

      final String csvContent = const ListToCsvConverter().convert(csvData);
      final String customDirPath = r'D:\Edp NetOps\Hasil Ping';
      final Directory customDir = Directory(customDirPath);

      // 2. Cek apakah foldernya sudah ada? Kalau belum, suruh aplikasi buatkan otomatis!
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }

      // 3. Buat nama filenya
      final String timestamp = DateFormat(
        'ddMMyyyy_HHmm',
      ).format(DateTime.now());
      final String prefix = isAutoRun ? "AutoPing_STB" : "Hasil_Ping";

      // 4. Gabungkan folder dengan nama file
      final String filePath = '${customDir.path}\\${prefix}_$timestamp.csv';

      await File(filePath).writeAsString(csvContent);

      await ActivityLogger.logAction(
        actionType: isAutoRun ? "AUTO_PING" : "PING",
        description: isAutoRun
            ? "Sistem Shift 3 otomatis mengeksekusi ping ke $totalTarget IP STB"
            : "Mengeksekusi ping ke $totalTarget IP Perangkat",
      );

      isScanning = false;
      progressValue = 1.0;
      statusText = "Selesai! File disimpan di: $filePath";
      notifyListeners();

      if (!isAutoRun) {
        showGlobalNotif(
          "Ping selesai! File tersimpan di Downloads.",
          AppStatusColors.success,
        );
      }
    } catch (e) {
      isScanning = false;
      statusText = "Terjadi Kesalahan: $e";
      notifyListeners();
      if (!isAutoRun) showGlobalNotif("Error: $e", AppStatusColors.danger);
    }
  }

  // ── PING SATU IP ──────────────────────────────────────────────────────────
  Future<List<dynamic>> _pingSingleIP(Map<String, String> target) async {
    final ip = target['ip']!;
    bool isAlive = false;
    try {
      final result = await Process.run('ping', ['-n', '1', '-w', '3000', ip]);
      if (result.stdout.toString().toLowerCase().contains('ttl=')) {
        isAlive = true;
      }
    } catch (_) {
      isAlive = false;
    }
    final waktu = DateFormat('HH:mm:ss').format(DateTime.now());
    return [target['toko'], target['jenis'], ip, isAlive ? "OK" : "NOK", waktu];
  }
}
