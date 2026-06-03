import 'package:edp_netops/core/platform/native_io.dart';

import 'package:flutter/material.dart';

import '../data/ftp_client.dart';
import '../data/ftp_service.dart';
import '../../../settings/data/settings_repository.dart';
import '../../../../core/utils/notification_mixin.dart';

/// FtpController — semua state dan logic untuk FtpPage.
///
/// Lokasi: features/network_tools/ftp/presentation/ftp_controller.dart
///
/// Tanggung jawab:
///   - Kelola state koneksi FTP (isConnected, isConnecting)
///   - Kelola state panel lokal (localPath, localFiles, selectedLocalFile)
///   - Kelola state panel remote (remotePath, remoteFiles, selectedRemoteFile)
///   - Operasi file: connect, load directory, upload, download, delete
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung (gunakan callback/notification state)
///   - Import widget selain ChangeNotifier
///
class FtpController extends ChangeNotifier with NotificationMixin {
  final FtpService ftpService = FtpService();

  // ── Parameter (dari FtpPage widget) ────────────────────────────
  final String targetIp;
  final String storeCode;
  final String storeName;

  FtpController({
    required this.targetIp,
    required this.storeCode,
    required this.storeName,
  });

  // ── FTP Credentials (dari Supabase app_settings) ───────────────
  final SettingsRepository _settingsRepo = SettingsRepository();
  String _ftpUser = '';
  String _ftpPass = '';
  bool isLoadingSettings = false;
  String? settingsError;

  // ── State: Koneksi ─────────────────────────────────────────────
  bool isConnected = false;
  bool isConnecting = false;

  // ── State: Panel Lokal ─────────────────────────────────────────
  String localPath = "C:\\";
  List<FileSystemEntity> localFiles = [];
  File? selectedLocalFile;
  List<String> availableDrives = [];

  // ── State: Panel Remote ────────────────────────────────────────
  String remotePath = "/";
  List<FtpEntry> remoteFiles = [];
  FtpEntry? selectedRemoteFile;
  bool isLoadingRemote = false;
  String? remoteError;
  String remoteErrorDetail = '';

  // ── State: Operasi ─────────────────────────────────────────────
  bool isDeletingLocal = false;
  bool isDeletingRemote = false;

  // ── State: Notification (via NotificationMixin) ────────────────

  // ── INISIALISASI ───────────────────────────────────────────────

  void init() {
    scanAvailableDrives();
    _loadSettingsAndConnect();
  }

  /// Muat FTP credentials dari Supabase app_settings, lalu connect.
  Future<void> _loadSettingsAndConnect() async {
    isLoadingSettings = true;
    settingsError = null;
    notifyListeners();

    final result = await _settingsRepo.fetchAppSettings();
    result.fold(
      (failure) {
        isLoadingSettings = false;
        settingsError = 'Gagal memuat konfigurasi FTP: ${failure.message}';
        notifyError('Gagal memuat konfigurasi FTP dari server.');
        notifyListeners();
      },
      (data) {
        _ftpUser = data['ftp_user'] ?? '';
        _ftpPass = data['ftp_pass'] ?? '';

        // Inject ke FtpService (singleton) agar upload/download juga pakai
        ftpService.setCredentials(user: _ftpUser, pass: _ftpPass);

        isLoadingSettings = false;
        notifyListeners();
      },
    );

    // Setelah credentials tersedia, connect ke remote
    if (settingsError == null) {
      await connectAndLoad();
    }
  }

  // ── LOKAL ──────────────────────────────────────────────────────

  void scanAvailableDrives() {
    final drives = <String>[];
    for (int i = 67; i <= 90; i++) {
      final drive = "${String.fromCharCode(i)}:\\";
      try {
        if (Directory(drive).existsSync()) drives.add(drive);
      } catch (_) {}
    }
    const targetFolder = r'D:\Siaran offline';
    availableDrives = drives;
    if (drives.contains("D:\\")) {
      localPath = "D:\\";
    } else if (drives.isNotEmpty) {
      localPath = drives.first;
    }

    // Langsung buka folder D:\Siaran offline jika ada, fallback ke drive
    if (Directory(targetFolder).existsSync()) {
      loadLocalDirectory(targetFolder);
    } else if (drives.isNotEmpty) {
      loadLocalDirectory(localPath);
    }
  }

