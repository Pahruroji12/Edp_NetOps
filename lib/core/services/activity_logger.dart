import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../features/auth/domain/auth_state.dart';

/// ActivityLogger — merekam jejak aktivitas & status online user.
///
/// Lokasi: core/services/activity_logger.dart
///
/// Perubahan dari versi lama:
/// - Tidak lagi query Supabase untuk ambil nama/role — sudah ada di AuthState.
/// - Lebih efisien: 1 query insert vs sebelumnya 1 select + 1 insert.
///
class ActivityLogger {
  static final _supabase = Supabase.instance.client;

  /// Merekam jejak aktivitas user ke tabel activity_logs.
  static Future<void> logAction({
    required String actionType,
    required String description,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Gunakan AuthState — tidak perlu query Supabase lagi untuk nama/role
      await _supabase.from('activity_logs').insert({
        'user_name': AuthState.instance.name.isNotEmpty
            ? AuthState.instance.name
            : 'Unknown',
        'user_role': AuthState.instance.role.isNotEmpty
            ? AuthState.instance.role
            : 'Unknown',
        'action_type': actionType,
        'description': description,
      });
    } catch (e) {
      // ignore: avoid_print
      print('System Log Error: $e');
    }
  }

  /// Mengubah status Online / Offline di tabel profiles.
  static Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_active': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', currentUser.id);
    } catch (e) {
      // ignore: avoid_print
      print('System Status Error: $e');
    }
  }
}
