import '../../features/auth/domain/auth_state.dart';
import '../permissions/permission_helper.dart';
import '../platform/feature_availability.dart';

/// AuthGuard — route-level security validation.
///
/// Lokasi: core/guards/auth_guard.dart
///
/// Dipakai di GoRouter redirect untuk memastikan:
///   1. User sudah login
///   2. User punya permission untuk route tersebut
///   3. Platform mendukung fitur di route tersebut
///
/// Cara pakai di GoRouter:
///   redirect: (context, state) {
///     final guard = AuthGuard.checkRoute(state.matchedLocation);
///     if (guard != null) return guard; // redirect
///     return null; // lanjut
///   }
///
class AuthGuard {
  AuthGuard._();

  // ── Route → Permission Mapping ─────────────────────────────────
  static const _routePermissions = <String, AppPermission>{
    '/ping': AppPermission.usePingScanner,
    '/scan-wdcp': AppPermission.useWdcpScan,
    '/settings': AppPermission.accessSettings,
    '/admin': AppPermission.accessAdminPanel,
  };

  // ── Route → Platform Check Mapping ─────────────────────────────
  static final _routePlatformChecks = <String, bool Function()>{
    '/ping': () => FeatureAvailability.canUsePing,
    '/scan-wdcp': () => FeatureAvailability.canUseWdcpScan,
  };

  /// Cek apakah route [path] boleh diakses.
  ///
  /// Return:
  ///   - `null` → akses diizinkan, lanjutkan navigasi
  ///   - `/dashboard` → redirect ke dashboard (tidak diizinkan)
  ///   - `/login` → redirect ke login (belum login)
  ///
  static String? checkRoute(String path) {
    final auth = AuthState.instance;

    // 1. Belum login → redirect ke login
    if (!auth.isLoggedIn) {
      return path == '/login' ? null : '/login';
    }

    // 2. Sudah login tapi buka /login → redirect ke dashboard
    if (auth.isLoggedIn && path == '/login') {
      return '/dashboard';
    }

    // 3. Cek platform support untuk route tertentu
    final platformCheck = _routePlatformChecks[path];
    if (platformCheck != null && !platformCheck()) {
      final featureName = path == '/ping' ? 'Ping Scanner' : 'Scan RbWDCP';
      return '/unsupported-feature?feature=$featureName';
    }

    // 4. Cek permission untuk route tertentu
    final requiredPermission = _routePermissions[path];
    if (requiredPermission != null && !PermissionHelper.can(requiredPermission)) {
      return '/dashboard';
    }

    // 5. Semua aman — lanjutkan
    return null;
  }

  /// Cek apakah current user boleh mengakses fitur tertentu.
  /// Menggabungkan auth + permission + platform check.
  ///
  /// Return true jika semua kondisi terpenuhi.
  static bool canAccess({
    AppPermission? permission,
    bool? platformSupported,
  }) {
    if (!AuthState.instance.isLoggedIn) return false;
    if (permission != null && !PermissionHelper.can(permission)) return false;
    if (platformSupported != null && !platformSupported) return false;
    return true;
  }
}
