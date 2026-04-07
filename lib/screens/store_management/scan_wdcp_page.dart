import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Utils & Services ---
import '../../utils/app_colors.dart';
import '../../utils/custom_snackbar.dart';
import '../../services/scan_rbwdcp_service.dart';

// --- Halaman Lain ---
import 'wdcp_control_page.dart';

class ScanWdcpPage extends StatefulWidget {
  const ScanWdcpPage({super.key});

  @override
  State<ScanWdcpPage> createState() => _ScanWdcpPageState();
}

class _ScanWdcpPageState extends State<ScanWdcpPage> {
  // ── Singleton service — scan tetap berjalan saat pindah halaman ──────────
  final ScanRbwdcpService _scan = ScanRbwdcpService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = [];

  // ── Staggered Fade-In Slide-Up flags (identik store_list_page) ──
  bool _showScanPanel = false;
  bool _showListCard = false;

  final TextEditingController _searchController = TextEditingController();

  // ── TAMBAHAN: Controller khusus untuk Scrollbar Daftar Toko ──
  final ScrollController _listScrollController = ScrollController();

  // Variabel untuk menampung data user di Drawer

  String _activeFilter = 'Semua';

  @override
  void initState() {
    super.initState();

    _fetchStores();
    _scan.addListener(_onScanUpdate);

    // ── Staggered Fade-In Slide-Up (identik store_list_page) ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _showScanPanel = true);
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _showListCard = true);
      });
    });
  }

  @override
  void dispose() {
    _scan.removeListener(_onScanUpdate);
    _searchController.dispose();
    _listScrollController.dispose(); // Jangan lupa di-dispose
    super.dispose();
  }

  void _onScanUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchStores() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stores')
          .select()
          .order('store_code', ascending: true);

      final List<Map<String, dynamic>> validStores = [];

      // Karena ini halaman Scan WDCP, kita pastikan hanya mengambil toko yang punya IP WDCP
      for (var item in response) {
        final ipWdcp = (item['ip_rb_wdcp'] ?? '').toString().trim();
        if (ipWdcp.isNotEmpty && ipWdcp != '-') {
          validStores.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _stores = validStores; // Simpan semua data valid ke _stores
          _applyFilters(); // Langsung jalankan filter (jika ada teks pencarian sebelumnya)
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          "Gagal memuat data toko: $e",
          AppStatusColors.danger,
        );
      }
    }
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredStores = _stores.where((store) {
        final code = (store['store_code'] ?? '').toString().toLowerCase();
        final name = (store['store_name'] ?? '').toString().toLowerCase();
        final ipWdcp = (store['ip_rb_wdcp'] ?? '').toString().toLowerCase();

        // Pencarian Teks: Cek apakah Kode, Nama, atau IP WDCP mengandung teks yang diketik
        final matchText =
            q.isEmpty ||
            code.contains(q) ||
            name.contains(q) ||
            ipWdcp.contains(q);

        if (!matchText)
          return false; // Jika teks tidak cocok, langsung buang dari daftar

        if (_activeFilter == 'Semua') return true;

        // Cek Filter Koneksi (Jika ke depannya ditambahkan tombol filter)
        final conn = (store['connection_type'] ?? '').toString().toLowerCase();
        switch (_activeFilter) {
          case 'FO':
            return conn.contains('astinet') ||
                conn.contains('icon') ||
                conn.contains('fiberstar');
          case 'VSAT':
            final ipVsat = (store['ip_vsat'] ?? '').toString();
            return conn.contains('vsat') || ipVsat.isNotEmpty;
          case 'GSM':
            return conn.contains('gsm') || conn.contains('orbit');
          case 'XL':
            return conn.contains('xl');
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> _launchPingCmd(String ip) async {
    try {
      await Process.start('cmd', ['/c', 'start', 'cmd', '/k', 'ping $ip -t']);
    } catch (e) {
      CustomSnackBar.show(context, "Gagal membuka CMD.", Colors.red);
    }
  }

  Future<void> _launchWinbox(String ip) async {
    const String winboxPath = r'D:\Edp NetOps\winbox.exe';
    if (!await File(winboxPath).exists()) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "File winbox.exe tidak ditemukan!",
          AppStatusColors.danger,
        );
      }
      return;
    }
    try {
      // Ambil kredensial WDCP dari app_settings (sama seperti WdcpControlPage)
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();
      final data = {for (var item in response) item['key']: item['value']};
      final String winboxUser = data['wdcp_user'] ?? 'admin';
      final String winboxPass = data['wdcp_pass'] ?? '';
      final String winboxPort = data['winbox_port'] ?? '8291';

      final address = '$ip:$winboxPort';
      await Process.start(winboxPath, [
        address,
        winboxUser,
        winboxPass,
      ], mode: ProcessStartMode.detached);
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Membuka Winbox ke $address...",
          context.accentColor,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Gagal membuka Winbox: $e",
          AppStatusColors.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Scan Panel — Fade-In Slide-Up pertama (80ms) ────────
                  _buildSectionHeader('SCAN RBWDCP', Icons.radar_rounded),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _showScanPanel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: _showScanPanel
                          ? Offset.zero
                          : const Offset(0, -0.03),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: _buildScannerPanel(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Daftar Toko — Fade-In Slide-Up kedua (280ms) ────────
                  _buildSectionHeader('DAFTAR TOKO', Icons.store_outlined),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _showListCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: _showListCard
                          ? Offset.zero
                          : const Offset(0, 0.04),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: _buildStoreListCard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KOMPONEN UI ---
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: MediaQuery.of(context).size.width >= 850
          ? null
          : IconButton(
              icon: Icon(Icons.menu_rounded, color: context.textPrimary),
              onPressed: () =>
                  MainLayout.scaffoldKey.currentState?.openDrawer(),
            ),
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Row(
        children: [
          // Titik biru glowing — identik ping_page
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SCAN WDCP",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                "Scan RbWDCP — Network Tools",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Tombol Refresh — identik _buildRefreshButton() di store_list_page
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _fetchStores,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.accentColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: context.accentColor,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Refresh",
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  // ==========================================
  // DRAWER (SMART DROPDOWN VERSION)
  // ==========================================
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

  // ══════════════════════════════════════════════════════════
  // STAT CHIP — chips kecil di scanner panel (Berhasil/Offline/Auth)
  // ══════════════════════════════════════════════════════════
  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.75),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerPanel() {
    final scanColor = _scan.isScanning
        ? AppStatusColors.danger
        : context.accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris: Icon + Status + Tombol Scan (kanan) ──
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: context.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Title + Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SCAN WDCP Y",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _scan.scanStatus,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Tombol kompak di kanan ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol CSV (jika ada hasil scan)
                  if (_scan.scanFilePath != null) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => CustomSnackBar.show(
                          context,
                          "Disimpan di: ${_scan.scanFilePath}",
                          context.successColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.successColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.successColor.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                size: 13,
                                color: context.successColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "CSV",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.successColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Tombol Scan / Batalkan
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _scan.isScanning
                          ? _scan.cancelScan
                          : _scan.startScan,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scanColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scanColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _scan.isScanning
                                  ? Icons.stop_rounded
                                  : Icons.radar_rounded,
                              size: 13,
                              color: scanColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _scan.isScanning ? "BATAL" : "SCAN",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scanColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Progress bar selalu ada di bawah (transparan saat idle) ──
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _scan.isScanning ? _scan.scanProgress : 0.0,
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                _scan.isScanning ? context.accentColor : Colors.transparent,
              ),
              minHeight: 4,
            ),
          ),

          // ── Stats chips — muncul saat ada hasil scan ──
          if (_scan.scanTotal > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatChip(
                  label: 'Berhasil',
                  value: '${_scan.scanSuccess}',
                  color: context.successColor,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  label: 'Offline',
                  value: '${_scan.scanOffline}',
                  color: AppStatusColors.danger,
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  label: 'Default Auth',
                  value: '${_scan.scanAuthActive}',
                  color: context.warningColor,
                  icon: Icons.warning_amber_rounded,
                ),
                const Spacer(),
                Text(
                  '${_scan.scanCompleted}/${_scan.scanTotal}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STORE LIST HEADER — dengan badge + refresh
  // ══════════════════════════════════════════════════════════

  Widget _buildStoreListCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Bayangan ala dashboard
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER (Responsif ala Dashboard) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: LayoutBuilder(
              builder: (_, constraints) {
                // Diperlebar sedikit batasnya karena ada tambahan tombol Refresh
                final isWide = constraints.maxWidth >= 450;

                final titleWidget = Text(
                  "DAFTAR RBWDCP",
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                );

                final searchWidget = SizedBox(
                  width: isWide ? 190 : double.infinity,
                  height: 36,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: context.accentColor,
                        selectionColor: context.accentColor.withOpacity(0.3),
                        selectionHandleColor: context.accentColor,
                      ),
                    ),
                    child: TextField(
                      // Menggunakan controller & filter milik Scan WDCP
                      controller: _searchController,
                      onChanged: (_) => _applyFilters(),
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: "Cari toko...",
                        hintStyle: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: context.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        filled: true,
                        fillColor: context.surfaceColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.accentColor,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 14,
                                  color: context.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                );

                // Badge angka milik Scan WDCP — lebar fixed agar tidak geser
                final badgeWidget = SizedBox(
                  width: 72,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.accentColor.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      "${_filteredStores.length}/${_stores.length}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.accentColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                );

                if (isWide) {
                  // Layout lebar: [Judul] [SPACER] [Search] [Badge]
                  return Row(
                    children: [
                      titleWidget,
                      const Spacer(),
                      searchWidget,
                      const SizedBox(width: 8),
                      badgeWidget,
                    ],
                  );
                } else {
                  // Layout sempit: [Judul] [Spacer] [Badge] (Baris 1) -> [Search] (Baris 2)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [titleWidget, const Spacer(), badgeWidget]),
                      const SizedBox(height: 10),
                      searchWidget,
                    ],
                  );
                }
              },
            ),
          ),
          Divider(height: 1, color: context.borderColor.withOpacity(0.5)),

          // ── KONTEN LIST & LOADING STATE (Milik Scan WDCP) ──
          // Semua state dibungkus SizedBox tinggi fixed agar card tidak bergeser
          SizedBox(
            height: 450,
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.accentColor.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.accentColor.withOpacity(0.1),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: context.accentColor,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "MEMUAT DATA TOKO...",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredStores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 32,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Tidak ada yang cocok'
                              : 'Tidak ada data',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller: _listScrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: ListView.separated(
                      controller: _listScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredStores.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: context.borderColor.withOpacity(0.5),
                      ),
                      itemBuilder: (_, i) => _buildStoreRow(_filteredStores[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreRow(Map<String, dynamic> store) {
    final storeCode = store['store_code'] ?? '-';
    final storeName = store['store_name'] ?? '-';
    final ipWdcp = (store['ip_rb_wdcp'] ?? '-').toString().trim();
    final connType = store['connection_type'] ?? '-';
    final hasIp = ipWdcp.isNotEmpty && ipWdcp != '-';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;

        final infoSection = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: context.accentColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.router_outlined,
                size: 15,
                color: context.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // Info toko
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Kode Toko - Nama Toko
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$storeCode - $storeName',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            final String textToCopy = "$storeCode - $storeName";
                            Clipboard.setData(ClipboardData(text: textToCopy));

                            CustomSnackBar.show(
                              context,
                              'Info toko disalin!',
                              context.accentColor,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.content_copy_rounded,
                              size: 13,
                              color: context.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 2. Tipe Koneksi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _connColor(connType).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _connColor(connType).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      connType,
                      style: TextStyle(
                        color: _connColor(connType),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 3. IP + copy
                  GestureDetector(
                    onTap: hasIp
                        ? () {
                            Clipboard.setData(ClipboardData(text: ipWdcp));
                            CustomSnackBar.show(
                              context,
                              'IP disalin!',
                              const Color(0xFF00D4FF),
                            );
                          }
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ipWdcp,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasIp
                                ? context.textPrimary
                                : context.textSecondary.withOpacity(0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (hasIp) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_outlined,
                            size: 10,
                            color: context.textSecondary.withOpacity(0.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        // Tombol — identik store_detail_page _buildMiniButton
        // Urutan: OPEN | WINBOX | PING (ping pojok kanan)
        final buttons = hasIp
            ? Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _buildMiniButton(
                    label: 'OPEN',
                    icon: Icons.settings_remote_outlined,
                    color: context.accentColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WdcpControlPage(
                          ip: ipWdcp,
                          storeName: storeName,
                          storeCode: storeCode,
                        ),
                      ),
                    ),
                  ),
                  _buildMiniButton(
                    label: 'WINBOX',
                    icon: Icons.terminal_rounded,
                    color: context.secondaryAccent,
                    onTap: () => _launchWinbox(ipWdcp),
                  ),
                  _buildMiniButton(
                    label: 'PING',
                    color: context.textSecondary,
                    onTap: () => _launchPingCmd(ipWdcp),
                    isOutline: true,
                  ),
                ],
              )
            : const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: infoSection),
                    const SizedBox(width: 12),
                    buttons,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoSection,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 36), // indent sesuai icon
                        buttons,
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // CONN COLOR — identik store_list_page (centralized)
  // ══════════════════════════════════════════════════════════
  Color _connColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('astinet')) return const Color(0xFF29B6F6);
    if (l.contains('icon')) return const Color(0xFF26C6DA);
    if (l.contains('fiberstar')) return const Color(0xFF66BB6A);
    if (l.contains('orbit')) return const Color(0xFFEF5350);
    if (l.contains('xl') || l.contains('tun')) return const Color(0xFFAB47BC);
    if (l.contains('indosat') || l.contains('isat')) {
      return const Color(0xFFFFCA28);
    }
    if (l.contains('vsat')) return const Color(0xFFFFB74D);
    if (l.contains('gsm')) return const Color(0xFFFF7043);
    return const Color(0xFF7A9CC4);
  }

  // ══════════════════════════════════════════════════════════
  // MINI BUTTON — identik store_detail_page
  // ══════════════════════════════════════════════════════════

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
}
