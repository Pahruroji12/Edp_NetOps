import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/services/activity_logger.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

/// SettingsRepository — operasi Supabase untuk konfigurasi sistem & manajemen user.
///
/// Lokasi: features/settings/data/settings_repository.dart
///
class SettingsRepository {
  final _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // APP SETTINGS (Router, VNC, SMTP)
  // ══════════════════════════════════════════════════════════════

  /// Ambil semua konfigurasi sebagai Map<key, value>.
  Future<Result<Map<String, String>>> fetchAppSettings() async {
    try {
      final response = await _client.from('app_settings').select();
      return SuccessResult({
        for (var item in response as List)
          item['key'] as String: item['value'] as String,
      });
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Simpan / update sebagian konfigurasi (upsert).
  Future<Result<void>> saveAppSettings(List<Map<String, dynamic>> data) async {
    try {
      await _client.from('app_settings').upsert(data);
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  /// Cari user berdasarkan NIK. Return null jika tidak ditemukan.
  Future<Result<Map<String, dynamic>?>> searchUserByNik(String nik) async {
    try {
      final res = await _client.from('profiles').select().eq('nik', nik).maybeSingle();
      return SuccessResult(res);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Tambah user baru — daftar di Supabase Auth lalu insert profil.
  Future<Result<void>> createUser({
    required String nik,
    required String nama,
    required String password,
    required String role,
  }) async {
    try {
      final cleanNik = nik.trim().replaceAll(' ', '');
      final fakeEmail = '$cleanNik@edp.com';

      final res = await _client.auth.signUp(email: fakeEmail, password: password);

      if (res.user != null) {
        await _client.from('profiles').insert({
          'id': res.user!.id,
          'nik': nik.trim(),
          'nama': nama.trim(),
          'role': role,
        });

        await ActivityLogger.logAction(
          actionType: 'TAMBAH_USER',
          description: 'Menambahkan akun baru: $nama ($role)',
        );
      }
      return const SuccessResult(null);
    } on AuthException catch (e) {
      return ErrorResult(AuthFailure(e.message, code: e.statusCode));
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Update nama & role user yang sudah ada.
  Future<Result<void>> updateUser({
    required String profileId,
    required String nik,
    required String nama,
    required String role,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({'nama': nama.trim(), 'role': role})
          .eq('id', profileId);

      await ActivityLogger.logAction(
        actionType: 'EDIT_USER',
        description: 'Mengubah data: $nik → $nama ($role)',
      );
      
      return const SuccessResult(null);
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }
}
