import 'package:flutter/material.dart';

import '../../../../core/platform/native_io.dart';
import '../../../../core/platform/ping_service.dart';
import '../../domain/store_model.dart';
import '../../data/store_repository.dart';
import '../../../../../core/utils/role_helper.dart';
import '../../../settings/data/settings_repository.dart';
import '../../../../../core/utils/notification_mixin.dart';
import '../../../../../core/platform/platform_helper.dart';
import '../../../../../core/utils/tool_helper.dart';
import '../../../../../core/platform/feature_availability.dart';

/// StoreDetailController — state dan logic untuk StoreDetailPage.
///
/// Lokasi: features/store/presentation/controllers/store_detail_controller.dart
///
/// Tanggung jawab:
///   - Ping state & performPing()
///   - isAdminOrAbove
///   - Launch Winbox / VNC / Telnet / CCTV / PingCmd
///   - Reload setelah edit (refreshStore)
///   - hasChanged flag
///   - Notification state untuk Page
///
class StoreDetailController extends ChangeNotifier with NotificationMixin {
  final _repo = StoreRepository();
  final _settingsRepo = SettingsRepository();

  // ── State ─────────────────────────────────────────────────────
  late StoreModel currentStore;
  bool isLoading = false;
  bool hasChanged = false;

  // ── Ping state ────────────────────────────────────────────────
  String pingStatus = 'Mengecek koneksi...';
  Color pingColor = const Color(0xFF7A9CC4);
  String latency = '';

  // ── Notification (via NotificationMixin) ──────────────────────
  /// Error dialog signal — page pops dialog when set.
  String? pendingErrorTitle;
  String? pendingErrorContent;

  void clearErrorDialog() {
    pendingErrorTitle = null;
    pendingErrorContent = null;
  }

  // ── Auth ──────────────────────────────────────────────────────
  bool get isAdminOrAbove => RoleHelper.isAdminOrAbove;

  bool get isMobile => PlatformHelper.isMobile;

  // ── Init ──────────────────────────────────────────────────────

  void init(StoreModel store) {
    currentStore = store;
    if (!isMobile && FeatureAvailability.canUsePing) {
      final ip = store.ipGateway;
      if (ip != null && ip.isNotEmpty) {
        performPing();
      } else {
        pingStatus = 'IP Gateway Kosong';
        pingColor = const Color(0xFFFFB347);
        notifyListeners();
      }
    } else if (isMobile || PlatformHelper.isWeb) {
      // Pada Web/Mobile, ping tidak tersedia
      pingStatus = '-';
      pingColor = const Color(0xFF7A9CC4);
      notifyListeners();
    }
  }

  // ── Ping ──────────────────────────────────────────────────────

  Future<void> performPing() async {
    if (!FeatureAvailability.canUsePing) return;

    final ip = currentStore.ipGateway;
    if (ip == null || ip.isEmpty) return;

    pingStatus = 'Mengecek koneksi...';
    pingColor = const Color(0xFF7A9CC4);
    latency = '';
    notifyListeners();

    final result = await performSinglePing(ip);

    if (result.success) {
      pingColor = const Color(0xFF00E676);
      latency = '${result.latencyMs ?? 0} ms';
      pingStatus = 'ONLINE';
    } else {
      pingColor = const Color(0xFFFF6B6B);
      pingStatus = result.statusText == 'OFFLINE' ? 'OFFLINE' : 'GAGAL';
    }
    notifyListeners();
  }

  // ── Launch Tools ──────────────────────────────────────────────
  //
  // Semua launch methods hanya berjalan di Desktop.
  // Guard FeatureAvailability.canLaunchProcess dipasang di sini.

  Future<void> launchWinbox(String ip) async {
    if (!FeatureAvailability.canLaunchProcess) return;

    final winboxPath = await ToolHelper.getWinboxPath();
    if (!await File(winboxPath).exists()) {
      pendingErrorTitle = "Winbox Tidak Ditemukan";
      pendingErrorContent = "Cek folder instalasi atau legacy: $winboxPath";
      notifyListeners();
      return;
    }
    final result = await _settingsRepo.fetchAppSettings();
    await result.fold(
      (failure) async => notifyError('Gagal: ${failure.message}'),
      (data) async {
        try {
          final winboxPort = data['winbox_port'] ?? '8291';
          final winboxUser = data['koneksi_user'] ?? 'admin';
          final winboxPass = data['koneksi_pass'] ?? '';
          final address = '${ip.trim()}:$winboxPort';
          await Process.start(winboxPath, [address, winboxUser, winboxPass], mode: ProcessStartMode.detached);
          notifyInfo('Winbox diluncurkan ke $address');
        } catch (e) {
          notifyError('Gagal: $e');
        }
      },
    );
  }

