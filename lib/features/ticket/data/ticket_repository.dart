import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/ticket_model.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

/// TicketRepository — semua operasi Supabase untuk tabel ticket_logs.
///
/// Lokasi: features/ticket/data/ticket_repository.dart
///
class TicketRepository {
  final _client = Supabase.instance.client;

  /// Ambil semua tiket, diurutkan terbaru dulu.
  Future<Result<List<TicketModel>>> fetchAll() async {
    try {
      final res = await _client
          .from('ticket_logs')
          .select()
          .order('created_at', ascending: false);
      final tickets = (res as List).map((j) => TicketModel.fromJson(j)).toList();
      return SuccessResult(tickets);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Simpan tiket baru setelah email berhasil dikirim.
  Future<Result<void>> insert({
    required String storeCode,
    required String storeName,
    required String provider,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      await _client.from('ticket_logs').insert({
        'store_code': storeCode,
        'store_name': storeName,
        'provider': provider,
        'nomor_tiket': null,
        'status': 'Open',
        'created_by': currentUser?.email ?? currentUser?.id ?? '-',
      });
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Update nomor tiket dan status.
  Future<Result<void>> update({
    required String id,
    required String nomorTiket,
    required String status,
  }) async {
    try {
      await _client
          .from('ticket_logs')
          .update({'nomor_tiket': nomorTiket, 'status': status})
          .eq('id', id);
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Hapus tiket berdasarkan ID.
  Future<Result<void>> delete(String id) async {
    try {
      await _client.from('ticket_logs').delete().eq('id', id);
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
