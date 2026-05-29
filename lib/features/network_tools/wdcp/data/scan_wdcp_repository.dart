import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';

/// ScanWdcpRepository — operasi Supabase untuk fitur Scan WDCP.
///
/// Lokasi: features/network_tools/wdcp/data/scan_wdcp_repository.dart
///
/// Tanggung jawab:
///   - Fetch daftar toko yang memiliki IP WDCP
///   - Fetch kredensial WDCP dari app_settings
///
/// Tidak ada business logic di sini — hanya data access.
///
class ScanWdcpRepository {
  final _client = Supabase.instance.client;

  /// Ambil semua toko yang punya IP WDCP valid, urut by store_code.
  Future<Result<List<Map<String, dynamic>>>> fetchStoresWithWdcpIp() async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .order('store_code', ascending: true);

      final List<Map<String, dynamic>> validStores = [];
      for (var item in response) {
        final ipWdcp = (item['ip_rb_wdcp'] ?? '').toString().trim();
        if (ipWdcp.isNotEmpty && ipWdcp != '-') {
          validStores.add(item);
        }
      }
      return SuccessResult(validStores);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Ambil kredensial WDCP (user, pass, winbox_port) dari app_settings.
  Future<Result<Map<String, String>>> fetchWdcpCredentials() async {
    try {
      final response = await _client.from('app_settings').select();
      final data = {
        for (var item in response) item['key'] as String: item['value'] as String,
      };
      return SuccessResult({
        'wdcp_user': data['wdcp_user'] ?? 'admin',
        'wdcp_pass': data['wdcp_pass'] ?? '',
        'winbox_port': data['winbox_port'] ?? '8291',
      });
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
