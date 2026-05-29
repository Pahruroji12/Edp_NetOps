import 'dart:io';
import 'package:flutter/material.dart';

import '../data/scan_rbwdcp_service.dart';
import '../data/scan_wdcp_repository.dart';
import '../../../../core/utils/notification_mixin.dart';

/// ScanWdcpController — semua state dan logic untuk ScanWdcpPage.
///
/// Lokasi: features/network_tools/wdcp/presentation/scan_wdcp_controller.dart
///
/// Tanggung jawab:
///   - Fetch stores via repository (bukan Supabase langsung)
///   - Filter stores (search + connection type)
///   - Launch Winbox & Ping CMD
///   - Kelola animation state
///   - Notification state untuk Page
///   - Bridge ke ScanRbwdcpService (singleton scan engine)
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung (gunakan notification state)
///   - Import widget selain ChangeNotifier
///   - Query Supabase langsung (harus via repository)
///
class ScanWdcpController extends ChangeNotifier with NotificationMixin {
  final ScanWdcpRepository _repo = ScanWdcpRepository();

  /// Singleton scan service — tetap berjalan saat pindah halaman.
  final ScanRbwdcpService scan = ScanRbwdcpService();

  // ── State: Animation ────────────────────────────────────────
  bool showScanPanel = false;
  bool showListCard = false;

  // ── State: Loading ──────────────────────────────────────────
  bool isLoading = true;

  // ── State: Store Data ───────────────────────────────────────
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> filteredStores = [];

  // ── State: Search & Filter ──────────────────────────────────
  final searchController = TextEditingController();
  final listScrollController = ScrollController();
  String activeFilter = 'Semua';

  // ── State: Notification (via NotificationMixin) ─────────────

  // ── Computed ────────────────────────────────────────────────
  int get totalStores => _stores.length;

  // ── INIT ────────────────────────────────────────────────────

  void init() {
    fetchStores();
    scan.addListener(_onScanUpdate);
  }

  void triggerAnimations() {
    Future.delayed(const Duration(milliseconds: 80), () {
      showScanPanel = true;
      notifyListeners();
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      showListCard = true;
      notifyListeners();
    });
  }

  void _onScanUpdate() {
    notifyListeners();
  }

  // ── FETCH STORES ────────────────────────────────────────────

  Future<void> fetchStores() async {
    isLoading = true;
    notifyListeners();
    
    final result = await _repo.fetchStoresWithWdcpIp();
    result.fold(
      (failure) => notifyError('Gagal memuat data toko: ${failure.message}'),
      (stores) {
        _stores = stores;
        _applyFilters();
      },
    );
    
    isLoading = false;
    notifyListeners();
  }

  // ── FILTER LOGIC ────────────────────────────────────────────

  void applyFilters() {
    _applyFilters();
    notifyListeners();
  }

  void setActiveFilter(String filter) {
    activeFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final q = searchController.text.toLowerCase();
    filteredStores = _stores.where((store) {
      final code = (store['store_code'] ?? '').toString().toLowerCase();
      final name = (store['store_name'] ?? '').toString().toLowerCase();
      final ipWdcp = (store['ip_rb_wdcp'] ?? '').toString().toLowerCase();

      final matchText =
          q.isEmpty || code.contains(q) || name.contains(q) || ipWdcp.contains(q);

      if (!matchText) return false;
      if (activeFilter == 'Semua') return true;

      final conn = (store['connection_type'] ?? '').toString().toLowerCase();
      switch (activeFilter) {
        case 'FO':
          return conn.contains('astinet') ||
              conn.contains('icon') ||
              conn.contains('fiberstar');
        case 'VSAT':
          final ipVsat = (store['ip_vsat'] ?? '').toString();
          return conn.contains('vsat') || ipVsat.isNotEmpty;
        case 'GSM':
          return conn.contains('gsm') || conn.contains('orbit');
        case 'XL':
          return conn.contains('xl');
        default:
          return true;
      }
    }).toList();
  }

  // ── LAUNCH ACTIONS ──────────────────────────────────────────

  Future<void> launchPingCmd(String ip) async {
    try {
      await Process.start('cmd', ['/c', 'start', 'cmd', '/k', 'ping $ip -t']);
    } catch (e) {
      notifyError('Gagal membuka CMD.');
    }
  }

  Future<void> launchWinbox(String ip) async {
    const String winboxPath = r'D:\Edp NetOps\winbox.exe';
    if (!await File(winboxPath).exists()) {
      notifyError('File winbox.exe tidak ditemukan!');
      return;
    }

    final result = await _repo.fetchWdcpCredentials();
    await result.fold(
      (failure) async => notifyError('Gagal membuka Winbox: ${failure.message}'),
      (creds) async {
        try {
          final address = '$ip:${creds['winbox_port']}';

          await Process.start(winboxPath, [
            address,
            creds['wdcp_user']!,
            creds['wdcp_pass']!,
          ], mode: ProcessStartMode.detached);

          notifyInfo('Membuka Winbox ke $address...');
        } catch (e) {
          notifyError('Gagal membuka Winbox: $e');
        }
      },
    );
  }

  // ── SCAN ACTIONS (delegated to service) ─────────────────────

  /// Cek apakah ada router dengan default-auth aktif sebelum fix.
  /// Return true jika ada yang perlu difix, false jika tidak.
  bool canFixDefaultAuth() {
    return scan.scanAuthActive > 0;
  }

  // ── DISPOSE ─────────────────────────────────────────────────

  @override
  void dispose() {
    scan.removeListener(_onScanUpdate);
    searchController.dispose();
    listScrollController.dispose();
    super.dispose();
  }
}
