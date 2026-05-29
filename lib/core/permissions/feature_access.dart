import 'package:flutter/material.dart';

import '../platform/feature_availability.dart';
import 'permission_helper.dart';

/// FeatureAccess — gabungan cek platform + permission.
///
/// Lokasi: core/permissions/feature_access.dart
///
/// Menggabungkan:
///   1. Apakah platform mendukung fitur ini?
///   2. Apakah user punya permission untuk fitur ini?
///
/// Cara pakai:
///   if (FeatureAccess.canShowNetworkTools) { ... }
///   if (FeatureAccess.canShowTicketActions) { ... }
///
/// Widget helper:
///   FeatureAccess.guardedWidget(
///     permission: AppPermission.openTicket,
///     platformCheck: true,
///     child: OpenTicketButton(),
///     fallback: SizedBox.shrink(),
///   );
///
class FeatureAccess {
  FeatureAccess._();

  // ══════════════════════════════════════════════════════════════
  // COMBINED CHECKS (Platform + Role)
  // ══════════════════════════════════════════════════════════════

  /// Network Tools menu: platform harus support + role admin/administrator
  static bool get canShowNetworkTools =>
      FeatureAvailability.canUseNetworkTools &&
      PermissionHelper.can(AppPermission.viewNetworkTools);

  /// Ping Scanner: Windows only + admin role
  static bool get canShowPing =>
      FeatureAvailability.canUsePing &&
      PermissionHelper.can(AppPermission.usePingScanner);

  /// FTP: Desktop only + admin role
  static bool get canShowFtp =>
      FeatureAvailability.canUseFtp &&
      PermissionHelper.can(AppPermission.useFtp);

  /// WDCP Scan: Desktop only + admin role
  static bool get canShowWdcpScan =>
      FeatureAvailability.canUseWdcpScan &&
      PermissionHelper.can(AppPermission.useWdcpScan);

  /// Ticket CRUD actions: role admin/administrator
  static bool get canShowTicketActions =>
      PermissionHelper.can(AppPermission.openTicket);

  /// Process launcher buttons: Windows only + admin role
  static bool get canShowProcessLauncher =>
      FeatureAvailability.canLaunchProcess &&
      PermissionHelper.can(AppPermission.launchWinbox);

  /// Settings page: administrator only
  static bool get canShowSettings =>
      PermissionHelper.can(AppPermission.accessSettings);

  /// Admin panel: administrator only
  static bool get canShowAdminPanel =>
      PermissionHelper.can(AppPermission.accessAdminPanel);

  /// Export data: admin role + filesystem access
  static bool get canExportData =>
      FeatureAvailability.canExportToFile &&
      PermissionHelper.can(AppPermission.exportData);

  // ══════════════════════════════════════════════════════════════
  // WIDGET HELPER — conditional rendering yang clean
  // ══════════════════════════════════════════════════════════════

  /// Render [child] hanya jika user punya [permission].
  /// Jika tidak, render [fallback] (default: SizedBox.shrink = invisible).
  static Widget guardedWidget({
    required AppPermission permission,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    return PermissionHelper.can(permission) ? child : fallback;
  }

  /// Render [child] hanya jika platform mendukung [platformCheck]
  /// DAN user punya [permission].
  static Widget platformGuardedWidget({
    required bool platformCheck,
    required AppPermission permission,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    if (!platformCheck) return fallback;
    if (!PermissionHelper.can(permission)) return fallback;
    return child;
  }

  /// Render [child] hanya jika platform mendukung (tanpa cek permission).
  static Widget platformOnlyWidget({
    required bool platformCheck,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    return platformCheck ? child : fallback;
  }
}