  void loadLocalDirectory(String path) {
    try {
      final entities = Directory(path).listSync();
      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      localPath = path;
      localFiles = entities;
      selectedLocalFile = null;
      notifyListeners();
    } catch (_) {
      notifyError("Akses folder ditolak.");
    }
  }

  void selectLocalFile(File file) {
    selectedLocalFile = file;
    notifyListeners();
  }

  Future<void> deleteLocalFile() async {
    if (selectedLocalFile == null) {
      notifyWarning("Pilih file di panel kiri terlebih dahulu.");
      return;
    }

    // Dialog confirmation handled by Page — controller hanya eksekusi
    isDeletingLocal = true;
    notifyListeners();
    try {
      await selectedLocalFile!.delete();
      notifyWarning("File lokal berhasil dihapus.");
      loadLocalDirectory(localPath);
    } catch (_) {
      notifyError("Gagal menghapus file lokal.");
    } finally {
      isDeletingLocal = false;
      notifyListeners();
    }
  }

  /// Nama file lokal yang dipilih (untuk dialog konfirmasi).
  String? get selectedLocalFileName {
    if (selectedLocalFile == null) return null;
    return selectedLocalFile!.path.split(Platform.pathSeparator).last;
  }

  // ── REMOTE ─────────────────────────────────────────────────────

  Future<void> connectAndLoad() async {
    // ── Guard: credentials harus tersedia ──
    if (_ftpUser.isEmpty || _ftpPass.isEmpty) {
      isConnected = false;
      isConnecting = false;
      remoteError = 'no_credentials';
      remoteErrorDetail =
          'Credential FTP belum dikonfigurasi.\n'
          'Hubungi Administrator untuk mengisi User & Password FTP\n'
          'di menu Pengaturan → Konfigurasi Sistem → FTP STB.';
      notifyListeners();
      return;
    }

    isConnecting = true;
    isConnected = false;
    remoteError = null;
    notifyListeners();

    final ftp = FtpClient(host: targetIp, user: _ftpUser, pass: _ftpPass);
    try {
      await ftp.connect();

      if (remotePath != '/') {
        try {
          await ftp.changeDirectory(remotePath);
        } catch (_) {
          throw Exception("dir_error:$remotePath");
        }
      }

      final entries = await ftp.listDirectory();
      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      isConnected = true;
      remoteError = null;
      remoteFiles = entries;
      selectedRemoteFile = null;
    } catch (e) {
      final msg = e.toString();
      isConnected = false;
      if (msg.contains("dir_error")) {
        remoteError = "dir_error";
      } else if (msg.contains('Expected 230') || msg.contains('Expected 331')) {
        // Login ditolak oleh STB — credentials salah
        remoteError = "auth_error";
        remoteErrorDetail =
            'Login FTP ditolak oleh STB.\n'
            'Periksa User & Password FTP di Pengaturan.';
      } else {
        remoteError = "offline";
      }
      if (remoteError != "auth_error") {
        remoteErrorDetail = e.toString();
      }
      debugPrint('FTP ERROR: $e');
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
      isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> loadRemoteDirectory(String path) async {
    isLoadingRemote = true;
    notifyListeners();

    final ftp = FtpClient(host: targetIp, user: _ftpUser, pass: _ftpPass);
    try {
      await ftp.connect();

      if (path != '/') {
        try {
          await ftp.changeDirectory(path);
        } catch (_) {
          throw Exception("dir_error:$path");
        }
      }

      final entries = await ftp.listDirectory();
      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      remotePath = path;
      remoteFiles = entries;
      remoteError = null;
      selectedRemoteFile = null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("dir_error")) {
        remoteError = "dir_error";
        notifyWarning("Folder tidak dapat diakses. Flashdisk mungkin rusak atau tidak terpasang.");
      } else {
        notifyError("Gagal memuat direktori. Pastikan STB $targetIp aktif.");
      }
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
      isLoadingRemote = false;
      notifyListeners();
    }
  }

  void selectRemoteFile(FtpEntry entry) {
    selectedRemoteFile = entry;
    notifyListeners();
  }

  /// Navigasi ke parent directory (remote).
  void navigateRemoteUp() {
    final parts = remotePath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      parts.removeLast();
      loadRemoteDirectory("/${parts.join('/')}");
    }
  }

