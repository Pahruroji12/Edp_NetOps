import 'package:flutter/foundation.dart';

/// AuthState — Single source of truth untuk data user yang sedang login.
///
/// Lokasi: features/auth/domain/auth_state.dart
///
/// Menggantikan 3 global variable lama di login_page.dart:
///   String currentUserNik = '';
///   String currentUserName = '';
///   String currentUserRole = '';
///
/// Cara akses di mana saja:
///   AuthState.instance.name     → nama user
///   AuthState.instance.role     → role user
///   AuthState.instance.isAdmin  → cek apakah admin
///
class AuthState extends ChangeNotifier {
  // ─── Singleton ───────────────────────────────────────────────
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  // ─── Private fields ──────────────────────────────────────────
  String _nik = '';
  String _name = '';
  String _role = '';

  /// Flag untuk menandai apakah perlu menampilkan notifikasi selamat datang di Dashboard
  bool showWelcomeOnDashboard = false;

  // ─── Getters (read-only dari luar) ───────────────────────────
  String get nik => _nik;
  String get name => _name;
  String get role => _role;

  bool get isLoggedIn => _nik.isNotEmpty;
  bool get isAdmin {
    final r = _role.toLowerCase();
    return r == 'administrator' || r == 'admin';
  }
  bool get isUser => _role == 'user';

  // ─── Methods ─────────────────────────────────────────────────

  /// Dipanggil setelah login berhasil
  void setUser({
    required String nik,
    required String name,
    required String role,
  }) {
    _nik = nik;
    _name = name;
    _role = role;
    showWelcomeOnDashboard = true;
    notifyListeners();
  }

  /// Dipanggil saat logout — reset semua data
  void clear() {
    _nik = '';
    _name = '';
    _role = '';
    showWelcomeOnDashboard = false;
    notifyListeners();
  }

  @override
  String toString() => 'AuthState(nik: $_nik, name: $_name, role: $_role)';
}
