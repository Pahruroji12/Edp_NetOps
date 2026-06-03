import 'platform_helper.dart';

/// FeatureAvailability — cek apakah fitur tertentu tersedia di platform ini.
///
/// Lokasi: core/platform/feature_availability.dart
///
/// Single source of truth untuk feature flags per platform.
/// Semua pengecekan platform terpusat di sini — tidak tersebar di widget.
///
/// Cara pakai:
///   if (FeatureAvailability.canUsePing) { ... }
///   if (FeatureAvailability.canUseFtp) { ... }
///   if (FeatureAvailability.canLaunchProcess) { ... }
///
class FeatureAvailability {
  FeatureAvailability._();

  // ══════════════════════════════════════════════════════════════
  // NETWORK TOOLS
  // ══════════════════════════════════════════════════════════════

  /// Ping Scanner — hanya di Windows (menggunakan Process.run 'ping')
  static bool get canUsePing => PlatformHelper.isWindows;
  static bool get canUsePingTools => canUsePing;

  /// FTP Client — hanya di Desktop (menggunakan raw TCP Socket)
  static bool get canUseFtp => PlatformHelper.isDesktop;

  /// Mikrotik API / WDCP Scanner — hanya di Desktop (TCP Socket)
  static bool get canUseMikrotikApi => PlatformHelper.isDesktop;

  /// WDCP Scan — hanya di Desktop
  static bool get canUseWdcpScan => PlatformHelper.isDesktop;
  static bool get canUseWdcpScanner => canUseWdcpScan;

  /// Network Tools group — semua sub-fitur network
  static bool get canUseNetworkTools =>
      canUsePing || canUseFtp || canUseMikrotikApi || canUseWdcpScan;

  // ══════════════════════════════════════════════════════════════
  // PROCESS LAUNCHER (Windows-only tools)
  // ══════════════════════════════════════════════════════════════

  /// Launch Winbox, VNC, Telnet, Ping CMD — hanya Windows
  static bool get canLaunchProcess => PlatformHelper.isWindows;
  static bool get canUseExternalProcess => canLaunchProcess;

  /// Launch explorer.exe — hanya Windows
  static bool get canOpenExplorer => PlatformHelper.isWindows;

  /// Control local background worker (VBS/Node) — hanya Windows / Desktop
  static bool get canUseWorkerControl => PlatformHelper.isWindows;

  /// Local file system direct export + Open Explorer — hanya Windows
  static bool get canUseDesktopOnlyExport => PlatformHelper.isWindows;

  /// Auto Update Service (Windows installer or Android APK install)
  static bool get canUseAutoUpdate => PlatformHelper.isWindows || PlatformHelper.isAndroid;

  // ══════════════════════════════════════════════════════════════
  // FILE SYSTEM
  // ══════════════════════════════════════════════════════════════

  /// File system access (read/write lokal) — tidak tersedia di Web
  static bool get canAccessFileSystem => !PlatformHelper.isWeb;

  /// Hardcoded Windows path (D:\Edp NetOps) — hanya Windows
  static bool get canUseWindowsPaths => PlatformHelper.isWindows;

  // ══════════════════════════════════════════════════════════════
  // DESKTOP-ONLY UI
  // ══════════════════════════════════════════════════════════════

  /// Window Manager — hanya Desktop
  static bool get canUseWindowManager => PlatformHelper.isDesktop;

  /// Desktop Drag & Drop (desktop_drop package) — hanya Desktop
  static bool get canUseDragDrop => PlatformHelper.isDesktop;

  /// Pasteboard (clipboard file paste) — hanya Desktop
  static bool get canUsePasteboard => PlatformHelper.isDesktop;

  // ══════════════════════════════════════════════════════════════
  // EMAIL / SMTP
  // ══════════════════════════════════════════════════════════════

  /// SMTP Email (mailer package) — tidak tersedia di Web
  static bool get canSendEmail => !PlatformHelper.isWeb;

  // ══════════════════════════════════════════════════════════════
  // EXPORT
  // ══════════════════════════════════════════════════════════════

  /// Export ke file lokal (Downloads folder) — tidak di Web
  static bool get canExportToFile => !PlatformHelper.isWeb;

  /// Share file (share_plus) — tersedia di mobile & desktop
  static bool get canShareFile => !PlatformHelper.isWeb;

  // ══════════════════════════════════════════════════════════════
  // HELPER: Descriptive reason mengapa fitur tidak tersedia
  // ══════════════════════════════════════════════════════════════

  /// Pesan alasan mengapa fitur tidak tersedia di platform saat ini.
  static String unavailableReason(String featureName) {
    final platform = PlatformHelper.platformName;
    if (PlatformHelper.isWeb) {
      return '$featureName tidak tersedia di versi Web.\n'
          'Gunakan aplikasi Desktop untuk mengakses fitur ini.';
    }
    if (PlatformHelper.isMobile) {
      return '$featureName tidak tersedia di $platform.\n'
          'Fitur ini hanya tersedia di Desktop (Windows).';
    }
    return '$featureName tidak tersedia di $platform.';
  }
}