  /// Navigasi ke subfolder (remote).
  void navigateRemoteInto(FtpEntry entry) {
    if (!entry.isDirectory) return;
    final newPath = remotePath.endsWith('/')
        ? "$remotePath${entry.name}"
        : "$remotePath/${entry.name}";
    loadRemoteDirectory(newPath);
  }

  // ── TRANSFER ───────────────────────────────────────────────────

  /// Validasi dan mulai upload. Return false jika tidak valid.
  bool startUpload() {
    if (selectedLocalFile == null) {
      notifyWarning("Pilih file di panel kiri terlebih dahulu.");
      return false;
    }
    ftpService
        .sendPromoFile(
          targetIp,
          remotePath,
          selectedLocalFile!,
          storeCode: storeCode,
        )
        .then((_) => loadRemoteDirectory(remotePath));
    return true;
  }

  /// Validasi dan mulai download. Return false jika tidak valid.
  bool startDownload() {
    if (selectedRemoteFile == null) {
      notifyWarning("Pilih file di panel kanan terlebih dahulu.");
      return false;
    }
    if (selectedRemoteFile!.isDirectory) {
      notifyWarning("Tidak dapat mengunduh folder.");
      return false;
    }
    ftpService
        .downloadFile(
          targetIp,
          remotePath,
          selectedRemoteFile!.name,
          localPath,
          storeCode: storeCode,
        )
        .then((_) => loadLocalDirectory(localPath));
    return true;
  }

  // ── DELETE REMOTE ──────────────────────────────────────────────

  /// Validasi sebelum delete remote.
  /// Return null jika tidak valid, return nama file jika valid.
  String? validateDeleteRemote() {
    if (selectedRemoteFile == null) {
      notifyWarning("Pilih file di panel kanan terlebih dahulu.");
      return null;
    }
    if (selectedRemoteFile!.isDirectory) {
      notifyWarning("Tidak dapat menghapus folder.");
      return null;
    }
    return selectedRemoteFile!.name;
  }

  /// Eksekusi delete remote (panggil setelah dialog confirm).
  Future<void> executeDeleteRemote() async {
    if (selectedRemoteFile == null) return;

    isDeletingRemote = true;
    notifyListeners();

    final success = await ftpService.deleteRemoteFile(
      targetIp,
      remotePath,
      selectedRemoteFile!.name,
    );

    isDeletingRemote = false;
    notifyListeners();

    if (success) {
      notifyWarning("${selectedRemoteFile!.name} berhasil dihapus dari STB.");
      loadRemoteDirectory(remotePath);
    } else {
      notifyError("Gagal menghapus file dari STB.");
    }
  }

  // ── HELPERS ────────────────────────────────────────────────────

  /// Nama bulan pendek — dipindah dari page.
  static String monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  /// Cek apakah bisa navigate ke parent (local).
  bool get canNavigateLocalUp {
    return Directory(localPath).parent.path != localPath;
  }

  /// Navigate ke parent directory (local).
  void navigateLocalUp() {
    loadLocalDirectory(Directory(localPath).parent.path);
  }

  /// Dapatkan drive letter dari localPath saat ini.
  String get currentDrive {
    if (localPath.length >= 3) {
      final drive = localPath.substring(0, 3);
      if (availableDrives.contains(drive)) return drive;
    }
    return availableDrives.isNotEmpty ? availableDrives.first : "C:\\";
  }
}
