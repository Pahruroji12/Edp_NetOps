import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../utils/activity_logger.dart';
import 'mikrotik_api_service.dart';

// Model Data dipindah ke sini agar bisa diakses secara global
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

// Menggunakan ChangeNotifier agar UI bisa "mendengar" perubahan dari background
class ScanRbwdcpService extends ChangeNotifier {
  // ── Singleton Pattern ── (Menjamin mesin ini cuma ada 1 dan terus hidup)
  static final ScanRbwdcpService _instance = ScanRbwdcpService._internal();
  factory ScanRbwdcpService() => _instance;
  ScanRbwdcpService._internal();

  // ── State Variables ──
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

  int _apiPort = 8728;
  String _apiUser = 'admin';
  String _apiPass = '';

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
    notifyListeners();
  }

  // ── Path file CSV yang dibuat sekali di awal scan ──
  String? _pendingFilePath;

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

    // ── Generate nama file sekali di awal, agar tidak berubah ──
    final ts = DateFormat('ddMMyyyy_HHmm').format(DateTime.now());
    _pendingFilePath =
        r'D:\Edp NetOps\scan Rbwdcp\ScanRBWDCP_'
        '$ts.csv';

    scanStatus = 'Mengambil konfigurasi API...';
    notifyListeners();

    try {
      await _loadApiSettings();

      scanStatus = 'Mengambil data toko...';
      notifyListeners();

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
      notifyListeners();

      int no = 1;
      for (final store in stores) {
        if (cancelRequested) break;

        final ip = (store['ip_rb_wdcp'] as String).trim();
        final connType = (store['connection_type'] ?? '') as String;
        final isVsat = connType.toUpperCase().contains('VSAT');
        final timeoutSec = isVsat ? 25 : 6;

        scanCurrentIp = ip;
        scanStatus = 'Scanning ${store['store_code']} — $ip...';
        notifyListeners(); // Update UI

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

        notifyListeners(); // Update progress bar di UI
        no++;
      }

      // ── SIMPAN SATU FILE DI AKHIR (scan selesai atau dibatalkan) ──
      if (scanResults.isNotEmpty) {
        scanStatus = cancelRequested
            ? 'Menyimpan hasil parsial ke CSV...'
            : 'Menyimpan ke CSV...';
        notifyListeners();
        scanFilePath = await _saveCsv(scanResults, path: _pendingFilePath);
      }

      await ActivityLogger.logAction(
        actionType: 'SCAN_RBWDCP',
        description: cancelRequested
            ? 'Scan dibatalkan — $scanCompleted/$scanTotal'
            : 'Scan selesai — $scanTotal router, $scanSuccess berhasil, $scanAuthActive default-auth aktif',
      );

      isScanning = false;
      scanCurrentIp = '';
      scanProgress = cancelRequested ? scanProgress : 1.0;
      scanStatus = cancelRequested
          ? 'Dibatalkan ($scanCompleted/$scanTotal)'
          : 'Selesai! $scanSuccess berhasil, $scanOffline tidak terjangkau';
      notifyListeners();
    } catch (e) {
      isScanning = false;
      scanStatus = 'Error: $e';
      notifyListeners();
    }
  }

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
      // Asumsi fungsi getWirelessInterfaces sudah Mas tambahkan di mikrotik_api_service
      final ifaceRaw = await api.getWirelessInterfaces().timeout(
        Duration(seconds: timeoutSec),
      );
      api.disconnect();

      final interfaces = ifaceRaw
          .map(
            (m) => WlanResult(
              name: m['name'] as String,
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

  Future<String> _saveCsv(List<ScanResultModel> data, {String? path}) async {
    final dir = Directory(r'D:\Edp NetOps\scan Rbwdcp');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Gunakan path yang sudah ditentukan di awal, atau buat baru jika tidak ada
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
