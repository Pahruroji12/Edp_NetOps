import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../domain/user_model.dart';
import '../../../core/services/activity_logger.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

/// ProfileRepository — operasi Supabase untuk profil pengguna & activity logs.
///
/// Lokasi: features/profile/data/profile_repository.dart
///
class ProfileRepository {
  final _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════

  /// Ambil semua user, urutkan by role.
  Future<Result<List<UserModel>>> fetchUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .order('role', ascending: true);
      final users = (res as List).map((j) => UserModel.fromJson(j)).toList();
      return SuccessResult(users);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Ambil semua user, urutkan by is_online (untuk admin panel).
  Future<Result<List<UserModel>>> fetchUsersOnlineFirst() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .order('is_online', ascending: false);
      final users = (res as List).map((j) => UserModel.fromJson(j)).toList();
      return SuccessResult(users);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Hapus user permanen via RPC Supabase.
  Future<Result<void>> deleteUser(String userId, String nama, String nik) async {
    try {
      await _client.rpc('hapus_user_permanen', params: {'target_uid': userId});
      await ActivityLogger.logAction(
        actionType: 'HAPUS_USER',
        description: 'Menghapus pengguna: $nama (NIK: $nik)',
      );
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PASSWORD
  // ══════════════════════════════════════════════════════════════

  /// Verifikasi password lama lalu update ke password baru.
  Future<Result<void>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final authClient = _client.auth;
      final currentEmail = authClient.currentUser?.email;

      if (currentEmail == null) return const ErrorResult(AuthFailure('Sesi login tidak ditemukan.'));

      // Verifikasi password lama
      await authClient.signInWithPassword(
        email: currentEmail,
        password: oldPassword,
      );

      // Update password baru
      await authClient.updateUser(UserAttributes(password: newPassword));

      await ActivityLogger.logAction(
        actionType: 'UBAH_PASSWORD',
        description: 'Pengguna mengubah kata sandi akunnya',
      );
      
      return const SuccessResult(null);
    } on AuthException catch (e) {
      return ErrorResult(AuthFailure(e.message, code: e.statusCode));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ACTIVITY LOGS (untuk AdminPanel)
  // ══════════════════════════════════════════════════════════════

  Future<Result<List<Map<String, dynamic>>>> fetchLogs({int limit = 200}) async {
    try {
      final res = await _client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return SuccessResult(List<Map<String, dynamic>>.from(res));
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
