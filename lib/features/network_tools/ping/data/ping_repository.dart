import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ping_config.dart';
import '../domain/ping_result.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';

/// PingRepository — satu-satunya file yang boleh query Supabase untuk ping.
///
/// Lokasi: features/network_tools/ping/data/ping_repository.dart
///
/// Tanggung jawab:
///   - Fetch data toko dari Supabase
///   - Bangun list target berdasarkan PingConfig
///
/// TIDAK BOLEH:
///   - Import Flutter/Material
///   - Extend ChangeNotifier
///   - Menampilkan Snackbar
///   - Menjalankan Process
///
class PingRepository {
  final _client = Supabase.instance.client;

  /// Fetch semua toko dan bangun daftar target berdasarkan config.
  ///
  /// Return: Result<List<PingTarget>> yang siap di-ping.
  Future<Result<List<PingTarget>>> fetchTargets(PingConfig config) async {
    try {
      final response = await _client.from('stores').select();

      final List<PingTarget> targets = [];

      for (final store in response) {
        final storeCode = store['store_code']?.toString() ?? '-';
        final storeName = store['store_name']?.toString() ?? '-';

        void addTarget(String jenis, String? ip) {
          if (ip != null && ip.trim().isNotEmpty && ip != '-') {
            targets.add(PingTarget(
              storeCode: storeCode,
              storeName: storeName,
              deviceType: jenis,
              ip: ip.trim(),
            ));
          }
        }

        if (config.gateway) addTarget('IP Gateway', store['ip_gateway']);
        if (config.station1) addTarget('IP Station 1', store['ip_station_1']);
        if (config.stb) addTarget('IP STB', store['ip_stb']);
        if (config.rbWdcp) addTarget('IP RB WDCP', store['ip_rb_wdcp']);
        if (config.cctv1) addTarget('IP CCTV 1', store['ip_cctv_1']);
        if (config.cctv2) addTarget('IP CCTV 2', store['ip_cctv_2']);
      }

      // Tambahkan IP manual
      if (config.manualIps.trim().isNotEmpty) {
        final lines = config.manualIps.split(RegExp(r'\r?\n'));
        for (final line in lines) {
          final ip = line.trim();
          if (ip.isNotEmpty) {
            targets.add(PingTarget(
              storeCode: '-',
              storeName: 'Input Manual',
              deviceType: 'Custom IP',
              ip: ip,
            ));
          }
        }
      }

      return SuccessResult(targets);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
