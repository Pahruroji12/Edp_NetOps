import '../../../../core/platform/native_io.dart';

// import 'package:flutter/material.dart';

import '../../../settings/data/settings_repository.dart';

/// ProcessLauncher — service untuk meluncurkan proses external.
///
/// Lokasi: features/store/presentation/services/process_launcher.dart
///
/// Tanggung jawab:
///   - Meluncurkan Winbox, VNC, Telnet, Ping CMD, CCTV
///   - Mengambil credentials dari Supabase app_settings
///   - Validasi file executable sebelum launch
///   - Menghilangkan hardcoded path dari page
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar/Dialog langsung
///   - Import widget apapun (kecuali Colors untuk result)
///
/// Cara pakai:
///   final launcher = ProcessLauncher();
///   final result = await launcher.launchWinbox(ip);
///   if (!result.success) showError(result.error!);
///

/// Hasil dari operasi launch — pattern Result untuk decouple dari UI.
class LaunchResult {
  final bool success;
  final String? message;
  final String? error;

  const LaunchResult.ok(this.message) : success = true, error = null;
  const LaunchResult.fail(this.error) : success = false, message = null;
}

class ProcessLauncher {
  final SettingsRepository _repo = SettingsRepository();

  // ── Path Configuration ─────────────────────────────────────────
  // Semua path terpusat di sini — tidak lagi hardcoded di page.
  // TODO: Fase berikutnya — pindahkan ke Supabase app_settings.
  static const String _basePath = r'D:\Edp NetOps';
  static const String _winboxPath = r'D:\Edp NetOps\winbox.exe';
  static const String _vncPath = r'D:\Edp NetOps\vncviewer.exe';
  static const String _defaultCctvPort = '45200';

  // ── WINBOX (Mikrotik Gateway) ──────────────────────────────────

  /// Luncurkan Winbox ke IP gateway toko.
  Future<LaunchResult> launchWinbox(String ip) async {
    if (!await File(_winboxPath).exists()) {
      return LaunchResult.fail(
        'Winbox tidak ditemukan di $_basePath\\winbox.exe',
      );
    }
    final result = await _repo.fetchAppSettings();
    return result.fold(
      (failure) => LaunchResult.fail('Gagal memuat konfigurasi: ${failure.message}'),
      (data) {
        try {
          final port = data['winbox_port'] ?? '8291';
          final user = data['koneksi_user'] ?? 'admin';
          final pass = data['koneksi_pass'] ?? '';
          final address = '${ip.trim()}:$port';

          Process.start(_winboxPath, [
            address,
            user,
            pass,
          ], mode: ProcessStartMode.detached);
          return LaunchResult.ok('Winbox diluncurkan ke $address');
        } catch (e) {
          return LaunchResult.fail('Gagal meluncurkan Winbox: $e');
        }
      },
    );
  }

  // ── WINBOX WDCP ────────────────────────────────────────────────

  /// Luncurkan Winbox ke IP RB WDCP dengan credentials WDCP.
  Future<LaunchResult> launchWinboxWdcp(String ip) async {
    if (!await File(_winboxPath).exists()) {
      return LaunchResult.fail(
        'Winbox tidak ditemukan di $_basePath\\winbox.exe',
      );
    }
    final result = await _repo.fetchAppSettings();
    return result.fold(
      (failure) => LaunchResult.fail('Gagal memuat konfigurasi: ${failure.message}'),
      (data) {
        try {
          final user = data['wdcp_user'] ?? 'admin';
          final pass = data['wdcp_pass'] ?? '';
          final port = data['winbox_port'] ?? '8291';
          final address = '$ip:$port';

          Process.start(_winboxPath, [
            address,
            user,
            pass,
          ], mode: ProcessStartMode.detached);
          return LaunchResult.ok('Winbox (WDCP) diluncurkan ke $address');
        } catch (e) {
          return LaunchResult.fail('Gagal meluncurkan Winbox WDCP: $e');
        }
      },
    );
  }

  // ── VNC ────────────────────────────────────────────────────────

  /// Luncurkan VNC Viewer ke IP station/kasir.
  Future<LaunchResult> launchVnc(String ip) async {
    if (!File(_vncPath).existsSync()) {
      return LaunchResult.fail(
        'VNC Viewer tidak ditemukan di $_basePath\\vncviewer.exe',
      );
    }
    final result = await _repo.fetchAppSettings();
    return result.fold(
      (failure) => LaunchResult.fail('Gagal memuat konfigurasi: ${failure.message}'),
      (data) {
        try {
          final password = data['vnc_pass'] ?? 'konvers1';

          Process.start(_vncPath, [
            ip,
            '/password',
            password,
          ], mode: ProcessStartMode.detached);
          return LaunchResult.ok('Membuka VNC ke $ip...');
        } catch (e) {
          return LaunchResult.fail('Gagal meluncurkan VNC: $e');
        }
      },
    );
  }

  // ── TELNET ─────────────────────────────────────────────────────

  /// Luncurkan Telnet ke IP:1953 via CMD.
  Future<LaunchResult> launchTelnet(String ip) async {
    try {
      await Process.start('cmd.exe', [
        '/c',
        'start',
        'cmd.exe',
        '/k',
        'telnet $ip 1953',
      ], runInShell: true);
      return LaunchResult.ok('Telnet diluncurkan ke $ip:1953');
    } catch (e) {
      return LaunchResult.fail(
        'Tidak dapat membuka Telnet ke $ip:1953\n\n'
        'Pastikan fitur Telnet Windows sudah diaktifkan.',
      );
    }
  }

  // ── PING CMD ───────────────────────────────────────────────────

  /// Luncurkan ping -t via CMD (ping continuous).
  Future<LaunchResult> launchPingCmd(String ip) async {
    try {
      await Process.start('cmd', ['/c', 'start', 'cmd', '/k', 'ping $ip -t']);
      return LaunchResult.ok('Ping CMD diluncurkan ke $ip');
    } catch (e) {
      return LaunchResult.fail('Gagal membuka CMD: $e');
    }
  }

  // ── CCTV (Internet Explorer) ───────────────────────────────────

  /// Buka CCTV via Internet Explorer ke IP:45200.
  Future<LaunchResult> launchCctv(String ip) async {
    final url = 'http://$ip:$_defaultCctvPort';
    try {
      await Process.run('cmd', ['/c', 'start', 'iexplore', url]);
      return LaunchResult.ok('Membuka Internet Explorer ke $url...');
    } catch (e) {
      return LaunchResult.fail('Gagal membuka Internet Explorer: $e');
    }
  }
}
