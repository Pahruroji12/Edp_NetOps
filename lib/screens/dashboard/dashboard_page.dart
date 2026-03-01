import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/store_model.dart';
import '../store_management/store_list_page.dart';
import '../store_management/store_detail_page.dart';
import '../auth/login_page.dart';
import '../profile/profile_page.dart';
import '../../utils/app_colors.dart';
import '../settings/settings_page.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/activity_logger.dart';
import '../profile/admin_panel_page.dart';
import '../store_management/ping_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<StoreModel> _allStores = [];
  List<StoreModel> _filteredStores = [];
  final TextEditingController _searchListController = TextEditingController();

  int _totalStores = 0;
  int _foStores = 0;
  int _backupVsat = 0;
  int _singleVsat = 0;
  int _gsmStores = 0;
  int _xlStores = 0;

  bool _isLoading = true;
  bool _animationsReady = false;

  // Staggered section flags
  bool _showAppBar = false;
  bool _showWelcome = false;
  bool _showStats = false;
  bool _showStoreList = false;
  final ScrollController _storeListController = ScrollController();

  late Timer _timer;
  String _timeString = "";
  String _dateString = "";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _startRealtimeClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Staggered Fade-In Slide-Up per section
      setState(() => _animationsReady = true);
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _showAppBar = true);
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _showWelcome = true);
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showStats = true);
      });
      Future.delayed(const Duration(milliseconds: 580), () {
        if (mounted) setState(() => _showStoreList = true);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _storeListController.dispose();
    _searchListController.dispose();
    super.dispose();
  }

  void _startRealtimeClock() {
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    final String second = now.second.toString().padLeft(2, '0');
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    if (mounted) {
      setState(() {
        _timeString = "$hour:$minute:$second";
        _dateString =
            "${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}";
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stores')
          .select()
          .order('store_code', ascending: true);

      final data = response as List<dynamic>;
      List<StoreModel> allData = [];
      try {
        allData = data.map((json) => StoreModel.fromJson(json)).toList();
      } catch (e) {
        debugPrint("Error Mapping: $e");
      }

      int fo = 0, backupVsat = 0, singleVsat = 0, gsm = 0, xl = 0;
      for (var store in allData) {
        String mainConn = store.connectionType?.toLowerCase() ?? "";
        String backConn = store.connectionBackup?.toLowerCase() ?? "";
        String ipVsat = store.ipVsat ?? "";
        bool isFo =
            mainConn.contains("astinet") ||
            mainConn.contains("icon") ||
            mainConn.contains("fiberstar");
        if (isFo) fo++;
        bool hasVsatIp = ipVsat.isNotEmpty;
        bool isBackupVsat =
            !mainConn.contains("vsat") &&
            (backConn.contains("vsat") || hasVsatIp);
        if (isBackupVsat) backupVsat++;
        if (mainConn.contains("vsat") || (mainConn.isEmpty && hasVsatIp))
          singleVsat++;
        if (mainConn.contains("gsm") || mainConn.contains("orbit")) gsm++;
        if (mainConn.contains("xl")) xl++;
      }

      if (mounted) {
        setState(() {
          _allStores = allData;
          _filteredStores = allData;
          _totalStores = allData.length;
          _foStores = fo;
          _backupVsat = backupVsat;
          _singleVsat = singleVsat;
          _gsmStores = gsm;
          _xlStores = xl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Dashboard: $e");
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

  void _runFilter(String keyword) {
    List<StoreModel> results = keyword.isEmpty
        ? _allStores
        : _allStores
              .where(
                (store) =>
                    store.storeName.toLowerCase().contains(
                      keyword.toLowerCase(),
                    ) ||
                    store.storeCode.toLowerCase().contains(
                      keyword.toLowerCase(),
                    ),
              )
              .toList();
    setState(() => _filteredStores = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingScreen()
          : AnimatedOpacity(
              opacity: _animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _animationsReady ? Offset.zero : const Offset(0, 0.02),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAnimatedOpacity(
                      opacity: _showAppBar ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      sliver: _buildSliverAppBar(),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome section — slide up delay 220ms
                            _animSection(
                              visible: _showWelcome,
                              delay: 0,
                              child: _buildWelcomeSection(),
                            ),
                            const SizedBox(height: 24),
                            // Stats label + grid — slide up delay 400ms
                            _animSection(
                              visible: _showStats,
                              delay: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel(
                                    "STATISTIK JARINGAN",
                                    Icons.analytics_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatsGrid(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Store list — slide up delay 580ms
                            _animSection(
                              visible: _showStoreList,
                              delay: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel(
                                    "DAFTAR TOKO",
                                    Icons.store_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStoreListCard(),
                                ],
                              ),
                            ),
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

  // ── Fade-In Slide-Up helper (sama dengan profile_page) ──────────────────
  Widget _animSection({
    required bool visible,
    required Widget child,
    int delay = 0,
    Duration duration = const Duration(milliseconds: 500),
    Offset from = const Offset(0, 0.04),
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : from,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "MEMUAT DATA...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
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
      backgroundColor: context.primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Builder(
        builder: (ctx) {
          final isDesktop = MediaQuery.of(ctx).size.width > 600;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.accentColor.withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isDesktop)
                // Desktop: EDP NETOPS  DASHBOARD satu baris
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "EDP NETOPS",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      "  DASHBOARD",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                )
              else
                // Mobile: bertumpuk
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "EDP NETOPS",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "DASHBOARD",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _fetchDashboardData,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.accentColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_outlined,
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
  // WELCOME SECTION — Responsif
  // Layar sempit: jam pindah ke bawah (Column)
  // Layar lebar: jam di kanan (Row)
  // ==========================================
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.accentColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (_, constraints) {
              // Jam pindah ke bawah jika lebar < 420px
              final isWide = constraints.maxWidth >= 420;

              final greetingPart = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Datang,",
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUserName.isNotEmpty ? currentUserName : "User",
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.accentColor.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF88),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF88).withOpacity(0.7),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Monitoring Infrastruktur Jaringan",
                          style: TextStyle(
                            color: context.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final clockPart = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: isWide
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeString,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateString,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "WIB",
                      style: TextStyle(
                        color: context.accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: greetingPart),
                    const SizedBox(width: 16),
                    clockPart,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greetingPart,
                    const SizedBox(height: 16),
                    // Jam melebar penuh di layar sempit
                    SizedBox(width: double.infinity, child: clockPart),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
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

  // ==========================================
  // STATS GRID — Responsif
  // ≥ 600px : 6 kolom (1 baris)
  // 350–599px: 3 kolom (2 baris)
  // < 350px : 2 kolom (3 baris)
  // ==========================================
  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        "Total Toko",
        _totalStores,
        Icons.store_outlined,
        context.accentColor,
        const Color(0xFF0A2030),
      ),
      _StatItem(
        "Fiber Optic",
        _foStores,
        Icons.cable_outlined,
        const Color(0xFF00E676),
        const Color(0xFF0A2018),
      ),
      _StatItem(
        "Backup VSAT",
        _backupVsat,
        Icons.satellite_alt_outlined,
        const Color(0xFF6C63FF),
        const Color(0xFF150F2A),
      ),
      _StatItem(
        "Single VSAT",
        _singleVsat,
        Icons.satellite_outlined,
        const Color(0xFFFFB347),
        const Color(0xFF241D10),
      ),
      _StatItem(
        "GSM/Orbit",
        _gsmStores,
        Icons.cell_tower_outlined,
        const Color(0xFFFF6B6B),
        const Color(0xFF2A1015),
      ),
      _StatItem(
        "XL",
        _xlStores,
        Icons.signal_cellular_alt_outlined,
        const Color(0xFFBB86FC),
        const Color(0xFF1A102A),
      ),
    ];

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        // Hitung jumlah kolom berdasarkan lebar
        int cols;
        if (w >= 600) {
          cols = 6;
        } else if (w >= 350) {
          cols = 3;
        } else {
          cols = 2;
        }
        final spacing = 12.0;
        final itemWidth = (w - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map((stat) => _buildStatCard(stat, itemWidth))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatItem stat, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: stat.accentColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: stat.accentColor.withOpacity(0.2)),
            ),
            child: Icon(stat.icon, color: stat.accentColor, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            stat.value.toString(),
            style: TextStyle(
              color: stat.accentColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stat.label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STORE LIST CARD — Responsif
  // Header: search bar + badge wrap ke bawah jika sempit
  // ==========================================
  Widget _buildStoreListCard() {
    return Container(
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final isWide = constraints.maxWidth >= 420;

                final titleWidget = Text(
                  "Daftar Toko",
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                );

                final searchWidget = SizedBox(
                  // Lebar penuh di layar sempit, fixed 190 di lebar
                  width: isWide ? 190 : double.infinity,
                  height: 36,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: context.accentColor, // Warna garis kursor
                        selectionColor: context.accentColor.withOpacity(
                          0.3,
                        ), // Warna blok teks
                        selectionHandleColor:
                            context.accentColor, // Warna pentolan kursor di HP
                      ),
                    ),
                    child: TextField(
                      controller: _searchListController,
                      onChanged: _runFilter,
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
                        suffixIcon: _searchListController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 14,
                                  color: context.textSecondary,
                                ),
                                onPressed: () {
                                  _searchListController.clear();
                                  _runFilter('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                );

                final badgeWidget = Container(
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
                    "${_filteredStores.length} Toko",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.accentColor,
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
                      const SizedBox(width: 10),
                      badgeWidget,
                    ],
                  );
                } else {
                  // Layout sempit: judul + badge satu baris, search di bawah
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
          Container(height: 1, color: context.borderColor),
          SizedBox(
            height: 330,
            child: Scrollbar(
              controller: _storeListController,
              thumbVisibility: true,
              radius: const Radius.circular(10),
              child: ListView.separated(
                controller: _storeListController,
                padding: EdgeInsets.zero,
                itemCount: _filteredStores.length,
                separatorBuilder: (c, i) => Divider(
                  height: 1,
                  color: context.borderColor.withOpacity(0.5),
                ),
                itemBuilder: (context, index) =>
                    _buildStoreItem(_filteredStores[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STORE ITEM — Responsif
  // IP address disembunyikan di layar sangat sempit
  // ==========================================
  Widget _buildStoreItem(StoreModel store) {
    String mainType = (store.connectionType ?? "-").trim().toUpperCase();
    String backupType = (store.connectionBackup ?? "").trim().toUpperCase();
    bool hasBackup = backupType.isNotEmpty && backupType != "-";
    bool hasIpVsat = store.ipVsat != null && store.ipVsat!.isNotEmpty;

    if (!hasBackup && hasIpVsat) {
      backupType = "VSAT";
      hasBackup = true;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailPage(store: store),
          ),
        ),
        splashColor: context.accentColor.withOpacity(0.05),
        highlightColor: context.accentColor.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 380;
              return Row(
                children: [
                  // Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Center(
                      child: Text(
                        store.storeCode.isNotEmpty
                            ? store.storeCode.substring(0, 1)
                            : "?",
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${store.storeCode} — ${store.storeName}",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _buildConnectionBadge(mainType),
                            if (hasBackup) ...[
                              const SizedBox(width: 5),
                              Icon(
                                Icons.add,
                                size: 9,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              _buildConnectionBadge(backupType),
                            ],
                            // IP hanya tampil jika lebar cukup
                            if (isWide) ...[
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  store.ipGateway ?? "No IP",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: context.textSecondary,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionBadge(String label) {
    Color color = context.textSecondary;
    String lower = label.toLowerCase();
    if (lower.contains("astinet"))
      color = const Color(0xFF29B6F6);
    else if (lower.contains("icon"))
      color = const Color(0xFF26C6DA);
    else if (lower.contains("fiberstar"))
      color = const Color(0xFF66BB6A);
    else if (lower.contains("orbit"))
      color = const Color(0xFFEF5350);
    else if (lower.contains("xl") || lower.contains("tun"))
      color = const Color(0xFFAB47BC);
    else if (lower.contains("indosat") || lower.contains("isat"))
      color = const Color(0xFFFFCA28);
    else if (lower.contains("vsat"))
      color = const Color(0xFFFFB74D);
    else if (lower.contains("gsm"))
      color = const Color(0xFFFF7043);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Icon(
                Icons.dashboard_outlined,
                color: context.accentColor,
                size: 20,
              ),
              title: Text(
                'Dashboard',
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
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

          if (Platform.isWindows)
            _buildDrawerTile(
              icon: Icons.network_check,
              label: 'Ping Scanner',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PingPage()),
                );
              },
            ),

          _buildDrawerTile(
            icon: Icons.person_outline,
            label: 'Profil Saya',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ProfilePage()),
              );
            },
          ),

          if (currentUserRole.toLowerCase() == 'administrator') ...[
            // Menu Setting hanya akan dirender/digambar jika rolenya administrator
            _buildDrawerTile(
              icon: Icons.settings_outlined,
              label: 'Setting',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => const SettingsPage()),
                );
              },
            ),
          ],

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
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
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

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  const _StatItem(
    this.label,
    this.value,
    this.icon,
    this.accentColor,
    this.bgColor,
  );
}
