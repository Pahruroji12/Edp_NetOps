import 'package:flutter/material.dart';

import '../../../features/auth/domain/auth_state.dart';
import '../data/settings_repository.dart';
import '../../../core/utils/notification_mixin.dart';
import '../../../core/error/failures.dart';

/// SettingsController — semua state dan logic untuk SettingsPage.
///
/// Lokasi: features/settings/presentation/settings_controller.dart
///
/// Tanggung jawab:
///   - Kelola state loading/saving
///   - Load & save app settings (router, VNC, SMTP)
///   - User management (search, create, update)
///   - Validasi form input
///   - Notification state untuk Page
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung (gunakan notification state)
///   - Import widget selain ChangeNotifier
///
class SettingsController extends ChangeNotifier with NotificationMixin {
  final SettingsRepository _repo = SettingsRepository();

  // ── Role check ──────────────────────────────────────────────
  bool get isAdministrator =>
      AuthState.instance.role.toLowerCase() == 'administrator';

  // ── State: Global Loading ───────────────────────────────────
  bool isLoading = false;
  bool animationsReady = false;

  // ── State: Text Controllers ─────────────────────────────────
  // Router / Koneksi
  final konUserCtrl = TextEditingController();
  final konPassCtrl = TextEditingController();
  final wdcpUserCtrl = TextEditingController();
  final wdcpPassCtrl = TextEditingController();
  final apiPortCtrl = TextEditingController();
  final winboxPortCtrl = TextEditingController();

  // VNC
  final vncPassCtrl = TextEditingController();
  final vncOfficeCtrl = TextEditingController();

  // SMTP
  final smtpHostCtrl = TextEditingController();
  final smtpPortCtrl = TextEditingController();
  final smtpUserCtrl = TextEditingController();
  final smtpPassCtrl = TextEditingController();
  final smtpNameCtrl = TextEditingController();

  // IMAP
  final imapHostCtrl = TextEditingController();
  final imapPortCtrl = TextEditingController();
  final imapUserCtrl = TextEditingController();
  final imapPassCtrl = TextEditingController();

  // FTP STB
  final ftpUserCtrl = TextEditingController();
  final ftpPassCtrl = TextEditingController();

  // SLA Scraper
  final slaUserCtrl = TextEditingController();
  final slaPassCtrl = TextEditingController();

  // User Management
  final nikUserCtrl = TextEditingController();
  final namaUserCtrl = TextEditingController();
  final passUserCtrl = TextEditingController();

  // Telegram Configuration
  final telegramBotTokenCtrl = TextEditingController();
  final telegramChatIdCtrl = TextEditingController();

  // ── State: Password visibility toggles ──────────────────────
  bool obsKon = true;
  bool obsWdcp = true;
  bool obsVnc = true;
  bool obsVncOffice = true;
  bool obsSmtp = true;
  bool obsImap = true;
  bool obsFtp = true;
  bool obsManageUserPass = true;
  bool obsTelegramToken = true;
  bool obsSla = true;

  // ── State: User Management ──────────────────────────────────
  String selectedRole = 'user';
  final List<String> roles = const ['administrator', 'admin', 'user'];
  bool isEditMode = false;
  bool isSearchingUser = false;
  String? editProfileId;

  // ── State: Notification (via NotificationMixin) ─────────────

  // ── TOGGLE HELPERS ──────────────────────────────────────────

  void toggleObsKon() {
    obsKon = !obsKon;
    notifyListeners();
  }

  void toggleObsWdcp() {
    obsWdcp = !obsWdcp;
    notifyListeners();
  }

  void toggleObsVnc() {
    obsVnc = !obsVnc;
    notifyListeners();
  }

  void toggleObsVncOffice() {
    obsVncOffice = !obsVncOffice;
    notifyListeners();
  }

  void toggleObsSmtp() {
    obsSmtp = !obsSmtp;
    notifyListeners();
  }

  void toggleObsImap() {
    obsImap = !obsImap;
    notifyListeners();
  }

  void toggleObsFtp() {
    obsFtp = !obsFtp;
    notifyListeners();
  }

  void toggleObsManageUserPass() {
    obsManageUserPass = !obsManageUserPass;
    notifyListeners();
  }

  void toggleObsTelegramToken() {
    obsTelegramToken = !obsTelegramToken;
    notifyListeners();
  }

  void toggleObsSla() {
    obsSla = !obsSla;
    notifyListeners();
  }

  // ── INISIALISASI ────────────────────────────────────────────

  void init() {
    if (isAdministrator) loadSettings();
  }

  void markAnimationsReady() {
    animationsReady = true;
    notifyListeners();
  }

  // ── LOAD SETTINGS ───────────────────────────────────────────

