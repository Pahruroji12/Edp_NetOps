import 'package:flutter/material.dart';
import '../data/wdcp_repository.dart';
import '../../../../core/utils/notification_mixin.dart';

/// WdcpController — semua state dan logic untuk WdcpControlPage.
///
/// Lokasi: features/network_tools/wdcp/presentation/wdcp_controller.dart
///
/// Tanggung jawab:
///   - Load settings & connect ke router via repository
///   - Kelola state devices, access list, system info
///   - Filter access list
///   - Add/remove MAC, toggle default auth
///   - Launch Winbox
///   - Notification state untuk Page
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung
///   - Query Supabase langsung
///
class WdcpController extends ChangeNotifier with NotificationMixin {
  final WdcpRepository _repo = WdcpRepository();

  final String ip;
  final String storeName;
  final String storeCode;

  WdcpController({
    required this.ip,
    required this.storeName,
    required this.storeCode,
  });

  // ── Credentials (dari Supabase) ─────────────────────────────
  String _user = '';
  String _pass = '';
  int _apiPort = 8728;
  String _winboxPort = '8291';

  // ── State: Loading ──────────────────────────────────────────
  bool isLoading = true;
  bool isConnected = false;
  bool isRefreshing = false;
  bool animationsReady = false;

  // ── State: Data ─────────────────────────────────────────────
  List<Map<String, String>> connectedDevices = [];
  List<Map<String, String>> _accessList = [];
  List<Map<String, String>> filteredAccessList = [];
  Map<String, String> systemInfo = {};
  bool defaultAuthStatus = false;

  // ── State: Text Controllers ─────────────────────────────────
  final macController = TextEditingController();
  final commentController = TextEditingController();
  final searchController = TextEditingController();

  // ── State: Notification (via NotificationMixin) ─────────────

  /// Signal page to switch to tab index after add MAC.
  int? pendingTabSwitch;

  @override
  void clearNotification() {
    super.clearNotification();
    pendingTabSwitch = null;
  }

  // ── Computed ────────────────────────────────────────────────
  int get deviceCount => connectedDevices.length;
  int get accessListCount => _accessList.length;

  // ── INIT ────────────────────────────────────────────────────

  void init() {
    loadSettingsAndConnect();
  }

  void markAnimationsReady() {
    animationsReady = true;
    notifyListeners();
  }

  // ── LOAD SETTINGS & CONNECT ─────────────────────────────────

  Future<void> loadSettingsAndConnect() async {
    final result = await _repo.fetchWdcpCredentials();
    await result.fold(
      (failure) async {
        isLoading = false;
        notifyError('Gagal ambil konfigurasi WDCP: ${failure.message}');
      },
      (creds) async {
        _user = creds['wdcp_user']!;
        _pass = creds['wdcp_pass']!;
        _apiPort = int.tryParse(creds['api_port']!) ?? 8728;
        _winboxPort = creds['winbox_port']!;
        await connectAndLoad();
      },
    );
  }

  Future<void> connectAndLoad() async {
    isLoading = true;
    isConnected = false;
    notifyListeners();

    final result = await _repo.connectAndFetch(
      ip: ip, apiPort: _apiPort, user: _user, pass: _pass,
    );

    result.fold(
      (failure) => notifyError('Gagal Konek: ${failure.message}'),
      (data) {
        connectedDevices = List<Map<String, String>>.from(data['devices'] ?? []);
        _accessList = List<Map<String, String>>.from(data['accessList'] ?? []);
        filteredAccessList = _accessList;
        defaultAuthStatus = data['authStatus'] as bool? ?? false;
        systemInfo = Map<String, String>.from(data['sysInfo'] ?? {});
        isConnected = true;
      },
    );

    isLoading = false;
    notifyListeners();
  }

  // ── REFRESH DATA ────────────────────────────────────────────

