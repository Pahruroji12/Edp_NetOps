import '../../store/domain/store_model.dart';

/// DashboardStats — domain entity: hasil kalkulasi statistik jaringan.
///
/// Lokasi: features/dashboard/domain/dashboard_stats.dart
///
/// Pure data class tanpa dependency ke Supabase atau data layer.
///
class DashboardStats {
  final List<StoreModel> stores;
  final int total;
  final int fo;
  final int backupVsat;
  final int singleVsat;
  final int gsm;
  final int xl;

  const DashboardStats({
    required this.stores,
    required this.total,
    required this.fo,
    required this.backupVsat,
    required this.singleVsat,
    required this.gsm,
    required this.xl,
  });
}
