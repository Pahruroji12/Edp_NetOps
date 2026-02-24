import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/custom_snackbar.dart';
import '../auth/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../store_management/store_list_page.dart';
import '../../utils/app_colors.dart';
import '../profile/profile_page.dart';
import '../../utils/activity_logger.dart';
import '../profile/admin_panel_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _animationsReady = false;

  bool get _isAdministrator => currentUserRole.toLowerCase() == 'administrator';

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  // bool _obsOld = true;
  // bool _obsNew = true;

  final _konUserCtrl = TextEditingController();
  final _konPassCtrl = TextEditingController();
  final _wdcpUserCtrl = TextEditingController();
  final _wdcpPassCtrl = TextEditingController();
  final _apiPortCtrl = TextEditingController();
  final _winboxPortCtrl = TextEditingController();
  bool _obsKon = true;
  bool _obsWdcp = true;
  bool _obsVnc = true;
  bool _obsManageUserPass = true;

  final _vncPassCtrl = TextEditingController();

  final _nikUserCtrl = TextEditingController();
  final _namaUserCtrl = TextEditingController();
  final _passUserCtrl = TextEditingController();
  String _selectedRole = 'user';
  final List<String> _roles = ['administrator', 'admin', 'user'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    if (_isAdministrator) _loadRouterSettings();
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _konUserCtrl.dispose();
    _konPassCtrl.dispose();
    _wdcpUserCtrl.dispose();
    _wdcpPassCtrl.dispose();
    _apiPortCtrl.dispose();
    _winboxPortCtrl.dispose();
    _nikUserCtrl.dispose();
    _namaUserCtrl.dispose();
    _passUserCtrl.dispose();
    _vncPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRouterSettings() async {
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();
      final data = {for (var item in response) item['key']: item['value']};
      setState(() {
        _apiPortCtrl.text = data['api_port'] ?? '8728';
        _winboxPortCtrl.text = data['winbox_port'] ?? '8291';
        _konUserCtrl.text = data['koneksi_user'] ?? '';
        _konPassCtrl.text = data['koneksi_pass'] ?? '';
        _wdcpUserCtrl.text = data['wdcp_user'] ?? '';
        _wdcpPassCtrl.text = data['wdcp_pass'] ?? '';
        _vncPassCtrl.text = data['vnc_pass'] ?? '';
      });
    } catch (e) {
      debugPrint("Gagal load setting: $e");
    }
  }

  Future<void> _savePartialRouter(
    List<Map<String, dynamic>> data,
    String msg,
  ) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('app_settings').upsert(data);
      if (mounted) CustomSnackBar.show(context, msg, Colors.green);
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, "Gagal simpan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveManageUser() async {
    // Pastikan semua kolom diisi, karena Supabase Auth butuh password
    if (_nikUserCtrl.text.isEmpty ||
        _namaUserCtrl.text.isEmpty ||
        _passUserCtrl.text.isEmpty) {
      CustomSnackBar.show(
        context,
        "NIK, Nama, dan Password wajib diisi!",
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Bersihkan semua spasi yang mungkin nyelip di tengah NIK
      final String cleanNik = _nikUserCtrl.text.trim().replaceAll(' ', '');

      // Gunakan .com agar 100% lolos validasi keamanan Supabase
      final String fakeEmail = '$cleanNik@edp.com';

      // 1. Daftarkan akun baru ke sistem kunci utama (Supabase Auth)
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: fakeEmail,
        password: _passUserCtrl.text.trim(),
      );

      // 2. Jika berhasil terdaftar di Auth, simpan detailnya ke tabel profiles
      if (res.user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': res.user!.id, //
          'nik': _nikUserCtrl.text.trim(),
          'nama': _namaUserCtrl.text.trim(),
          'role': _selectedRole,
        });

        await ActivityLogger.logAction(
          actionType: "TAMBAH_USER",
          description:
              "Menambahkan akun baru: ${_namaUserCtrl.text.trim()} ($_selectedRole)",
        );

        if (mounted) {
          CustomSnackBar.show(
            context,
            "Akun ${_nikUserCtrl.text} berhasil ditambahkan!",
            Colors.green,
          );
          // Bersihkan form setelah sukses
          _nikUserCtrl.clear();
          _namaUserCtrl.clear();
          _passUserCtrl.clear();
          setState(() => _selectedRole = 'user');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Gagal daftar akun: ${e.message}",
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, "Gagal simpan profil: $e", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========================================== //
  // LOGOUT FUNCTION //
  // ========================================== //
  Future<void> _logout(BuildContext context) async {
    try {
      // 1. Matikan lampu status jadi Offline
      await ActivityLogger.updateOnlineStatus(false);

      // 2. Catat log bahwa user ini keluar dari aplikasi
      await ActivityLogger.logAction(
        actionType: "LOGOUT",
        description: "Pengguna keluar dari sistem",
      );

      // 3. Hapus token sesi dengan aman menggunakan Supabase Auth
      await Supabase.instance.client.auth.signOut();

      // 4. Bersihkan memori variabel global
      currentUserNik = '';
      currentUserName = '';
      currentUserRole = '';

      // 5. Arahkan kembali ke halaman Login secara total (menghapus riwayat 'back')
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context, "Gagal logout: $e", Colors.red);
      }
    }
  }

  Widget _responsiveRow({
    required List<Widget> children,
    double threshold = 500,
    double spacing = 14,
  }) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= threshold;
        if (isWide) {
          final items = <Widget>[];
          for (int i = 0; i < children.length; i++) {
            items.add(children[i]);
            if (i < children.length - 1) items.add(SizedBox(width: spacing));
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          );
        } else {
          final items = <Widget>[];
          for (int i = 0; i < children.length; i++) {
            Widget child = children[i];
            if (child is Expanded) child = child.child;
            if (child is Flexible) child = child.child;
            items.add(SizedBox(width: double.infinity, child: child));
            if (i < children.length - 1) items.add(SizedBox(height: spacing));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingOverlay()
          : AnimatedOpacity(
              opacity: _animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _animationsReady ? Offset.zero : const Offset(0, 0.04),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            if (_isAdministrator) ...[
                              _buildSectionHeader(
                                "MANAJEMEN PENGGUNA",
                                Icons.people_outline,
                              ),
                              const SizedBox(height: 12),
                              _buildUserManagementCard(),
                              const SizedBox(height: 24),

                              _buildSectionHeader(
                                "KONFIGURASI SISTEM",
                                Icons.router_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildRouterCard(),
                            ] else ...[
                              // TAMPILAN JIKA BUKAN ADMINISTRATOR
                              _buildRestrictedAccessWidget(),
                            ],

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // WIDGET AKSES TERBATAS UNTUK NON-ADMIN
  // ==========================================
  Widget _buildRestrictedAccessWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gpp_bad_outlined,
              size: 64,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Akses Dibatasi",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Halaman pengaturan sistem dan manajemen pengguna\nhanya dapat diakses oleh akun dengan level Administrator.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET LAINNYA
  // ==========================================
  Widget _buildLoadingOverlay() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Memproses...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    // Warna & icon sesuai role
    Color roleAccent;
    IconData roleIcon;
    switch (currentUserRole.toLowerCase()) {
      case 'administrator':
        roleAccent = const Color(0xFFFF6B6B);
        roleIcon = Icons.admin_panel_settings_outlined;
        break;
      case 'admin':
        roleAccent = const Color(0xFFFFB347);
        roleIcon = Icons.manage_accounts_outlined;
        break;
      default:
        roleAccent = context.accentColor;
        roleIcon = Icons.person_outline;
    }

    // Inisial avatar
    final nameParts = currentUserName.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'U';

    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),

      // ── Title collapsed ─────────────────────────────────
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "PENGATURAN SISTEM",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),

      // ── Hero expanded ────────────────────────────────────
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                roleAccent.withOpacity(0.10),
                context.primaryColor,
                context.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 12),
              child: Row(
                children: [
                  // Avatar kotak
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [roleAccent, roleAccent.withOpacity(0.55)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: roleAccent.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      // Role icon badge
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: roleAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Icon(roleIcon, size: 12, color: roleAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Info teks + status — responsif
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final isWide = constraints.maxWidth >= 260;

                        // Widget NIK
                        final nikRow = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 11,
                              color: context.textSecondary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentUserNik,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        );

                        // Widget role badge
                        final roleBadge = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roleAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: roleAccent.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 9, color: roleAccent),
                              const SizedBox(width: 4),
                              Text(
                                currentUserRole.toUpperCase(),
                                style: TextStyle(
                                  color: roleAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        );

                        // Widget status online
                        final statusPill = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00E676).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E676,
                                      ).withOpacity(0.7),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Nama + status pill (lebar: sejajar, sempit: nama saja)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentUserName.isNotEmpty
                                        ? currentUserName
                                        : 'User',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (isWide) ...[
                                  const SizedBox(width: 10),
                                  statusPill,
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            // NIK
                            nikRow,
                            const SizedBox(height: 6),
                            // Role badge + status pill (sempit: status di sini)
                            Row(
                              children: [
                                roleBadge,
                                if (!isWide) ...[
                                  const SizedBox(width: 8),
                                  statusPill,
                                ],
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouterCard() {
    return _buildCard(
      accentLeft: const Color(0xFF00C9A7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Konfigurasi Router & VNC",
            "Kelola koneksi, port jaringan, dan password VNC sistem.",
            Icons.router_outlined,
            const Color(0xFF00C9A7),
          ),
          const SizedBox(height: 20),
          _responsiveRow(
            threshold: 520,
            children: [
              Expanded(
                child: _buildRouterSubCard(
                  title: "RB KONEKSI",
                  icon: Icons.cable_outlined,
                  accentColor: context.accentColor,
                  child: Column(
                    children: [
                      _buildModernTextField(
                        "User RB Koneksi",
                        _konUserCtrl,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                      _buildModernTextField(
                        "Password RB Koneksi",
                        _konPassCtrl,
                        prefixIcon: Icons.key_outlined,
                        isPass: true,
                        isObs: _obsKon,
                        onObsToggle: () => setState(() => _obsKon = !_obsKon),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildSmallButton(
                          label: "Simpan",
                          color: context.accentColor,
                          onPressed: () => _savePartialRouter([
                            {'key': 'koneksi_user', 'value': _konUserCtrl.text},
                            {'key': 'koneksi_pass', 'value': _konPassCtrl.text},
                          ], "Router Koneksi Disimpan!"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildRouterSubCard(
                  title: "RB WDCP",
                  icon: Icons.hub_outlined,
                  accentColor: const Color(0xFFFFB347),
                  child: Column(
                    children: [
                      _buildModernTextField(
                        "User RB WDCP",
                        _wdcpUserCtrl,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                      _buildModernTextField(
                        "Password RB WDCP",
                        _wdcpPassCtrl,
                        prefixIcon: Icons.key_outlined,
                        isPass: true,
                        isObs: _obsWdcp,
                        onObsToggle: () => setState(() => _obsWdcp = !_obsWdcp),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildSmallButton(
                          label: "Simpan",
                          color: const Color(0xFFFFB347),
                          onPressed: () => _savePartialRouter([
                            {'key': 'wdcp_user', 'value': _wdcpUserCtrl.text},
                            {'key': 'wdcp_pass', 'value': _wdcpPassCtrl.text},
                          ], "Router WDCP Disimpan!"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _responsiveRow(
            threshold: 520,
            children: [
              Expanded(
                child: _buildRouterSubCard(
                  title: "PORT GLOBAL",
                  icon: Icons.settings_ethernet_outlined,
                  accentColor: const Color(0xFF00C9A7),
                  child: Column(
                    children: [
                      _buildModernTextField(
                        "Port API",
                        _apiPortCtrl,
                        prefixIcon: Icons.api_outlined,
                        isNum: true,
                      ),
                      const SizedBox(height: 10),
                      _buildModernTextField(
                        "Port Winbox",
                        _winboxPortCtrl,
                        prefixIcon: Icons.desktop_windows_outlined,
                        isNum: true,
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildSmallButton(
                          label: "Simpan Port",
                          color: const Color(0xFF00C9A7),
                          icon: Icons.save_outlined,
                          onPressed: () => _savePartialRouter([
                            {'key': 'api_port', 'value': _apiPortCtrl.text},
                            {
                              'key': 'winbox_port',
                              'value': _winboxPortCtrl.text,
                            },
                          ], "Port Global Disimpan!"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildRouterSubCard(
                  title: "PASSWORD VNC",
                  icon: Icons.desktop_windows_outlined,
                  accentColor: const Color(0xFF6C63FF),
                  child: Column(
                    children: [
                      _buildModernTextField(
                        "Password VNC",
                        _vncPassCtrl,
                        prefixIcon: Icons.desktop_access_disabled_outlined,
                        isPass: true,
                        isObs: _obsVnc,
                        onObsToggle: () => setState(() => _obsVnc = !_obsVnc),
                      ),
                      const SizedBox(height: 60), // Spacer penyama tinggi
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildSmallButton(
                          label: "Simpan VNC",
                          color: const Color(0xFF6C63FF),
                          icon: Icons.save_outlined,
                          onPressed: () => _savePartialRouter([
                            {'key': 'vnc_pass', 'value': _vncPassCtrl.text},
                          ], "Password VNC Disimpan!"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouterSubCard({
    required String title,
    required Color accentColor,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon box jika ada, fallback ke garis vertikal
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 13, color: accentColor),
                )
              else
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildUserManagementCard() {
    return _buildCard(
      accentLeft: context.secondaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Manajemen Pengguna",
            "Tambah akun baru atau perbarui data pengguna terdaftar.",
            Icons.people_outline,
            context.secondaryAccent,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                _responsiveRow(
                  threshold: 500,
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        "NIK Karyawan",
                        _nikUserCtrl,
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildModernTextField(
                        "Nama Lengkap",
                        _namaUserCtrl,
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _responsiveRow(
                  threshold: 500,
                  children: [
                    Expanded(child: _buildModernDropdown()),
                    Expanded(
                      child: _buildModernTextField(
                        "Set Password Baru",
                        _passUserCtrl,
                        prefixIcon: Icons.lock_outline,
                        isPass: true,
                        isObs: _obsManageUserPass,
                        onObsToggle: () => setState(
                          () => _obsManageUserPass = !_obsManageUserPass,
                        ),
                        helperText: "Kosongkan jika hanya ubah Role/Nama",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: _buildPrimaryButton(
              label: "Simpan Data Pengguna",
              icon: Icons.person_add_outlined,
              onPressed: _saveManageUser,
              color: context.secondaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      dropdownColor: context.cardColor,
      style: TextStyle(color: context.textPrimary, fontSize: 13),
      icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary),
      decoration: InputDecoration(
        labelText: "Role Akses",
        labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
        prefixIcon: Icon(
          Icons.admin_panel_settings_outlined,
          color: context.textSecondary,
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: context.cardColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      items: _roles
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedRole = v!),
    );
  }

  Widget _buildCard({required Widget child, Color? accentLeft}) {
    return Stack(
      children: [
        // Card utama
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: accentLeft != null ? 28 : 24,
            right: 24,
            top: 24,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        // Garis aksen kiri via Positioned — tidak konflik dengan layout
        if (accentLeft != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentLeft, accentLeft.withOpacity(0.25)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? context.accentColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [buttonColor, buttonColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PENAMBAHAN BUNGKUSAN THEME AGAR WARNA BLOK SELECTION TEXT TERLIHAT JELAS
  Widget _buildModernTextField(
    String label,
    TextEditingController ctrl, {
    IconData? prefixIcon,
    bool isPass = false,
    bool isObs = false,
    VoidCallback? onObsToggle,
    bool isNum = false,
    String? helperText,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: context.accentColor,
          selectionColor: context.accentColor.withOpacity(0.3),
          selectionHandleColor: context.accentColor,
        ),
      ),
      child: TextFormField(
        controller: ctrl,
        obscureText: isPass ? isObs : false,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        cursorColor: context.accentColor,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: TextStyle(
            color: context.textSecondary.withOpacity(0.7),
            fontSize: 10,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: context.textSecondary, size: 18)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.accentColor, width: 1.5),
          ),
          filled: true,
          fillColor: context.cardColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          suffixIcon: isPass && onObsToggle != null
              ? IconButton(
                  icon: Icon(
                    isObs
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  onPressed: onObsToggle,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    // Warna & icon sesuai role
    Color roleAccentD;
    IconData roleIconD;
    switch (currentUserRole.toLowerCase()) {
      case 'administrator':
        roleAccentD = const Color(0xFFFF6B6B);
        roleIconD = Icons.admin_panel_settings_outlined;
        break;
      case 'admin':
        roleAccentD = const Color(0xFFFFB347);
        roleIconD = Icons.manage_accounts_outlined;
        break;
      default:
        roleAccentD = context.accentColor;
        roleIconD = Icons.person_outline;
    }

    // Inisial 2 huruf
    final nameParts = currentUserName.trim().split(' ');
    final initialsD = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'U';

    return Drawer(
      backgroundColor: context.surfaceColor,
      child: Column(
        children: [
          // ── HEADER DRAWER ─────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleAccentD.withOpacity(0.13), context.cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + status online
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar kotak inisial 2 huruf
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roleAccentD,
                                    roleAccentD.withOpacity(0.55),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: roleAccentD.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initialsD,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            // Role icon badge sudut kanan bawah
                            Positioned(
                              right: -5,
                              bottom: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: roleAccentD.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  roleIconD,
                                  size: 12,
                                  color: roleAccentD,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Status pill online
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00E676).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E676,
                                      ).withOpacity(0.7),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Nama
                    Text(
                      currentUserName.isNotEmpty ? currentUserName : 'User',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 5),

                    // NIK monospace
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          currentUserNik,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleAccentD.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: roleAccentD.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIconD, size: 11, color: roleAccentD),
                          const SizedBox(width: 6),
                          Text(
                            currentUserRole.toUpperCase(),
                            style: TextStyle(
                              color: roleAccentD,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const DashboardPage()),
              );
            },
          ),
          _buildDrawerTile(
            icon: Icons.store_outlined,
            label: 'Data Toko',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const StoreListPage()),
              );
            },
          ),
          _buildDrawerTile(
            icon: Icons.person_outline,
            label: 'Profil Saya',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const ProfilePage()),
              );
            },
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Icon(
                Icons.settings_outlined,
                color: context.accentColor,
                size: 20,
              ),
              title: Text(
                'Setting',
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),

          if (currentUserRole.toLowerCase() == 'administrator') ...[
            // Menu Setting hanya akan dirender/digambar jika rolenya administrator
            _buildDrawerTile(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Control Center',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => const AdminPanelPage()),
                );
              },
            ),
          ],

          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 1,
            color: context.borderColor,
          ),
          const SizedBox(height: 8),
          _buildDrawerTile(
            icon: Icons.logout_outlined,
            label: 'Keluar Aplikasi',
            iconColor: const Color(0xFFFF6B6B),
            labelColor: const Color(0xFFFF6B6B),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: iconColor ?? context.textSecondary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1520),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_outlined,
                        color: Color(0xFFFF6B6B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Keluar Aplikasi?",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Apakah Anda yakin ingin keluar dari aplikasi EDP NetOps?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _logout(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Ya, Keluar",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
