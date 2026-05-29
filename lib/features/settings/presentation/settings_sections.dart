import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

/// RouterConfigSection — section Konfigurasi Router & VNC.
///
/// Lokasi: features/settings/presentation/settings_sections.dart
///
/// Extracted dari _buildRouterCard() di settings_page.dart.
/// Hanya render UI, semua logic ada di SettingsController.

// ══════════════════════════════════════════════════════════════
// ROUTER & VNC CONFIG SECTION
// ══════════════════════════════════════════════════════════════

class RouterConfigSection extends StatelessWidget {
  final SettingsController ctrl;

  const RouterConfigSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      accentLeft: const Color(0xFF00C9A7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsCardHeader(
            title: "Konfigurasi Router & VNC",
            subtitle: "Kelola koneksi, port jaringan, dan password VNC sistem.",
            icon: Icons.router_outlined,
            color: Color(0xFF00C9A7),
          ),
          const SizedBox(height: 20),

          // ── Row 1: RB Koneksi + RB WDCP ──
          SettingsResponsiveRow(
            threshold: 520,
            children: [
              Expanded(child: _buildKoneksiSubCard(context)),
              Expanded(child: _buildWdcpSubCard(context)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Row 2: Port Global + VNC ──
          SettingsResponsiveRow(
            threshold: 520,
            children: [
              Expanded(child: _buildPortSubCard(context)),
              Expanded(child: _buildVncSubCard(context)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Row 3: FTP STB ──
          SettingsResponsiveRow(
            threshold: 520,
            children: [
              Expanded(child: _buildFtpSubCard(context)),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKoneksiSubCard(BuildContext context) {
    return SettingsSubCard(
      title: "RB KONEKSI",
      icon: Icons.cable_outlined,
      accentColor: context.accentColor,
      child: Column(
        children: [
          SettingsTextField(
            "User RB Koneksi",
            ctrl.konUserCtrl,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "Password RB Koneksi",
            ctrl.konPassCtrl,
            prefixIcon: Icons.key_outlined,
            isPass: true,
            isObs: ctrl.obsKon,
            onObsToggle: ctrl.toggleObsKon,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan",
              color: context.accentColor,
              onPressed: ctrl.saveKoneksi,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWdcpSubCard(BuildContext context) {
    return SettingsSubCard(
      title: "RB WDCP",
      icon: Icons.hub_outlined,
      accentColor: const Color(0xFFFFB347),
      child: Column(
        children: [
          SettingsTextField(
            "User RB WDCP",
            ctrl.wdcpUserCtrl,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "Password RB WDCP",
            ctrl.wdcpPassCtrl,
            prefixIcon: Icons.key_outlined,
            isPass: true,
            isObs: ctrl.obsWdcp,
            onObsToggle: ctrl.toggleObsWdcp,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan",
              color: const Color(0xFFFFB347),
              onPressed: ctrl.saveWdcp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortSubCard(BuildContext context) {
    return SettingsSubCard(
      title: "PORT GLOBAL",
      icon: Icons.settings_ethernet_outlined,
      accentColor: const Color(0xFF00C9A7),
      child: Column(
        children: [
          SettingsTextField(
            "Port API",
            ctrl.apiPortCtrl,
            prefixIcon: Icons.api_outlined,
            isNum: true,
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "Port Winbox",
            ctrl.winboxPortCtrl,
            prefixIcon: Icons.desktop_windows_outlined,
            isNum: true,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan Port",
              color: const Color(0xFF00C9A7),
              icon: Icons.save_outlined,
              onPressed: ctrl.savePorts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVncSubCard(BuildContext context) {
    return SettingsSubCard(
      title: "PASSWORD VNC TOKO",
      icon: Icons.desktop_windows_outlined,
      accentColor: const Color(0xFF6C63FF),
      child: Column(
        children: [
          SettingsTextField(
            "Password VNC Toko",
            ctrl.vncPassCtrl,
            prefixIcon: Icons.desktop_access_disabled_outlined,
            isPass: true,
            isObs: ctrl.obsVnc,
            onObsToggle: ctrl.toggleObsVnc,
            helperText: "Password VNC untuk akses perangkat toko",
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "Password VNC Office",
            ctrl.vncOfficeCtrl,
            prefixIcon: Icons.monitor_outlined,
            isPass: true,
            isObs: ctrl.obsVncOffice,
            onObsToggle: ctrl.toggleObsVncOffice,
            helperText: "Password VNC untuk akses perangkat kantor",
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan VNC",
              color: const Color(0xFF6C63FF),
              icon: Icons.save_outlined,
              onPressed: ctrl.saveVnc,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFtpSubCard(BuildContext context) {
    const ftpColor = Color(0xFFFFB347);
    return SettingsSubCard(
      title: "FTP STB",
      icon: Icons.tv_outlined,
      accentColor: ftpColor,
      child: Column(
        children: [
          SettingsTextField(
            "User FTP STB",
            ctrl.ftpUserCtrl,
            prefixIcon: Icons.person_outline,
            helperText: "Username FTP untuk akses STB Android",
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "Password FTP STB",
            ctrl.ftpPassCtrl,
            prefixIcon: Icons.key_outlined,
            isPass: true,
            isObs: ctrl.obsFtp,
            onObsToggle: ctrl.toggleObsFtp,
            helperText: "Password FTP untuk akses STB Android",
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan FTP",
              color: ftpColor,
              icon: Icons.save_outlined,
              onPressed: ctrl.saveFtp,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SMTP CONFIG SECTION
// ══════════════════════════════════════════════════════════════

class SmtpConfigSection extends StatelessWidget {
  final SettingsController ctrl;

  const SmtpConfigSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const smtpColor = Color(0xFF2196F3);
    return SettingsCard(
      accentLeft: smtpColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsCardHeader(
            title: "Konfigurasi SMTP",
            subtitle: "Pengaturan server email untuk pengiriman tiket otomatis.",
            icon: Icons.email_outlined,
            color: smtpColor,
          ),
          const SizedBox(height: 20),

          // ── Row 1: Server + Account ──
          SettingsResponsiveRow(
            threshold: 520,
            children: [
              Expanded(child: _buildServerSubCard(context)),
              Expanded(child: _buildAccountSubCard(context)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Row 2: Sender Name ──
          _buildSenderNameSubCard(context),
        ],
      ),
    );
  }

  Widget _buildServerSubCard(BuildContext context) {
    const smtpColor = Color(0xFF2196F3);
    return SettingsSubCard(
      title: "SERVER EMAIL",
      icon: Icons.dns_outlined,
      accentColor: smtpColor,
      child: Column(
        children: [
          SettingsTextField(
            "SMTP Host",
            ctrl.smtpHostCtrl,
            prefixIcon: Icons.cloud_outlined,
            helperText: "Contoh: smtp.gmail.com",
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "SMTP Port",
            ctrl.smtpPortCtrl,
            prefixIcon: Icons.settings_ethernet_outlined,
            isNum: true,
            helperText: "587 (TLS) atau 465 (SSL)",
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan",
              color: smtpColor,
              icon: Icons.save_outlined,
              onPressed: ctrl.saveSmtpServer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSubCard(BuildContext context) {
    return SettingsSubCard(
      title: "AKUN EMAIL",
      icon: Icons.manage_accounts_outlined,
      accentColor: const Color(0xFF42A5F5),
      child: Column(
        children: [
          SettingsTextField(
            "Email Pengirim",
            ctrl.smtpUserCtrl,
            prefixIcon: Icons.alternate_email_outlined,
            helperText: "Alamat email yang digunakan untuk kirim",
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "App Password",
            ctrl.smtpPassCtrl,
            prefixIcon: Icons.key_outlined,
            isPass: true,
            isObs: ctrl.obsSmtp,
            onObsToggle: ctrl.toggleObsSmtp,
            helperText: "Gunakan App Password, bukan password akun",
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan",
              color: const Color(0xFF42A5F5),
              icon: Icons.save_outlined,
              onPressed: ctrl.saveSmtpAccount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderNameSubCard(BuildContext context) {
    return SettingsSubCard(
      title: "NAMA PENGIRIM",
      icon: Icons.badge_outlined,
      accentColor: const Color(0xFF1565C0),
      child: SettingsResponsiveRow(
        threshold: 520,
        children: [
          Expanded(
            child: SettingsTextField(
              "Nama Pengirim",
              ctrl.smtpNameCtrl,
              prefixIcon: Icons.drive_file_rename_outline_outlined,
              helperText:
                  "Nama yang muncul di email penerima. Contoh: EDP NetOps",
            ),
          ),
          const SizedBox(width: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan Nama",
              color: const Color(0xFF1565C0),
              icon: Icons.save_outlined,
              onPressed: ctrl.saveSmtpName,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// IMAP CONFIG SECTION
// ══════════════════════════════════════════════════════════════

class ImapConfigSection extends StatelessWidget {
  final SettingsController ctrl;

  const ImapConfigSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const imapColor = Color(0xFFFFB74D); // Warm orange
    return SettingsCard(
      accentLeft: imapColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsCardHeader(
            title: "Konfigurasi IMAP",
            subtitle: "Pengaturan inbox email untuk sinkronisasi otomatis nomor tiket dari balasan provider.",
            icon: Icons.mail_outline_rounded,
            color: imapColor,
          ),
          const SizedBox(height: 20),

          // ── Row 1: Server + Account ──
          SettingsResponsiveRow(
            threshold: 520,
            children: [
              Expanded(child: _buildServerSubCard(context)),
              Expanded(child: _buildAccountSubCard(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerSubCard(BuildContext context) {
    const imapColor = Color(0xFFFFB74D);
    return SettingsSubCard(
      title: "SERVER IMAP INCOMING",
      icon: Icons.dns_outlined,
      accentColor: imapColor,
      child: Column(
        children: [
          SettingsTextField(
            "IMAP Host",
            ctrl.imapHostCtrl,
            prefixIcon: Icons.cloud_outlined,
            helperText: "Contoh: imap.gmail.com",
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "IMAP Port",
            ctrl.imapPortCtrl,
            prefixIcon: Icons.settings_ethernet_outlined,
            isNum: true,
            helperText: "993 (SSL/TLS) atau 143 (Non-SSL)",
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan Server",
              color: imapColor,
              icon: Icons.save_outlined,
              onPressed: ctrl.saveImapServer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSubCard(BuildContext context) {
    const imapColor = Color(0xFFFFA726);
    return SettingsSubCard(
      title: "AKUN IMAP EMAIL",
      icon: Icons.manage_accounts_outlined,
      accentColor: imapColor,
      child: Column(
        children: [
          SettingsTextField(
            "Email Pengguna",
            ctrl.imapUserCtrl,
            prefixIcon: Icons.alternate_email_outlined,
            helperText: "Alamat email untuk sinkronisasi tiket",
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            "App Password / Sandi",
            ctrl.imapPassCtrl,
            prefixIcon: Icons.key_outlined,
            isPass: true,
            isObs: ctrl.obsImap,
            onObsToggle: ctrl.toggleObsImap,
            helperText: "Gunakan App Password untuk keamanan tinggi",
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SettingsSmallButton(
              label: "Simpan Akun",
              color: imapColor,
              icon: Icons.save_outlined,
              onPressed: ctrl.saveImapAccount,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// USER MANAGEMENT SECTION
// ══════════════════════════════════════════════════════════════

class UserManagementSection extends StatelessWidget {
  final SettingsController ctrl;

  const UserManagementSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      accentLeft: context.secondaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsCardHeader(
            title: "Manajemen Pengguna",
            subtitle: ctrl.isEditMode
                ? "Mode Edit — ubah nama atau role pengguna."
                : "Cari NIK untuk edit, atau isi semua kolom untuk tambah akun baru.",
            icon: Icons.people_outline,
            color:
                ctrl.isEditMode ? context.warningColor : context.secondaryAccent,
          ),
          const SizedBox(height: 20),

          // ── Mode indicator badge ──
          if (ctrl.isEditMode)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: context.warningColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "MODE EDIT — NIK: ${ctrl.nikUserCtrl.text}",
                    style: TextStyle(
                      color: context.warningColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          // ── Form area ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                // ── Baris 1: NIK + Cari ──
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SettingsTextField(
                          "NIK Karyawan",
                          ctrl.nikUserCtrl,
                          prefixIcon: Icons.badge_outlined,
                          readOnly: ctrl.isEditMode,
                          helperText: ctrl.isEditMode
                              ? null
                              : "Ketik NIK lalu tekan Cari untuk edit, atau langsung isi semua untuk tambah baru.",
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildSearchButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Baris 2: Nama + Role ──
                SettingsResponsiveRow(
                  threshold: 500,
                  children: [
                    Expanded(
                      child: SettingsTextField(
                        "Nama Lengkap",
                        ctrl.namaUserCtrl,
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    Expanded(
                      child: SettingsRoleDropdown(
                        selectedRole: ctrl.selectedRole,
                        roles: ctrl.roles,
                        onChanged: ctrl.setRole,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Baris 3: Password (hanya mode tambah) ──
                if (!ctrl.isEditMode)
                  SettingsTextField(
                    "Password",
                    ctrl.passUserCtrl,
                    prefixIcon: Icons.lock_outline,
                    isPass: true,
                    isObs: ctrl.obsManageUserPass,
                    onObsToggle: ctrl.toggleObsManageUserPass,
                    helperText: "Wajib diisi untuk akun baru.",
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Action buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (ctrl.isEditMode) ...[
                SettingsSmallButton(
                  label: "Batal",
                  color: context.textSecondary,
                  icon: Icons.close_rounded,
                  onPressed: ctrl.resetUserForm,
                ),
                const SizedBox(width: 10),
              ],
              SettingsPrimaryButton(
                label: ctrl.isEditMode ? "Simpan Perubahan" : "Tambah Akun Baru",
                icon: ctrl.isEditMode
                    ? Icons.save_outlined
                    : Icons.person_add_outlined,
                onPressed: ctrl.saveUser,
                color: ctrl.isEditMode
                    ? context.warningColor
                    : context.secondaryAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: ctrl.isSearchingUser ? null : ctrl.searchUser,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: ctrl.isSearchingUser
                ? context.accentColor.withOpacity(0.05)
                : context.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.accentColor.withOpacity(
                ctrl.isSearchingUser ? 0.15 : 0.3,
              ),
            ),
          ),
          child: Center(
            child: ctrl.isSearchingUser
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: context.accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: context.accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Cari",
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
