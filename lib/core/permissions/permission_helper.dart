import '../../features/auth/domain/auth_state.dart';
import '../utils/role_helper.dart';

/// AppPermission — enum fitur yang membutuhkan akses terbatas.
///
/// Digunakan bersama [PermissionHelper.hasAccess] untuk cek akses.
///
enum AppPermission {
  // ── Network Tools ──────────────────────────────────────────────
  viewNetworkTools,
  usePingScanner,
  useFtp,
  useWdcpScan,
  useMikrotikControl,

  // ── Ticket Management ──────────────────────────────────────────
  viewTickets,       // semua role bisa lihat
  openTicket,        // buat tiket baru
  updateTicket,      // update nomor tiket / status
  deleteTicket,      // hapus tiket

  // ── Store Management ───────────────────────────────────────────
  viewStores,        // semua role bisa lihat
  editStore,         // edit data toko
  deleteStore,       // hapus toko

  // ── Admin Features ─────────────────────────────────────────────
  accessSettings,    // halaman settings
  accessAdminPanel,  // halaman admin panel / control center
  exportData,        // export ke Excel

  // ── Process Launcher ───────────────────────────────────────────
  launchWinbox,
  launchVnc,
  launchTelnet,
  launchPingCmd,
}

/// PermissionHelper — reusable permission checker untuk seluruh aplikasi.
///
/// Lokasi: core/permissions/permission_helper.dart
///
/// Single source of truth untuk permission matrix.
/// Menghilangkan duplikasi `if (role == 'administrator' || role == 'admin')`.
///
/// Cara pakai:
///   if (PermissionHelper.hasAccess(AppPermission.openTicket)) { ... }
///   if (PermissionHelper.can(AppPermission.viewNetworkTools)) { ... }
///
class PermissionHelper {
  PermissionHelper._();

  /// Cek apakah current user punya akses ke [permission].
  static bool hasAccess(AppPermission permission) {
    return _checkPermission(AuthState.instance.role, permission);
  }

  /// Alias lebih pendek untuk [hasAccess].
  static bool can(AppPermission permission) => hasAccess(permission);

  /// Cek akses berdasarkan role string tertentu (bukan current user).
  static bool hasAccessForRole(String role, AppPermission permission) {
    return _checkPermission(role, permission);
  }

  /// Cek multiple permissions sekaligus — semua harus true.
  static bool hasAllAccess(List<AppPermission> permissions) {
    return permissions.every((p) => hasAccess(p));
  }

  /// Cek multiple permissions sekaligus — minimal satu true.
  static bool hasAnyAccess(List<AppPermission> permissions) {
    return permissions.any((p) => hasAccess(p));
  }

  // ══════════════════════════════════════════════════════════════
  // PERMISSION MATRIX
  // ══════════════════════════════════════════════════════════════

  static bool _checkPermission(String role, AppPermission permission) {
    final isAdminLevel = RoleHelper.isAdminRole(role);
    final isSuperAdmin = RoleHelper.isAdministratorRole(role);

    switch (permission) {
      // ── Network Tools: admin/administrator only ─────────────────
      case AppPermission.viewNetworkTools:
      case AppPermission.usePingScanner:
      case AppPermission.useFtp:
      case AppPermission.useWdcpScan:
      case AppPermission.useMikrotikControl:
        return isAdminLevel;

      // ── Tickets ─────────────────────────────────────────────────
      case AppPermission.viewTickets:
        return true; // semua role bisa lihat
      case AppPermission.openTicket:
      case AppPermission.updateTicket:
      case AppPermission.deleteTicket:
        return isAdminLevel;

      // ── Stores ──────────────────────────────────────────────────
      case AppPermission.viewStores:
        return true; // semua role bisa lihat
      case AppPermission.editStore:
      case AppPermission.deleteStore:
        return isAdminLevel;

      // ── Admin Features ──────────────────────────────────────────
      case AppPermission.accessSettings:
      case AppPermission.accessAdminPanel:
        return isSuperAdmin; // hanya administrator (super admin)
      case AppPermission.exportData:
        return isAdminLevel;

      // ── Process Launcher ────────────────────────────────────────
      case AppPermission.launchWinbox:
      case AppPermission.launchVnc:
      case AppPermission.launchTelnet:
      case AppPermission.launchPingCmd:
        return isAdminLevel;
    }
  }
}
