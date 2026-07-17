import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/domain/auth_state.dart';

/// Model data untuk satu entri riwayat aktivitas STB 24 Jam.
class Stb24JamHistoryItem {
  final String id;
  final String actionType; // 'generate' atau 'report'
  final DateTime tanggal;
  final bool success;
  final int totalToko;
  final int totalOk;
  final int totalNok;
  final String? message;
  final String? userName;
  final DateTime createdAt;

  Stb24JamHistoryItem({
    required this.id,
    required this.actionType,
    required this.tanggal,
    required this.success,
    this.totalToko = 0,
    this.totalOk = 0,
    this.totalNok = 0,
    this.message,
    this.userName,
    required this.createdAt,
  });

  factory Stb24JamHistoryItem.fromMap(Map<String, dynamic> map) {
    return Stb24JamHistoryItem(
      id: map['id'] as String,
      actionType: map['action_type'] as String,
      tanggal: DateTime.parse(map['tanggal'] as String),
      success: map['success'] as bool? ?? false,
      totalToko: map['total_toko'] as int? ?? 0,
      totalOk: map['total_ok'] as int? ?? 0,
      totalNok: map['total_nok'] as int? ?? 0,
      message: map['message'] as String?,
      userName: map['user_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Stb24JamRepository — operasi Supabase untuk riwayat aktivitas STB 24 Jam.
///
/// Lokasi: features/network_tools/stb24jam/data/stb24jam_repository.dart
///
class Stb24JamRepository {
  final _client = Supabase.instance.client;

  /// Simpan entri riwayat baru ke tabel stb24jam_history.
  Future<Result<void>> insertHistory({
    required String actionType,
    required DateTime tanggal,
    required bool success,
    int totalToko = 0,
    int totalOk = 0,
    int totalNok = 0,
    String? message,
  }) async {
    try {
      await _client
          .from('stb24jam_history')
          .insert({
            'action_type': actionType,
            'tanggal':
                '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
            'success': success,
            'total_toko': totalToko,
            'total_ok': totalOk,
            'total_nok': totalNok,
            'message': message,
            'user_name': AuthState.instance.name.isNotEmpty
                ? AuthState.instance.name
                : 'Unknown',
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: Gagal menyimpan riwayat ke server');
            },
          );
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Ambil daftar riwayat terbaru (default 30 entri terakhir).
  Future<Result<List<Stb24JamHistoryItem>>> fetchHistory({
    int limit = 30,
  }) async {
    try {
      final response = await _client
          .from('stb24jam_history')
          .select()
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: Gagal mengambil riwayat dari server');
            },
          );

      final items = (response as List)
          .map((e) => Stb24JamHistoryItem.fromMap(e as Map<String, dynamic>))
          .toList();
      return SuccessResult(items);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Menghapus satu entri riwayat aktivitas berdasarkan ID.
  Future<Result<void>> deleteHistory(String id) async {
    try {
      await _client
          .from('stb24jam_history')
          .delete()
          .eq('id', id)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: Gagal menghapus riwayat dari server');
            },
          );
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