  Future<void> refreshData() async {
    isRefreshing = true;
    notifyListeners();

    final result = await _repo.connectAndFetch(
      ip: ip, apiPort: _apiPort, user: _user, pass: _pass,
    );

    result.fold(
      (failure) => notifyError('Gagal refresh: ${failure.message}'),
      (data) {
        connectedDevices = List<Map<String, String>>.from(data['devices'] ?? []);
        _accessList = List<Map<String, String>>.from(data['accessList'] ?? []);
        _applyAccessListFilter();
        defaultAuthStatus = data['authStatus'] as bool? ?? false;
        systemInfo = Map<String, String>.from(data['sysInfo'] ?? {});
      },
    );

    isRefreshing = false;
    notifyListeners();
  }

  // ── FILTER ACCESS LIST ──────────────────────────────────────

  void filterAccessList(String query) {
    _applyAccessListFilter(query: query);
    notifyListeners();
  }

  void _applyAccessListFilter({String? query}) {
    final q = query ?? searchController.text;
    if (q.isEmpty) {
      filteredAccessList = _accessList;
    } else {
      final lower = q.toLowerCase();
      filteredAccessList = _accessList.where((item) {
        final mac = (item['mac-address'] ?? '').toLowerCase();
        final comment = (item['comment'] ?? '').toLowerCase();
        return mac.contains(lower) || comment.contains(lower);
      }).toList();
    }
  }

  // ── ADD MAC ─────────────────────────────────────────────────

  Future<void> addMac() async {
    final macInput = macController.text.trim();
    final commentInput = commentController.text.trim();

    if (macInput.isEmpty) {
      notifyError('MAC Address tidak boleh kosong');
      return;
    }

    final isDuplicate = _accessList.any((item) => item['mac-address'] == macInput);
    if (isDuplicate) {
      notifyError('GAGAL: MAC $macInput sudah terdaftar!');
      return;
    }

    final result = await _repo.addMac(
      ip: ip, apiPort: _apiPort, user: _user, pass: _pass,
      mac: macInput, comment: commentInput,
    );

    await result.fold(
      (failure) async => notifyError('Gagal tambah: ${failure.message}'),
      (_) async {
        notifySuccess('Sukses menambahkan $macInput');
        macController.clear();
        commentController.clear();
        pendingTabSwitch = 1; // Signal page to switch to whitelist tab
        await refreshData();
      },
    );
  }

  // ── REMOVE MAC ──────────────────────────────────────────────

  Future<void> removeMac(String id, String mac) async {
    final result = await _repo.removeMac(
      ip: ip, apiPort: _apiPort, user: _user, pass: _pass, id: id,
    );

    await result.fold(
      (failure) async => notifyError('Gagal hapus: ${failure.message}'),
      (_) async {
        notifyWarning('MAC $mac berhasil dihapus');
        await refreshData();
      },
    );
  }

  // ── TOGGLE AUTH ─────────────────────────────────────────────

  Future<void> toggleAuth(bool value) async {
    final result = await _repo.toggleAuth(
      ip: ip, apiPort: _apiPort, user: _user, pass: _pass, value: value,
    );

    await result.fold(
      (failure) async => notifyError('Gagal ubah setting: ${failure.message}'),
      (_) async {
        final level = value ? NotifLevel.error : NotifLevel.success;
        notify('Default Authenticate: ${value ? "ENABLED" : "DISABLED"}', level);
        await refreshData();
      },
    );
  }

  // ── LAUNCH WINBOX ───────────────────────────────────────────

  Future<void> launchWinbox() async {
    final result = await _repo.launchWinbox(
      ip: ip, winboxPort: _winboxPort, user: _user, pass: _pass,
    );

    result.fold(
      (failure) => notifyError('${failure.message}'),
      (address) => notifyInfo('Membuka Winbox ke $address...'),
    );
  }

  // ── DISPOSE ─────────────────────────────────────────────────

  @override
  void dispose() {
    macController.dispose();
    commentController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
