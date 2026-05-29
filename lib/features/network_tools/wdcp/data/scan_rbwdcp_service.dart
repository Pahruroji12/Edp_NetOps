import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/activity_logger.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'mikrotik_api_service.dart';

// ── Model Data ─────────────────────────────────────────────────────────────────
class WlanResult {
  final String name;
  final bool defaultAuth;
  const WlanResult({required this.name, required this.defaultAuth});
}

class ScanResultModel {
  final int no;
  final String storeCode;
  final String storeName;
  final String ip;
  final String connectionType;
  final List<WlanResult> wlanResults;
  final bool success;
  final String errorMsg;

  const ScanResultModel({
    required this.no,
    required this.storeCode,
    required this.storeName,
    required this.ip,
    required this.connectionType,
    required this.wlanResults,
    required this.success,
    this.errorMsg = '',
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE
// ══════════════════════════════════════════════════════════════════════════════
class ScanRbwdcpService extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final ScanRbwdcpService _instance = ScanRbwdcpService._internal();
  factory ScanRbwdcpService() => _instance;
  ScanRbwdcpService._internal();

  // ── State — Scan ───────────────────────────────────────────────────────────
  bool isScanning = false;
  bool cancelRequested = false;
  int scanTotal = 0;
  int scanCompleted = 0;
  int scanSuccess = 0;
  int scanOffline = 0;
  int scanAuthActive = 0;
  String scanStatus = 'Siap untuk memulai scan...';
  double scanProgress = 0.0;
  String scanCurrentIp = '';
  String? scanFilePath;
  final List<ScanResultModel> scanResults = [];

  // ── State — Fix Default Auth ───────────────────────────────────────────────
  bool isFixing = false;
  bool fixCancelRequested = false;
  int fixTotal = 0;
  int fixCompleted = 0;
  int fixSuccess = 0;
  int fixFailed = 0;
  double fixProgress = 0.0;
  String fixStatus = '';

  int _apiPort = 8728;
  String _apiUser = 'admin';
  String _apiPass = '';

  // ── Throttle notifyListeners — max sekali per 150ms agar UI tidak rebuild
  // terlalu sering saat scan ratusan toko ────────────────────────────────────
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
  void _throttledNotify({bool force = false}) {
    final now = DateTime.now();
    if (force || now.difference(_lastNotify).inMilliseconds >= 150) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  Future<void> _loadApiSettings() async {
    final resp = await Supabase.instance.client.from('app_settings').select();
    final data = {for (var item in resp) item['key']: item['value']};
    _apiUser = data['wdcp_user'] ?? 'admin';
    _apiPass = data['wdcp_pass'] ?? '';
    _apiPort = int.tryParse(data['api_port'] ?? '8728') ?? 8728;
  }

  void cancelScan() {
    cancelRequested = true;
    scanStatus = 'Membatalkan scan... (Menunggu router terakhir)';
    _throttledNotify(force: true);
  }

  void cancelFix() {
    fixCancelRequested = true;
    fixStatus = 'Membatalkan fix... (Menunggu router selesai)';
    _throttledNotify(force: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCAN SATU ROUTER — dijalankan langsung di main isolate (async/await)
  // Socket Flutter tidak kompatibel dengan Isolate.run() karena bergantung
  // pada event loop utama. Semua operasi sudah non-blocking (async).
  // ══════════════════════════════════════════════════════════════════════════
  Future<ScanResultModel> _scanOneRouter({
    required int no,
    required String storeCode,
    required String storeName,
    required String ip,
    required String connectionType,
    required int timeoutSec,
  }) async {
    final api = MikrotikApiService();
    try {
      await api
          .connect(ip, _apiPort, _apiUser, _apiPass)
          .timeout(Duration(seconds: timeoutSec));

      final ifaceRaw = await api.getWirelessInterfaces().timeout(
        Duration(seconds: timeoutSec),
      );

      api.disconnect();

      final interfaces = ifaceRaw
          .map(
            (m) => WlanResult(
              name: m['name'] as String,
              // FIX BUG 3: RouterOS mengembalikan 'yes'/'no', bukan 'true'/'false'
              defaultAuth: m['defaultAuth'] as bool,
            ),
          )
          .toList();

      return ScanResultModel(
        no: no,
        storeCode: storeCode,
        storeName: storeName,
        ip: ip,
        connectionType: connectionType,
        wlanResults: interfaces.isEmpty
            ? [const WlanResult(name: '-', defaultAuth: false)]
            : interfaces,
        success: true,
      );
    } on TimeoutException {
      api.disconnect();
      final isVsat = connectionType.toUpperCase().contains('VSAT');
      return ScanResultModel(
        no: no,
        storeCode: storeCode,
        storeName: storeName,
        ip: ip,
        connectionType: connectionType,
        wlanResults: [],
        success: false,
        errorMsg: isVsat ? 'Timeout (VSAT)' : 'Timeout (${timeoutSec}s)',
      );
    } catch (e) {
      api.disconnect();
      return ScanResultModel(
        no: no,
        storeCode: storeCode,
        storeName: storeName,
        ip: ip,
        connectionType: connectionType,
        wlanResults: [],
        success: false,
        errorMsg: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIX DEFAULT AUTH
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> startFixDefaultAuth() async {
    if (isFixing || isScanning) return;

    final targets = scanResults
        .where((r) => r.success && r.wlanResults.any((w) => w.defaultAuth))
        .toList();

    if (targets.isEmpty) return;

    isFixing = true;
    fixCancelRequested = false;
    fixTotal = targets.length;
    fixCompleted = 0;
    fixSuccess = 0;
    fixFailed = 0;
    fixProgress = 0.0;
    fixStatus = 'Mengambil konfigurasi API...';
    _throttledNotify(force: true);

    try {
      await _loadApiSettings();

      for (final target in targets) {
        if (fixCancelRequested) break;

        fixStatus = 'Fixing ${target.storeCode} — ${target.ip}...';
        _throttledNotify();

        final api = MikrotikApiService();
        try {
          await api
              .connect(target.ip, _apiPort, _apiUser, _apiPass)
              .timeout(const Duration(seconds: 10));
          await api.setDefaultAuth(false).timeout(const Duration(seconds: 10));
          api.disconnect();
          fixSuccess++;

          final idx = scanResults.indexOf(target);
          if (idx != -1) {
            final fixed = ScanResultModel(
              no: target.no,
              storeCode: target.storeCode,
              storeName: target.storeName,
              ip: target.ip,
              connectionType: target.connectionType,
              wlanResults: target.wlanResults
                  .map((w) => WlanResult(name: w.name, defaultAuth: false))
                  .toList(),
              success: target.success,
            );
            scanResults[idx] = fixed;
          }
        } catch (e) {
          api.disconnect();
          fixFailed++;
          debugPrint('Fix gagal untuk ${target.ip}: $e');
        }

        fixCompleted++;
        fixProgress = fixCompleted / fixTotal;
        _throttledNotify();
      }

      scanAuthActive = scanResults
          .where((r) => r.success && r.wlanResults.any((w) => w.defaultAuth))
          .length;

      await ActivityLogger.logAction(
        actionType: 'FIX_DEFAULT_AUTH',
        description: fixCancelRequested
            ? 'Fix dibatalkan — $fixSuccess berhasil, $fixFailed gagal '
                  'dari $fixCompleted/$fixTotal router'
            : 'Fix Default Auth selesai — $fixSuccess berhasil, '
                  '$fixFailed gagal dari $fixTotal router',
      );

      isFixing = false;
      fixStatus = fixCancelRequested
          ? 'Dibatalkan ($fixCompleted/$fixTotal) — $fixSuccess OK, $fixFailed Gagal'
          : 'Fix selesai! $fixSuccess berhasil, $fixFailed gagal';
      _throttledNotify(force: true);

      if (fixCancelRequested) {
        CustomSnackBar.warning('Fix default auth dibatalkan ($fixCompleted/$fixTotal).');
      } else {
        CustomSnackBar.success('Fix default auth selesai! $fixSuccess berhasil, $fixFailed gagal.');
      }
    } catch (e) {
      isFixing = false;
      fixStatus = 'Error: $e';
      _throttledNotify(force: true);
      CustomSnackBar.error('Fix default auth gagal: $e');
    }
  }

  String? _pendingFilePath;

  // ══════════════════════════════════════════════════════════════════════════
  // START SCAN
  // Dijalankan sequential async — satu router selesai baru lanjut ke berikutnya.
  // UI tetap responsif karena semua operasi socket sudah non-blocking.
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> startScan() async {
    if (isScanning) return;

    isScanning = true;
    cancelRequested = false;
    scanTotal = 0;
    scanCompleted = 0;
    scanSuccess = 0;
    scanOffline = 0;
    scanAuthActive = 0;
    scanProgress = 0.0;
    scanCurrentIp = '';
    scanFilePath = null;
    scanResults.clear();

    final ts = DateFormat('ddMMyyyy_HHmm').format(DateTime.now());
    _pendingFilePath =
        r'D:\Edp NetOps\scan Rbwdcp\ScanRBWDCP_'
        '$ts.csv';

    scanStatus = 'Mengambil konfigurasi API...';
    _throttledNotify(force: true);

    try {
      await _loadApiSettings();

      scanStatus = 'Mengambil data toko...';
      _throttledNotify(force: true);

      final response = await Supabase.instance.client
          .from('stores')
          .select()
          .order('store_code');

      final stores = (response as List)
          .where(
            (s) =>
                s['ip_rb_wdcp'] != null &&
                (s['ip_rb_wdcp'] as String).trim().isNotEmpty &&
                s['ip_rb_wdcp'] != '-',
          )
          .toList();

      scanTotal = stores.length;
      scanStatus = 'Memulai scan $scanTotal router...';
      _throttledNotify(force: true);

      int no = 1;
      for (final store in stores) {
        if (cancelRequested) break;

        final ip = (store['ip_rb_wdcp'] as String).trim();
        final connType = (store['connection_type'] ?? '') as String;
        final isVsat = connType.toUpperCase().contains('VSAT');
        final timeoutSec = isVsat ? 25 : 6;

        scanCurrentIp = ip;
        scanStatus = 'Scanning ${store['store_code']} — $ip...';
        _throttledNotify();

        // ── FIX BUG 1: Langsung await async, TANPA Isolate.run() ──
        // Socket Flutter tidak bisa dijalankan di Isolate terpisah.
        // Semua operasi sudah async/await sehingga UI tetap responsif.
        final result = await _scanOneRouter(
          no: no,
          storeCode: store['store_code'] ?? '-',
          storeName: store['store_name'] ?? '-',
          ip: ip,
          connectionType: connType,
          timeoutSec: timeoutSec,
        );

        scanResults.add(result);
        scanCompleted++;
        scanProgress = scanCompleted / scanTotal;

        if (result.success) {
          scanSuccess++;
          if (result.wlanResults.any((w) => w.defaultAuth)) {
            scanAuthActive++;
          }
        } else {
          scanOffline++;
        }

        _throttledNotify();
        no++;
      }

      // ── Simpan CSV ─────────────────────────────────────────────────────
      if (scanResults.isNotEmpty) {
        scanStatus = cancelRequested
            ? 'Menyimpan hasil parsial ke CSV...'
            : 'Menyimpan ke CSV...';
        _throttledNotify(force: true);
        scanFilePath = await _saveCsv(scanResults, path: _pendingFilePath);
      }

      await ActivityLogger.logAction(
        actionType: 'SCAN_RBWDCP',
        description: cancelRequested
            ? 'Scan dibatalkan — $scanCompleted/$scanTotal'
            : 'Scan selesai — $scanTotal router, $scanSuccess berhasil, '
                  '$scanAuthActive default-auth aktif',
      );

      isScanning = false;
      scanCurrentIp = '';
      scanProgress = cancelRequested ? scanProgress : 1.0;
      scanStatus = cancelRequested
          ? 'Dibatalkan ($scanCompleted/$scanTotal)'
          : 'Selesai! $scanSuccess berhasil, $scanOffline tidak terjangkau';
      _throttledNotify(force: true);

      if (cancelRequested) {
        CustomSnackBar.warning('Scan RBWDCP dibatalkan ($scanCompleted/$scanTotal).');
      } else {
        CustomSnackBar.success('Scan RBWDCP selesai! $scanSuccess berhasil, $scanOffline offline.');
      }
    } catch (e) {
      isScanning = false;
      scanStatus = 'Error: $e';
      _throttledNotify(force: true);
      CustomSnackBar.error('Scan RBWDCP gagal: $e');
    }
  }

  Future<String> _saveCsv(List<ScanResultModel> data, {String? path}) async {
    final dir = Directory(r'D:\Edp NetOps\scan Rbwdcp');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final filePath =
        path ??
        '${dir.path}\\ScanRBWDCP_'
            '${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.csv';

    final rows = <List<dynamic>>[
      [
        'No',
        'Kode Toko',
        'Nama Toko',
        'IP RBWCP',
        'Koneksi',
        'Interface',
        'Default Auth',
        'Keterangan',
      ],
    ];

    for (final r in data) {
      if (r.wlanResults.isEmpty) {
        rows.add([
          r.no,
          r.storeCode,
          r.storeName,
          r.ip,
          r.connectionType.isEmpty ? '-' : r.connectionType,
          '-',
          '-',
          r.errorMsg,
        ]);
      } else {
        for (final w in r.wlanResults) {
          rows.add([
            r.no,
            r.storeCode,
            r.storeName,
            r.ip,
            r.connectionType.isEmpty ? '-' : r.connectionType,
            w.name.toUpperCase(),
            w.defaultAuth ? 'true' : 'false',
            w.defaultAuth ? 'NOK' : 'OK',
          ]);
        }
      }
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: '|',
      eol: '\n',
    ).convert(rows);

    await File(filePath).writeAsString(csv);
    return filePath;
  }
}
