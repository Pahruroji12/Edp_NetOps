import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/store_model.dart';
import 'store_form_page.dart';
import 'package:dart_ping/dart_ping.dart';
import 'dart:io';
import 'wdcp_control_page.dart';
import '../auth/login_page.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/app_colors.dart';
import '../../utils/activity_logger.dart';
import '../../services/ftp_service.dart';
import 'ftp_page.dart';

class StoreDetailPage extends StatefulWidget {
  final StoreModel store;

  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late StoreModel _currentStore;
  bool _isLoading = false;
  bool _hasChanged = false;
  bool _animationsReady = false;

  String _pingStatus = "Mengecek koneksi...";
  Color _pingColor = const Color(0xFF7A9CC4);
  String _latency = "";

  bool get _isMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false; // Jika diakses via Web
    }
  }

  bool get _isAdminOrAbove =>
      currentUserRole.toLowerCase() == 'administrator' ||
      currentUserRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _currentStore = widget.store;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    if (!_isMobile) {
      if (_currentStore.ipGateway != null &&
          _currentStore.ipGateway!.isNotEmpty) {
        _performPing();
      } else {
        setState(() {
          _pingStatus = "IP Gateway Kosong";
          _pingColor = const Color(0xFFFFB347);
        });
      }
    }
  }

  Future<void> _performPing() async {
    final ip = _currentStore.ipGateway;
    if (ip == null || ip.isEmpty) return;
    setState(() {
      _pingStatus = "Mengecek koneksi...";
      _pingColor = const Color(0xFF7A9CC4);
      _latency = "";
    });
    try {
      final ping = Ping(ip, count: 1, timeout: 2);
      final response = await ping.stream.first;
      setState(() {
        if (response.response != null && response.error == null) {
          _pingColor = const Color(0xFF00E676);
          _latency = "${response.response!.time?.inMilliseconds ?? 0} ms";
          _pingStatus = "ONLINE";
        } else {
          _pingColor = const Color(0xFFFF6B6B);
          _pingStatus = "OFFLINE";
        }
      });
    } catch (e) {
      setState(() {
        _pingColor = const Color(0xFFFF6B6B);
        _pingStatus = "GAGAL";
      });
    }
  }

  Future<void> _launchWinbox(String ip) async {
    const winboxPath = r'D:\Edp NetOps\winbox.exe';
    if (!await File(winboxPath).exists()) {
      if (mounted) {
        _showErrorDialog(
          "Winbox Tidak Ditemukan",
          "Cek folder D:\\Edp NetOps\\winbox.exe",
        );
      }
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();
      final data = {for (var item in response) item['key']: item['value']};
      final String winboxPort = data['winbox_port'] ?? '8291';
      final String winboxUser = data['koneksi_user'] ?? 'admin';
      final String winboxPass = data['koneksi_pass'] ?? '';
      final address = '${ip.trim()}:$winboxPort';
      await Process.start(winboxPath, [
        address,
        winboxUser,
        winboxPass,
      ], mode: ProcessStartMode.detached);
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Winbox diluncurkan ke $address',
          Colors.blue,
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, "Gagal: $e", Colors.red);
    }
  }

  Future<void> _launchTelnet(String ip) async {
    try {
      await Process.start('cmd.exe', [
        '/c',
        'start',
        'cmd.exe',
        '/k',
        'telnet $ip 1953',
      ], runInShell: true);
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          "Telnet Gagal",
          "Tidak dapat membuka Telnet ke \$ip:1953\n\nPastikan fitur Telnet Windows sudah diaktifkan.",
        );
      }
    }
  }

  /// True jika koneksi utama adalah VSAT (tanpa backup / single)
  bool get _isVsatOnly {
    final main = (_currentStore.connectionType ?? '').toUpperCase();
    final backup = (_currentStore.connectionBackup ?? '').toUpperCase();
    return main.contains('VSAT') && !backup.contains('VSAT');
  }

  /// True jika toko pakai dual koneksi yang melibatkan VSAT (di backup)
  bool get _isVsatDual {
    final backup = (_currentStore.connectionBackup ?? '').toUpperCase();
    final main = (_currentStore.connectionType ?? '').toUpperCase();
    return backup.contains('VSAT') ||
        (main.contains('VSAT') && backup.isNotEmpty);
  }

  Future<void> _launchVnc(String ip) async {
    final String vncPath = r'D:\Edp NetOps\vncviewer.exe';

    // Cek apakah file vncviewer.exe ada di komputer
    if (!File(vncPath).existsSync()) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "File tidak ditemukan: $vncPath",
          Colors.red,
        );
      }
      return;
    }

    try {
      // 1. Ambil data password dari Supabase terlebih dahulu
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();

      // Ubah list hasil query menjadi Map agar mudah dipanggil
      final data = {for (var item in response) item['key']: item['value']};

      // 2. Ambil nilai password VNC
      // Jika di database kosong/gagal ditarik, akan menggunakan '123' sebagai cadangan
      final String vncPassword = data['vnc_pass'] ?? 'konvers1';

      // 3. Jalankan aplikasi VNC Viewer dengan password dari Supabase
      await Process.start(vncPath, [
        ip,
        '/password',
        vncPassword,
      ], mode: ProcessStartMode.detached);

      if (mounted) {
        CustomSnackBar.show(context, "Membuka VNC ke $ip...", Colors.blue);
      }
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, "Error: $e", Colors.red);
    }
  }

  Future<void> _launchCctv(String ip) async {
    const String cctvPort = "45200";
    final String url = "http://$ip:$cctvPort";
    try {
      // Menambahkan 'iexplore' untuk memaksa Windows membuka Internet Explorer
      await Process.run('cmd', ['/c', 'start', 'iexplore', url]);

      if (mounted) {
        CustomSnackBar.show(
          context,
          "Membuka Internet Explorer ke $url...",
          Colors.blue,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Gagal membuka Internet Explorer: $e",
          Colors.red,
        );
      }
    }
  }

  void _launchPingCmd(String ip) async {
    try {
      await Process.start('cmd', ['/c', 'start', 'cmd', '/k', 'ping $ip -t']);
    } catch (e) {
      CustomSnackBar.show(context, "Gagal membuka CMD.", Colors.red);
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentColor,
                      foregroundColor: context.primaryColor,
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editStore() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreFormPage(store: _currentStore),
      ),
    );
    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final response = await Supabase.instance.client
            .from('stores')
            .select()
            .eq('id', _currentStore.id)
            .single();
        setState(() {
          _currentStore = StoreModel.fromJson(response);
          _hasChanged = true;
          _isLoading = false;
        });
        _performPing();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            "Gagal memuat ulang data: $e",
            Colors.red,
          );
        }
      }
    }
  }

  Future<void> _deleteStore() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
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
                      Icons.delete_outline,
                      color: Color(0xFFFF6B6B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Hapus Toko?",
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Data toko ${_currentStore.storeCode} akan dihapus permanen.",
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
                          onPressed: () => Navigator.pop(context, false),
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
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Hapus",
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
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // 1. Hapus data dari database Supabase
        await Supabase.instance.client
            .from('stores')
            .delete()
            .eq('id', _currentStore.id);

        //
        await ActivityLogger.logAction(
          actionType: "HAPUS_TOKO",
          description:
              "Menghapus data toko: ${_currentStore.storeCode} - ${_currentStore.storeName}",
        );

        if (mounted) {
          CustomSnackBar.show(context, "Toko berhasil dihapus", Colors.green);
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(context, "Gagal menghapus: $e", Colors.red);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: _isLoading
          ? _buildLoadingState()
          : AnimatedOpacity(
              opacity: _animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPingCard(),
                          const SizedBox(height: 20),
                          _buildSectionLabel(
                            "INFORMASI TOKO",
                            Icons.store_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(),
                          const SizedBox(height: 20),
                          _buildSectionLabel(
                            _isMobile ? "INFORMASI IP" : "MANAJEMEN PERANGKAT",
                            _isMobile
                                ? Icons.lan_outlined
                                : Icons.device_hub_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildDeviceCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "MEMUAT...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context, _hasChanged),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_currentStore.storeCode} — ${_currentStore.storeName}",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "Detail & Manajemen",
            style: TextStyle(color: context.textSecondary, fontSize: 10),
          ),
        ],
      ),
      actions: [
        if (_isAdminOrAbove) ...[
          _buildAppBarAction(
            icon: Icons.edit_outlined,
            onTap: _editStore,
            color: context.accentColor,
          ),
          const SizedBox(width: 4),
          _buildAppBarAction(
            icon: Icons.delete_outline,
            onTap: _deleteStore,
            color: const Color(0xFFFF6B6B),
          ),
        ],
        const SizedBox(width: 12),
      ],
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

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.accentColor),
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

  // ==========================================
  // PING CARD
  // ==========================================
  Widget _buildPingCard() {
    if (_isMobile) {
      return const SizedBox.shrink();
    }
    final isOnline = _pingStatus == "ONLINE";
    final isChecking = _pingStatus == "Mengecek koneksi...";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pingColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _pingColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "STATUS KONEKSI GATEWAY",
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isChecking)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: context.accentColor,
                    strokeWidth: 2,
                  ),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _pingColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _pingColor.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Text(
                _pingStatus,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _pingColor,
                  letterSpacing: 1,
                ),
              ),
              if (isOnline && _latency.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _pingColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _pingColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _latency,
                    style: TextStyle(
                      color: _pingColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_currentStore.ipGateway != null) ...[
            const SizedBox(height: 6),
            Text(
              _currentStore.ipGateway!,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                label: "Cek Ulang",
                icon: Icons.refresh_rounded,
                color: context.accentColor,
                onTap: _performPing,
              ),
              const SizedBox(width: 10),
              _buildOutlineButton(
                label: "Ping CMD",
                icon: Icons.terminal_outlined,
                color: context.textSecondary,
                onTap: () {
                  if (_currentStore.ipGateway?.isNotEmpty == true) {
                    _launchPingCmd(_currentStore.ipGateway!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFO CARD
  // ==========================================
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.storefront_outlined,
            "Kode Toko",
            _currentStore.storeCode,
            isFirst: true,
            copyable: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.badge_outlined,
            "Nama Toko",
            _currentStore.storeName,
            copyable: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.cable_outlined,
            "Koneksi Utama",
            _currentStore.connectionType ?? "-",
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.settings_backup_restore_outlined,
            "Koneksi Backup",
            _currentStore.connectionBackup ?? "-",
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEVICE CARD
  // ==========================================
  Widget _buildDeviceCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JARINGAN UTAMA
          _buildSubHeader(
            "JARINGAN UTAMA",
            Icons.wifi_outlined,
            context.accentColor,
          ),
          _buildIpRow(
            context,
            "IP Gateway",
            _currentStore.ipGateway,
            isGateway: true,
            isFirst: true,
            // Telnet di kiri WINBOX — hanya untuk toko VSAT saja (bukan dual)
            prependButton:
                (!_isMobile &&
                    _isVsatOnly &&
                    _currentStore.ipGateway?.isNotEmpty == true)
                ? _buildMiniButton(
                    label: "TELNET",
                    icon: Icons.terminal_rounded,
                    color: context.warningColor,
                    onTap: () => _launchTelnet(_currentStore.ipGateway!),
                  )
                : null,
          ),
          if (_currentStore.ipVsat?.isNotEmpty == true &&
              _currentStore.ipVsat != '-') ...[
            _buildDivider(),
            _buildIpRow(
              context,
              "IP VSAT",
              _currentStore.ipVsat,
              icon: Icons.satellite_alt_outlined,
              customButton:
                  (!_isMobile &&
                      _isVsatDual &&
                      _currentStore.ipVsat?.isNotEmpty == true)
                  ? _buildMiniButton(
                      label: "TELNET",
                      icon: Icons.terminal_rounded,
                      color: context.warningColor,
                      onTap: () => _launchTelnet(_currentStore.ipVsat!),
                    )
                  : null,
            ),
          ],
          _buildDivider(),
          _buildIpRow(
            context,
            "IP RB WDCP",
            _currentStore.ipRbWdcp,
            icon: Icons.settings_input_antenna_outlined,
            customButton:
                (_isAdminOrAbove &&
                    (_currentStore.ipRbWdcp?.isNotEmpty == true))
                ? _buildMiniButton(
                    label: "OPEN",
                    icon: Icons.settings_remote_outlined,
                    color: context.accentColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WdcpControlPage(
                          ip: _currentStore.ipRbWdcp!,
                          storeName: _currentStore.storeName,
                          storeCode: _currentStore.storeCode,
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // STATION / KASIR — hanya tampil jika ada IP
          Builder(
            builder: (context) {
              final stations =
                  <(String, String?)>[
                        ('Station 1', _currentStore.ipStation1),
                        ('Station 2', _currentStore.ipStation2),
                        ('Station 3', _currentStore.ipStation3),
                        ('Station 4', _currentStore.ipStation4),
                        ('Station 5', _currentStore.ipStation5),
                      ]
                      .where(
                        (s) => s.$2 != null && s.$2!.isNotEmpty && s.$2 != '-',
                      )
                      .toList();

              if (stations.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  _buildSubDivider(),
                  _buildSubHeader(
                    "STATION / KASIR",
                    Icons.point_of_sale_outlined,
                    const Color(0xFF00C9A7),
                  ),
                  for (int i = 0; i < stations.length; i++) ...[
                    if (i > 0) _buildDivider(),
                    _buildIpRow(
                      context,
                      stations[i].$1,
                      stations[i].$2,
                      showVnc: true,
                      icon: Icons.computer_outlined,
                    ),
                  ],
                ],
              );
            },
          ),

          // PERANGKAT LAIN
          _buildSubDivider(),
          _buildSubHeader(
            "PERANGKAT LAINNYA",
            Icons.devices_outlined,
            const Color(0xFFFFB347),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIpRow(
                context,
                "IP STB",
                _currentStore.ipStb,
                icon: Icons.tv_outlined,
                customButton:
                    (!_isMobile &&
                        _currentStore.ipStb != null &&
                        _currentStore.ipStb!.isNotEmpty)
                    ? _buildMiniButton(
                        label: "FTP",
                        icon: Icons.upload_file,
                        color: context.warningColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FtpPage(
                                targetIp: _currentStore.ipStb!,
                                storeCode: _currentStore.storeCode,
                                storeName: _currentStore.storeName,
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              ),
              if (!_isMobile)
                ListenableBuilder(
                  listenable: FtpService(),
                  builder: (context, child) {
                    final ftpService = FtpService();
                    final activeJob = ftpService.activeJobs
                        .where(
                          (j) =>
                              j.isActive && j.targetIp == _currentStore.ipStb,
                        )
                        .firstOrNull;

                    if (activeJob != null) {
                      return ListenableBuilder(
                        listenable: activeJob,
                        builder: (context, _) => Padding(
                          padding: const EdgeInsets.only(
                            left: 45.0,
                            right: 16.0,
                            bottom: 12.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: activeJob.progress > 0
                                    ? activeJob.progress
                                    : null,
                                backgroundColor: context.surfaceColor,
                                color: context.warningColor,
                                minHeight: 2.5,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                activeJob.statusText,
                                style: TextStyle(
                                  color: context.warningColor,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          if (_currentStore.ipIkiosk?.isNotEmpty == true &&
              _currentStore.ipIkiosk != '-') ...[
            _buildDivider(),
            _buildIpRow(
              context,
              "IP iKiosk",
              _currentStore.ipIkiosk,
              icon: Icons.touch_app_outlined,
            ),
          ],
          if (_currentStore.ipTimbangan?.isNotEmpty == true &&
              _currentStore.ipTimbangan != '-') ...[
            _buildDivider(),
            _buildIpRow(
              context,
              "Timbangan",
              _currentStore.ipTimbangan,
              icon: Icons.scale_outlined,
            ),
          ],

          // CCTV — hanya tampil jika ada IP
          Builder(
            builder: (context) {
              final cctvs =
                  <(String, String?)>[
                        ('CCTV 1', _currentStore.ipCctv1),
                        ('CCTV 2', _currentStore.ipCctv2),
                      ]
                      .where(
                        (c) => c.$2 != null && c.$2!.isNotEmpty && c.$2 != '-',
                      )
                      .toList();

              if (cctvs.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  _buildSubDivider(),
                  _buildSubHeader(
                    "CCTV / NVR",
                    Icons.videocam_outlined,
                    const Color(0xFFFF6B6B),
                  ),
                  for (int i = 0; i < cctvs.length; i++) ...[
                    if (i > 0) _buildDivider(),
                    _buildIpRow(
                      context,
                      cctvs[i].$1,
                      cctvs[i].$2,
                      showCctv: true,
                      icon: Icons.videocam_outlined,
                      isLast: i == cctvs.length - 1,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: context.borderColor.withOpacity(0.6),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSubDivider() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.symmetric(
          horizontal: BorderSide(color: context.borderColor),
        ),
      ),
    );
  }

  Widget _buildSubHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    bool copyable = false,
  }) {
    final valueWidget = copyable
        ? GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              CustomSnackBar.show(
                context,
                '$label disalin!',
                const Color(0xFF00D4FF),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.copy_outlined,
                  size: 12,
                  color: context.textSecondary.withOpacity(0.45),
                ),
              ],
            ),
          )
        : Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: context.textSecondary, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildIpRow(
    BuildContext context,
    String label,
    String? value, {
    bool isGateway = false,
    bool showVnc = false,
    bool showCctv = false,
    bool showPing = true,
    IconData icon = Icons.computer_outlined,
    Widget? customButton,
    Widget? prependButton, // ditampilkan sebelum WINBOX
    bool isFirst = false,
    bool isLast = false,
  }) {
    final bool hasValue = value != null && value.isNotEmpty && value != "-";

    // Kumpulkan tombol yang aktif
    final List<Widget> actionButtons = [
      if (!_isMobile) ...[
        if (hasValue && prependButton != null) prependButton,
        if (hasValue && isGateway && _isAdminOrAbove && !_isVsatOnly)
          _buildMiniButton(
            label: "WINBOX",
            color: context.accentColor,
            onTap: () => _launchWinbox(value),
          ),
        if (hasValue && showVnc)
          _buildMiniButton(
            label: "VNC",
            icon: Icons.desktop_windows_outlined,
            color: const Color(0xFF00C9A7),
            onTap: () => _launchVnc(value),
          ),
        if (hasValue && showCctv && _isAdminOrAbove)
          _buildMiniButton(
            label: "VIEW",
            icon: Icons.videocam_outlined,
            color: const Color(0xFFFF6B6B),
            onTap: () => _launchCctv(value),
          ),
        if (hasValue && customButton != null)
          customButton, // Ini akan menyembunyikan tombol MANAGE
        if (hasValue && showPing && !isGateway)
          _buildMiniButton(
            label: "PING",
            color: context.textSecondary,
            onTap: () => _launchPingCmd(value),
            isOutline: true,
          ),
      ],
    ];

    final Widget ipLabel = Text(
      label,
      style: TextStyle(color: context.textSecondary, fontSize: 11),
    );
    final Widget ipValue = GestureDetector(
      onTap: hasValue
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              CustomSnackBar.show(
                context,
                "$label disalin!",
                const Color(0xFF00D4FF),
              );
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasValue ? value : "—",
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: hasValue
                  ? context.textPrimary
                  : context.textSecondary.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          if (hasValue) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.copy_outlined,
              size: 11,
              color: context.textSecondary.withOpacity(0.5),
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        // Threshold: jika ada tombol & lebar < 380 → layout vertikal
        final bool isCompact =
            constraints.maxWidth < 380 && actionButtons.isNotEmpty;

        if (isCompact) {
          // LAYOUT SEMPIT: ikon + label di kiri atas, IP di bawahnya, tombol di kanan
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: hasValue
                          ? context.accentColor.withOpacity(0.7)
                          : context.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 25), // indent menyesuaikan lebar ikon
                    Expanded(child: ipValue),
                    Wrap(spacing: 5, children: actionButtons),
                  ],
                ),
              ],
            ),
          );
        } else {
          // LAYOUT LEBAR: ikon + label + IP kiri, tombol kanan (default)
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasValue
                      ? context.accentColor.withOpacity(0.7)
                      : context.textSecondary,
                  size: 17,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ipLabel, const SizedBox(height: 2), ipValue],
                  ),
                ),
                if (actionButtons.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Wrap(spacing: 5, children: actionButtons),
                ],
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMiniButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
    bool isOutline = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withOpacity(isOutline ? 0.3 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: context.primaryColor, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: context.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