  Future<void> loadSettings() async {
    final result = await _repo.fetchAppSettings();
    result.fold(
      (failure) => debugPrint('Gagal load setting: ${failure.message}'),
      (data) {
        apiPortCtrl.text = data['api_port'] ?? '8728';
        winboxPortCtrl.text = data['winbox_port'] ?? '8291';
        konUserCtrl.text = data['koneksi_user'] ?? '';
        konPassCtrl.text = data['koneksi_pass'] ?? '';
        wdcpUserCtrl.text = data['wdcp_user'] ?? '';
        wdcpPassCtrl.text = data['wdcp_pass'] ?? '';
        vncPassCtrl.text = data['vnc_pass'] ?? '';
        vncOfficeCtrl.text = data['vnc_office'] ?? '';
        smtpHostCtrl.text = data['smtp_host'] ?? 'smtp.gmail.com';
        smtpPortCtrl.text = data['smtp_port'] ?? '587';
        smtpUserCtrl.text = data['smtp_user'] ?? '';
        smtpPassCtrl.text = data['smtp_pass'] ?? '';
        smtpNameCtrl.text = data['smtp_name'] ?? 'EDP NetOps';
        imapHostCtrl.text = data['imap_host'] ?? 'imap.gmail.com';
        imapPortCtrl.text = data['imap_port'] ?? '993';
        imapUserCtrl.text = data['imap_user'] ?? '';
        imapPassCtrl.text = data['imap_pass'] ?? '';
        ftpUserCtrl.text = data['ftp_user'] ?? '';
        ftpPassCtrl.text = data['ftp_pass'] ?? '';
        telegramBotTokenCtrl.text = data['telegram_bot_token'] ?? '';
        telegramChatIdCtrl.text = data['telegram_chat_id'] ?? '';
        slaUserCtrl.text = data['sla_username'] ?? '';
        slaPassCtrl.text = data['sla_password'] ?? '';
        notifyListeners();
      },
    );
  }

  // ── SAVE PARTIAL SETTINGS ───────────────────────────────────

  Future<void> savePartialSettings(
    List<Map<String, dynamic>> data,
    String successMessage,
  ) async {
    isLoading = true;
    notifyListeners();

    final result = await _repo.saveAppSettings(data);
    result.fold(
      (failure) => notifyError('Gagal simpan: ${failure.message}'),
      (_) => notifySuccess(successMessage),
    );

    isLoading = false;
    notifyListeners();
  }

  // ── Shortcut methods untuk setiap section ───────────────────

  void saveKoneksi() => savePartialSettings([
    {'key': 'koneksi_user', 'value': konUserCtrl.text},
    {'key': 'koneksi_pass', 'value': konPassCtrl.text},
  ], 'Router Koneksi Disimpan!');

  void saveWdcp() => savePartialSettings([
    {'key': 'wdcp_user', 'value': wdcpUserCtrl.text},
    {'key': 'wdcp_pass', 'value': wdcpPassCtrl.text},
  ], 'Router WDCP Disimpan!');

  void savePorts() => savePartialSettings([
    {'key': 'api_port', 'value': apiPortCtrl.text},
    {'key': 'winbox_port', 'value': winboxPortCtrl.text},
  ], 'Port Global Disimpan!');

  void saveVnc() => savePartialSettings([
    {'key': 'vnc_pass', 'value': vncPassCtrl.text},
    {'key': 'vnc_office', 'value': vncOfficeCtrl.text},
  ], 'Password VNC Disimpan!');

  void saveSmtpServer() => savePartialSettings([
    {'key': 'smtp_host', 'value': smtpHostCtrl.text},
    {'key': 'smtp_port', 'value': smtpPortCtrl.text},
  ], 'Konfigurasi Server SMTP Disimpan!');

  void saveSmtpAccount() => savePartialSettings([
    {'key': 'smtp_user', 'value': smtpUserCtrl.text},
    {'key': 'smtp_pass', 'value': smtpPassCtrl.text},
  ], 'Akun Email SMTP Disimpan!');

  void saveSmtpName() => savePartialSettings([
    {'key': 'smtp_name', 'value': smtpNameCtrl.text},
  ], 'Nama Pengirim Disimpan!');

  void saveImapServer() => savePartialSettings([
    {'key': 'imap_host', 'value': imapHostCtrl.text},
    {'key': 'imap_port', 'value': imapPortCtrl.text},
  ], 'Konfigurasi Server IMAP Disimpan!');

  void saveImapAccount() => savePartialSettings([
    {'key': 'imap_user', 'value': imapUserCtrl.text},
    {'key': 'imap_pass', 'value': imapPassCtrl.text},
  ], 'Akun Email IMAP Disimpan!');

  void saveFtp() => savePartialSettings([
    {'key': 'ftp_user', 'value': ftpUserCtrl.text},
    {'key': 'ftp_pass', 'value': ftpPassCtrl.text},
  ], 'Credential FTP STB Disimpan!');

