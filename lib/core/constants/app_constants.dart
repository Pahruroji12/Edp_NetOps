/// AppConstants — konstanta global aplikasi.
///
/// Lokasi: core/constants/app_constants.dart
///
/// Menghilangkan semua hardcoded values yang tersebar di codebase.
/// Fase berikutnya: pindahkan ke Supabase app_settings.
///
class AppConstants {
  AppConstants._();

  // ── Aplikasi ───────────────────────────────────────────────────
  static const String appName = 'EDP NetOps';
  static const String appVersion = '3.1.0';

  // ── Path Executable (Windows Desktop) ──────────────────────────
  static const String basePath = r'D:\Edp NetOps';
  static const String winboxPath = r'D:\Edp NetOps\winbox.exe';
  static const String vncViewerPath = r'D:\Edp NetOps\vncviewer.exe';
  static const String pingOutputDir = r'D:\Edp NetOps\Hasil Ping';
  static const String stb24JamRekapDir = r'D:\Rekap Ping STB 24 Jam';
  static const String slaReportOutputDir = r'D:\Report SLA & Data dispensasi';

  // ── Port Default ───────────────────────────────────────────────
  static const String defaultWinboxPort = '8291';
  static const String defaultTelnetPort = '1953';
  static const String defaultCctvPort = '45200';

  // ── FTP ────────────────────────────────────────────────────────
  static const int ftpDefaultPort = 21;
  static const int ftpConnectTimeout = 10;

  // ── Network ────────────────────────────────────────────────────
  static const int pingTimeout = 2; // seconds
  static const int pingCount = 1;

  // ── UI ─────────────────────────────────────────────────────────
  static const double sidebarBreakpoint = 850.0;
  static const double dialogMaxWidth = 520.0;
  static const double cardBorderRadius = 16.0;

  // ── Supabase Tables ────────────────────────────────────────────
  static const String tableStores = 'stores';
  static const String tableUsers = 'users';
  static const String tableAppSettings = 'app_settings';
  static const String tableTickets = 'tickets';
  static const String tableActivityLog = 'activity_log';
}
