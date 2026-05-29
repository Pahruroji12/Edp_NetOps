import 'package:supabase_flutter/supabase_flutter.dart';
import '../../store/domain/store_model.dart';
import '../domain/dashboard_stats.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

/// DashboardRepository — fetch dan kalkulasi data dashboard.
///
/// Lokasi: features/dashboard/data/dashboard_repository.dart
///
class DashboardRepository {
  final _client = Supabase.instance.client;

  Future<Result<DashboardStats>> fetchStats() async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .order('store_code', ascending: true);

      final stores = (response as List)
          .map((j) => StoreModel.fromJson(j))
          .toList();

      int fo = 0, backupVsat = 0, singleVsat = 0, gsm = 0, xl = 0;

      for (final store in stores) {
        final main = store.connectionType?.toLowerCase() ?? '';
        final back = store.connectionBackup?.toLowerCase() ?? '';
        final ipVsat = store.ipVsat ?? '';

        final isFo =
            main.contains('astinet') ||
            main.contains('icon') ||
            main.contains('fiberstar');
        if (isFo) fo++;

        final hasVsatIp = ipVsat.isNotEmpty;
        final isBackupVsat =
            !main.contains('vsat') && (back.contains('vsat') || hasVsatIp);
        if (isBackupVsat) backupVsat++;

        if (main.contains('vsat') || (main.isEmpty && hasVsatIp)) singleVsat++;
        if (main.contains('gsm') || main.contains('orbit')) gsm++;
        if (main.contains('xl')) xl++;
      }

      return SuccessResult(DashboardStats(
        stores: stores,
        total: stores.length,
        fo: fo,
        backupVsat: backupVsat,
        singleVsat: singleVsat,
        gsm: gsm,
        xl: xl,
      ));
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
