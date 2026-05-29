import '../../../features/auth/domain/auth_state.dart';

/// RoleHelper — utility untuk role checks di seluruh codebase.
///
/// Lokasi: core/utils/role_helper.dart
///
/// Menghilangkan duplikasi pattern:
///   AuthState.instance.role.toLowerCase() == 'administrator'
///   AuthState.instance.role.toLowerCase() == 'admin'
///   role == 'administrator' || role == 'admin'
///
/// Cara pakai:
///   if (RoleHelper.isAdminOrAbove) { ... }
///   if (RoleHelper.isAdministrator) { ... }  // hanya super admin
///   final label = RoleHelper.labelFor(role);
///
class RoleHelper {
  RoleHelper._();

  static AuthState get _auth => AuthState.instance;

  // ── Role Checks (current user) ─────────────────────────────────

  /// True jika role == 'administrator' (super admin).
  static bool get isAdministrator =>
      _auth.role.toLowerCase() == 'administrator';

  /// True jika role == 'administrator' atau 'admin'.
  static bool get isAdminOrAbove => _auth.isAdmin;

  /// True jika role == 'user'.
  static bool get isUser => _auth.isUser;

  // ── Role Checks (arbitrary role string) ─────────────────────────

  /// Cek apakah role tertentu termasuk admin-level.
  static bool isAdminRole(String role) {
    final r = role.toLowerCase();
    return r == 'administrator' || r == 'admin';
  }

  /// Cek apakah role tertentu adalah super admin.
  static bool isAdministratorRole(String role) =>
      role.toLowerCase() == 'administrator';

  // ── Label ───────────────────────────────────────────────────────

  /// Human-readable label untuk role.
  static String labelFor(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
        return 'ADMINISTRATOR';
      case 'admin':
        return 'ADMIN';
      case 'user':
        return 'USER';
      default:
        return role.toUpperCase();
    }
  }
}