  Future<void> launchWinboxWdcp(String ip) async {
    if (!FeatureAvailability.canLaunchProcess) return;

    final winboxPath = await ToolHelper.getWinboxPath();
    if (!await File(winboxPath).exists()) {
      pendingErrorTitle = "Winbox Tidak Ditemukan";
      pendingErrorContent = "Cek folder instalasi atau legacy: $winboxPath";
      notifyListeners();
      return;
    }
    final result = await _settingsRepo.fetchAppSettings();
    await result.fold(
      (failure) async => notifyError('Gagal: ${failure.message}'),
      (data) async {
        try {
          final winboxUser = data['wdcp_user'] ?? 'admin';
          final winboxPass = data['wdcp_pass'] ?? '';
          final winboxPort = data['winbox_port'] ?? '8291';
          final address = '$ip:$winboxPort';
          await Process.start(winboxPath, [address, winboxUser, winboxPass], mode: ProcessStartMode.detached);
          notifyInfo('Winbox (WDCP) diluncurkan ke $address');
        } catch (e) {
          notifyError('Gagal: $e');
        }
      },
    );
  }

  Future<void> launchVnc(String ip) async {
    if (!FeatureAvailability.canLaunchProcess) return;

    const vncPath = r'D:\Edp NetOps\vncviewer.exe';
    if (!File(vncPath).existsSync()) {
      notifyError('File tidak ditemukan: $vncPath');
      return;
    }
    final result = await _settingsRepo.fetchAppSettings();
    await result.fold(
      (failure) async => notifyError('Error: ${failure.message}'),
      (data) async {
        try {
          final vncPassword = data['vnc_pass'] ?? 'konvers1';
          await Process.start(vncPath, [ip, '/password', vncPassword], mode: ProcessStartMode.detached);
          notifyInfo('Membuka VNC ke $ip...');
        } catch (e) {
          notifyError('Error: $e');
        }
      },
    );
  }

  void launchTelnet(String ip) {
    if (!FeatureAvailability.canLaunchProcess) return;

    try {
      Process.start('cmd.exe', ['/c', 'start', 'cmd.exe', '/k', 'telnet $ip 1953'], runInShell: true);
    } catch (e) {
      pendingErrorTitle = "Telnet Gagal";
      pendingErrorContent = "Tidak dapat membuka Telnet ke $ip:1953\n\nPastikan fitur Telnet Windows sudah diaktifkan.";
      notifyListeners();
    }
  }

  void launchCctv(String ip) {
    if (!FeatureAvailability.canLaunchProcess) return;

    const cctvPort = "45200";
    final url = "http://$ip:$cctvPort";
    try {
      Process.run('cmd', ['/c', 'start', 'iexplore', url]);
      notifyInfo('Membuka Internet Explorer ke $url...');
    } catch (e) {
      notifyError('Gagal membuka Internet Explorer: $e');
    }
  }

  void launchPingCmd(String ip) {
    if (!FeatureAvailability.canLaunchProcess) return;

    try {
      Process.start('cmd', ['/c', 'start', 'cmd', '/k', 'ping $ip -t']);
    } catch (e) {
      notifyError('Gagal membuka CMD.');
    }
  }

  // ── Data ──────────────────────────────────────────────────────

  Future<void> refreshStore() async {
    isLoading = true;
    notifyListeners();
    
    final result = await _repo.fetchById(currentStore.id);
    
    result.fold(
      (failure) {
        notifyError('Gagal me-refresh data: ${failure.message}');
        isLoading = false;
        notifyListeners();
      },
      (data) async {
        currentStore = data;
        hasChanged = true;
        isLoading = false;
        notifyListeners();
        await performPing();
      },
    );
  }

  Future<bool> deleteStore() async {
    isLoading = true;
    notifyListeners();
    
    final result = await _repo.delete(currentStore);
    
    return result.fold(
      (failure) {
        isLoading = false;
        notifyError('Gagal menghapus toko: ${failure.message}');
        notifyListeners();
        return false;
      },
      (_) {
        return true;
      },
    );
  }
}