  void saveTelegram() => savePartialSettings([
    {'key': 'telegram_bot_token', 'value': telegramBotTokenCtrl.text},
    {'key': 'telegram_chat_id', 'value': telegramChatIdCtrl.text},
  ], 'Konfigurasi Telegram Bot Disimpan!');

  void saveSla() => savePartialSettings([
    {'key': 'sla_username', 'value': slaUserCtrl.text},
    {'key': 'sla_password', 'value': slaPassCtrl.text},
  ], 'Kredensial Login SLA Disimpan!');

  // ── USER MANAGEMENT ─────────────────────────────────────────

  void resetUserForm() {
    isEditMode = false;
    editProfileId = null;
    nikUserCtrl.clear();
    namaUserCtrl.clear();
    passUserCtrl.clear();
    selectedRole = 'user';
    notifyListeners();
  }

  void setRole(String role) {
    selectedRole = role;
    notifyListeners();
  }

  Future<void> searchUser() async {
    final nik = nikUserCtrl.text.trim();
    if (nik.isEmpty) {
      notifyError('Masukkan NIK terlebih dahulu.');
      return;
    }

    isSearchingUser = true;
    notifyListeners();

    final result = await _repo.searchUserByNik(nik);
    result.fold(
      (failure) => notifyError('Gagal cari user: ${failure.message}'),
      (userMap) {
        if (userMap == null) {
          notifyWarning(
            'NIK $nik tidak ditemukan. Form siap untuk tambah akun baru.',
          );
          isEditMode = false;
          editProfileId = null;
          namaUserCtrl.clear();
          passUserCtrl.clear();
          selectedRole = 'user';
        } else {
          final rawRole = (userMap['role'] ?? 'user').toString().toLowerCase();
          isEditMode = true;
          editProfileId = userMap['id'] as String?;
          namaUserCtrl.text = userMap['nama'] ?? '';
          selectedRole = roles.contains(rawRole) ? rawRole : 'user';
          passUserCtrl.clear();
          notifyInfo('User ditemukan. Ubah data lalu simpan.');
        }
      },
    );

    isSearchingUser = false;
    notifyListeners();
  }

  Future<void> updateUser() async {
    if (namaUserCtrl.text.trim().isEmpty) {
      notifyError('Nama tidak boleh kosong.');
      return;
    }

    isLoading = true;
    notifyListeners();

    final result = await _repo.updateUser(
      profileId: editProfileId!,
      nik: nikUserCtrl.text.trim(),
      nama: namaUserCtrl.text.trim(),
      role: selectedRole,
    );

    result.fold((failure) => notifyError('Gagal update: ${failure.message}'), (
      _,
    ) {
      notifySuccess('Data pengguna berhasil diperbarui!');
      resetUserForm();
    });

    isLoading = false;
    notifyListeners();
  }

  Future<void> createUser() async {
    if (nikUserCtrl.text.isEmpty ||
        namaUserCtrl.text.isEmpty ||
        passUserCtrl.text.isEmpty) {
      notifyError('NIK, Nama, dan Password wajib diisi!');
      return;
    }

    isLoading = true;
    notifyListeners();

    final result = await _repo.createUser(
      nik: nikUserCtrl.text,
      nama: namaUserCtrl.text,
      password: passUserCtrl.text.trim(),
      role: selectedRole,
    );

    result.fold(
      (failure) {
        if (failure is AuthFailure) {
          notifyError('Gagal daftar akun: ${failure.message}');
        } else {
          notifyError('Gagal simpan profil: ${failure.message}');
        }
      },
      (_) {
        notifySuccess('Akun ${nikUserCtrl.text} berhasil ditambahkan!');
        resetUserForm();
      },
    );

    isLoading = false;
    notifyListeners();
  }

  /// Simpan user — dispatch ke create atau update berdasarkan mode.
  void saveUser() {
    if (isEditMode) {
      updateUser();
    } else {
      createUser();
    }
  }

  // ── DISPOSE ─────────────────────────────────────────────────

  @override
  void dispose() {
    konUserCtrl.dispose();
    konPassCtrl.dispose();
    wdcpUserCtrl.dispose();
    wdcpPassCtrl.dispose();
    apiPortCtrl.dispose();
    winboxPortCtrl.dispose();
    vncPassCtrl.dispose();
    vncOfficeCtrl.dispose();
    smtpHostCtrl.dispose();
    smtpPortCtrl.dispose();
    smtpUserCtrl.dispose();
    smtpPassCtrl.dispose();
    smtpNameCtrl.dispose();
    imapHostCtrl.dispose();
    imapPortCtrl.dispose();
    imapUserCtrl.dispose();
    imapPassCtrl.dispose();
    ftpUserCtrl.dispose();
    ftpPassCtrl.dispose();
    nikUserCtrl.dispose();
    namaUserCtrl.dispose();
    passUserCtrl.dispose();
    telegramBotTokenCtrl.dispose();
    telegramChatIdCtrl.dispose();
    super.dispose();
  }
}
