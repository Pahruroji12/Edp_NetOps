import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../domain/auth_state.dart';
import '../../../core/services/activity_logger.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

/// AuthRepository — semua operasi Supabase yang berkaitan dengan autentikasi.
///
/// Lokasi: features/auth/data/auth_repository.dart
///
class AuthRepository {
  final _client = Supabase.instance.client;

  /// Login dengan NIK + password.
  /// Return nama user jika sukses, ErrorResult jika gagal.
  Future<Result<String>> signIn({required String nik, required String password}) async {
    try {
      final String cleanNik = nik.replaceAll(' ', '');
      final String fakeEmail = '$cleanNik@edp.com';

      final AuthResponse res = await _client.auth.signInWithPassword(
        email: fakeEmail,
        password: password,
      );

      if (res.user == null) {
        return const ErrorResult(AuthFailure('Login gagal: user null'));
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .single();

      AuthState.instance.setUser(
        nik: profile['nik'] ?? '',
        name: profile['nama'] ?? 'Karyawan',
        role: profile['role'] ?? 'user',
      );

      await ActivityLogger.updateOnlineStatus(true);
      await ActivityLogger.logAction(
        actionType: 'LOGIN',
        description: 'Pengguna berhasil masuk ke sistem',
      );

      return SuccessResult(AuthState.instance.name);
    } on AuthException catch (e) {
      return ErrorResult(AuthFailure(e.message));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Logout — update status offline, catat log, clear auth state.
  Future<Result<void>> signOut() async {
    try {
      await ActivityLogger.updateOnlineStatus(false);
      await ActivityLogger.logAction(
        actionType: 'LOGOUT',
        description: 'Pengguna keluar dari sistem',
      );
      await _client.auth.signOut();
      AuthState.instance.clear();
      return const SuccessResult(null);
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
