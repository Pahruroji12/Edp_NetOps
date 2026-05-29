import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/store_model.dart';
import '../../../core/services/activity_logger.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

/// StoreRepository — semua operasi Supabase untuk data toko & app settings.
///
/// Lokasi: features/store/data/store_repository.dart
///
class StoreRepository {
  final _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // STORE CRUD
  // ══════════════════════════════════════════════════════════════

  /// Ambil semua toko, diurutkan berdasarkan kode toko.
  Future<Result<List<StoreModel>>> fetchAll() async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .order('store_code', ascending: true);
      final stores = (response as List).map((j) => StoreModel.fromJson(j)).toList();
      return SuccessResult(stores);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Ambil satu toko berdasarkan ID.
  Future<Result<StoreModel>> fetchById(String id) async {
    try {
      final response = await _client
          .from('stores')
          .select()
          .eq('id', id)
          .single();
      return SuccessResult(StoreModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Tambah toko baru.
  Future<Result<void>> insert(Map<String, dynamic> data) async {
    try {
      await _client.from('stores').insert(data);
      await ActivityLogger.logAction(
        actionType: 'TAMBAH_TOKO',
        description: "Menambahkan data toko baru: ${data['store_name']}",
      );
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return ErrorResult(ServerFailure("Kode Toko '${data['store_code']}' sudah terdaftar!", code: e.code));
      }
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Update data toko yang sudah ada.
  Future<Result<void>> update(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('stores').update(data).eq('id', id);
      await ActivityLogger.logAction(
        actionType: 'EDIT_TOKO',
        description: "Mengubah data toko: ${data['store_name']}",
      );
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return ErrorResult(ServerFailure("Kode Toko '${data['store_code']}' sudah terdaftar!", code: e.code));
      }
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Hapus toko berdasarkan ID.
  Future<Result<void>> delete(StoreModel store) async {
    try {
      await _client.from('stores').delete().eq('id', store.id);
      await ActivityLogger.logAction(
        actionType: 'HAPUS_TOKO',
        description: "Menghapus data toko: ${store.storeCode} - ${store.storeName}",
      );
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
