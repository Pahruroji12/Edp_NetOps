import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityLogger {
  static final _supabase = Supabase.instance.client;

  /// Fungsi untuk merekam jejak aktivitas
  static Future<void> logAction({
    required String actionType,
    required String description,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Ambil Nama dan Role dari tabel profiles
      final userData = await _supabase
          .from('profiles')
          .select('nama, role')
          .eq('id', currentUser.id)
          .single();

      // Simpan ke tabel log
      await _supabase.from('activity_logs').insert({
        'user_name': userData['nama'] ?? 'Unknown',
        'user_role': userData['role'] ?? 'Unknown',
        'action_type': actionType,
        'description': description,
      });
    } catch (e) {
      print("System Log Error: $e");
    }
  }

  /// Fungsi untuk mengubah status lampu Online / Offline
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
      print("System Status Error: $e");
    }
  }
}
