import 'package:edp_netops/core/platform/native_io.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mikrotik_api_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/tool_helper.dart';
import '../../../../core/error/failures.dart';

/// WdcpRepository — operasi data untuk fitur WDCP Control.
///
/// Lokasi: features/network_tools/wdcp/data/wdcp_repository.dart
///
/// Tanggung jawab:
///   - Fetch kredensial WDCP dari Supabase
///   - Koneksi ke router MikroTik dan fetch data
///   - CRUD access list
///   - Toggle default authenticate
///   - Launch Winbox
///
class WdcpRepository {
  final _client = Supabase.instance.client;

  /// Ambil kredensial WDCP dari app_settings.
  Future<Result<Map<String, String>>> fetchWdcpCredentials() async {
    try {
      final response = await _client.from('app_settings').select();
      final data = {
        for (var item in response) item['key'] as String: item['value'] as String,
      };
      return SuccessResult({
        'wdcp_user': data['wdcp_user'] ?? 'admin',
        'wdcp_pass': data['wdcp_pass'] ?? '',
        'api_port': data['api_port'] ?? '8728',
        'winbox_port': data['winbox_port'] ?? '8291',
      });
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Koneksi ke router dan ambil semua data sekaligus.
  Future<Result<Map<String, dynamic>>> connectAndFetch({
    required String ip,
    required int apiPort,
    required String user,
    required String pass,
  }) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(ip, apiPort, user, pass);

      List<Map<String, String>> devices = [];
      List<Map<String, String>> accessList = [];
      bool authStatus = false;
      Map<String, String> sysInfo = {};

      try { devices = await svc.getRegistrationTable(); } catch (_) {}
      try { accessList = await svc.getAccessList(); } catch (_) {}
      try { authStatus = await svc.getDefaultAuthStatus(); } catch (_) {}
      try { sysInfo = await svc.getSystemResource(); } catch (_) {}

      return SuccessResult({
        'devices': devices,
        'accessList': accessList,
        'authStatus': authStatus,
        'sysInfo': sysInfo,
      });
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    } finally {
      svc.disconnect();
    }
  }

  /// Tambah MAC ke access list.
  Future<Result<void>> addMac({
    required String ip,
    required int apiPort,
    required String user,
    required String pass,
    required String mac,
    required String comment,
  }) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(ip, apiPort, user, pass);
      await svc.addAccessList(mac, comment);
      return const SuccessResult(null);
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    } finally {
      svc.disconnect();
    }
  }

  /// Hapus MAC dari access list.
  Future<Result<void>> removeMac({
    required String ip,
    required int apiPort,
    required String user,
    required String pass,
    required String id,
  }) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(ip, apiPort, user, pass);
      await svc.removeAccessList(id);
      return const SuccessResult(null);
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    } finally {
      svc.disconnect();
    }
  }

  /// Toggle default authenticate.
  Future<Result<void>> toggleAuth({
    required String ip,
    required int apiPort,
    required String user,
    required String pass,
    required bool value,
  }) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(ip, apiPort, user, pass);
      await svc.setDefaultAuth(value);
      return const SuccessResult(null);
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    } finally {
      svc.disconnect();
    }
  }

  /// Launch Winbox ke IP tertentu.
  Future<Result<String>> launchWinbox({
    required String ip,
    required String winboxPort,
    required String user,
    required String pass,
  }) async {
    final winboxPath = await ToolHelper.getWinboxPath();
    if (!await File(winboxPath).exists()) {
      return ErrorResult(UnknownFailure('File winbox.exe tidak ditemukan di: $winboxPath'));
    }
    try {
      final address = '$ip:$winboxPort';
      await Process.start(
        winboxPath,
        [address, user, pass],
        mode: ProcessStartMode.detached,
      );
      return SuccessResult(address);
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
