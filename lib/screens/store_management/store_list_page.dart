import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/store_model.dart';
import 'store_detail_page.dart';
import 'store_form_page.dart';
import '../auth/login_page.dart';
import '../../utils/custom_snackbar.dart';
import '../profile/profile_page.dart';
import '../dashboard/dashboard_page.dart';
import '../../utils/app_colors.dart';
import '../settings/settings_page.dart';
import '../../utils/activity_logger.dart';
import '../profile/admin_panel_page.dart';
import '../../utils/export_helper.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<StoreModel> _allStores = [];
  List<StoreModel> _filteredStores = [];
  bool _isLoading = true;
  // bool _animationsReady = false;

  // Staggered Fade-In Slide-Up flags
  bool _showHeader = false;
  bool _showList = false;
  final TextEditingController _searchController = TextEditingController();

  // Filter chip aktif
  String _activeFilter = 'Semua';
  final List<String> _filterChips = ['Semua', 'FO', 'VSAT', 'GSM', 'XL'];

  bool get _isAdminOrAbove =>
      currentUserRole.toLowerCase() == 'administrator' ||
      currentUserRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _fetchStores();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // setState(() => _animationsReady = true);
      // Staggered Fade-In Slide-Up
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _showHeader = true);
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _showList = true);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stores')
          .select()
          .order('store_code', ascending: true);
      if (mounted) {
        setState(() {
          _allStores = (response as List<dynamic>)
              .map((json) => StoreModel.fromJson(json))
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(context, "Gagal memuat data: $e", Colors.red);
      }
    }
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredStores = _allStores.where((store) {
        final matchText =
            q.isEmpty ||
            store.storeCode.toLowerCase().contains(q) ||
            store.storeName.toLowerCase().contains(q) ||
            (store.ipGateway ?? '').toLowerCase().contains(q);
        if (!matchText) return false;
        if (_activeFilter == 'Semua') return true;
        final conn = (store.connectionType ?? '').toLowerCase();
        switch (_activeFilter) {
          case 'FO':
            return conn.contains('astinet') ||
                conn.contains('icon') ||
                conn.contains('fiberstar');
          case 'VSAT':
            return conn.contains('vsat') || (store.ipVsat?.isNotEmpty == true);
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

  // Warna badge koneksi — centralized
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.primaryColor,
      drawer: _buildDrawer(),
      floatingActionButton: _isAdminOrAbove ? _buildFab() : null,
      body: Column(
        children: [
          // Header — Fade-In Slide-Up pertama (80ms)
          AnimatedOpacity(
            opacity: _showHeader ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _showHeader ? Offset.zero : const Offset(0, -0.03),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              child: _buildHeader(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : AnimatedOpacity(
                    opacity: _showList ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: _showList ? Offset.zero : const Offset(0, 0.04),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: _filteredStores.isEmpty
                          ? _buildEmptyState()
                          : _buildStoreList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FAB
  // ==========================================
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.accentColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const StoreFormPage()),
          );
          if (result == true) _fetchStores();
        },
        backgroundColor: context.accentColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.add_rounded, color: context.primaryColor, size: 20),
        label: Text(
          "Toko Baru",
          style: TextStyle(
            color: context.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER — Responsif
  // ==========================================
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris atas: hamburger + judul + spacer + badge + refresh ──
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 480;
              return Row(
                children: [
                  _buildIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
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
                          const SizedBox(width: 8),
                          Text(
                            "DATA TOKO",
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_filteredStores.length} dari ${_allStores.length} toko",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Badge total hanya di layar lebar
                  if (isWide) ...[
                    _buildStatBadge(
                      "${_allStores.length}",
                      "TOTAL",
                      context.accentColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildExportButton(),
                  const SizedBox(width: 8),
                  _buildRefreshButton(),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // ── Search bar ──
          _buildSearchBar(),
          const SizedBox(height: 12),

          // ── Filter chips — selalu horizontal scroll ──
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderColor),
          ),
          child: Icon(icon, color: context.textPrimary, size: 18),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            // Tangkap pesan kembaliannya
            final message = await ExportHelper.exportToCSV(_filteredStores);

            if (mounted) {
              // Tampilkan pesan sukses warna hijau
              CustomSnackBar.show(context, message, Colors.green);
            }
          } catch (e) {
            if (mounted) {
              CustomSnackBar.show(context, e.toString(), context.dangerColor);
            }
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.successColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.download_rounded,
                color: context.successColor,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                "Export",
                style: TextStyle(
                  color: context.successColor,
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

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _fetchStores,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.accentColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: context.accentColor, size: 14),
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
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          controller: _searchController,
          onChanged: (_) => _applyFilters(),
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Cari kode, nama, atau IP gateway...",
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 12),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.textSecondary,
              size: 18,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.textSecondary,
                      size: 16,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterChips.map((chip) {
          final isActive = _activeFilter == chip;
          final Color chipColor = chip == 'Semua'
              ? context.accentColor
              : chip == 'FO'
              ? const Color(0xFF29B6F6)
              : chip == 'VSAT'
              ? const Color(0xFFFFB74D)
              : chip == 'GSM'
              ? const Color(0xFFFF7043)
              : const Color(0xFFAB47BC);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  _activeFilter = chip;
                  _applyFilters();
                }),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? chipColor : chipColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? chipColor : chipColor.withOpacity(0.25),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: chipColor.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        chip,
                        style: TextStyle(
                          color: isActive ? context.primaryColor : chipColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // LOADING STATE
  // ==========================================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
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
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.borderColor),
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 40,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Tidak Ada Hasil",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _activeFilter != 'Semua'
                ? "Coba ubah filter atau kata pencarian"
                : "Belum ada data toko tersedia",
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          if (_activeFilter != 'Semua' ||
              _searchController.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeFilter = 'Semua';
                  _searchController.clear();
                });
                _applyFilters();
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: context.accentColor,
                size: 16,
              ),
              label: Text(
                "Reset Filter",
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // STORE LIST — Grid 2 kolom di desktop, 1 di mobile
  // ==========================================
  Widget _buildStoreList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildStoreCard(_filteredStores[index]),
      ),
    );
  }

  // ==========================================
  // STORE CARD — Premium redesign
  // Accent bar kiri + glow radial + kode badge + chevron styled
  // ==========================================
  Widget _buildStoreCard(StoreModel store) {
    String mainType = (store.connectionType ?? "-").trim().toUpperCase();
    String backupType = (store.connectionBackup ?? "").trim().toUpperCase();
    bool hasIpVsat = store.ipVsat?.isNotEmpty == true;
    if ((backupType.isEmpty || backupType == "-") && hasIpVsat) {
      backupType = "VSAT";
    }
    bool hasBackup = backupType.isNotEmpty && backupType != "-";

    final Color cardAccent = _connColor(store.connectionType ?? '');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: cardAccent.withOpacity(0.06),
        highlightColor: cardAccent.withOpacity(0.03),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => StoreDetailPage(store: store)),
          );
          if (changed == true) _fetchStores();
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Radial glow kanan atas — warna sesuai koneksi
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [cardAccent.withOpacity(0.1), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Accent bar kiri vertikal
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardAccent, cardAccent.withOpacity(0.2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    // Avatar dengan warna koneksi
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardAccent.withOpacity(0.25)),
                      ),
                      child: Center(
                        child: Text(
                          store.storeCode.isNotEmpty
                              ? store.storeCode.substring(0, 1).toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: cardAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Kode badge + Nama
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cardAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: cardAccent.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  store.storeCode,
                                  style: TextStyle(
                                    color: cardAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  store.storeName,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // IP Gateway
                          Row(
                            children: [
                              Icon(
                                Icons.router_outlined,
                                size: 10,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                store.ipGateway?.isNotEmpty == true
                                    ? store.ipGateway!
                                    : "—",
                                style: TextStyle(
                                  color: store.ipGateway?.isNotEmpty == true
                                      ? context.textSecondary
                                      : context.textSecondary.withOpacity(0.4),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),

                          // Connection badges
                          Wrap(
                            spacing: 5,
                            runSpacing: 3,
                            children: [
                              if (mainType.isNotEmpty && mainType != "-")
                                _buildConnectionBadge(mainType),
                              if (hasBackup) _buildConnectionBadge(backupType),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Chevron styled
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionBadge(String label) {
    if (label.isEmpty || label == "-") return const SizedBox.shrink();
    final color = _connColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ==========================================
  // DRAWER
  // ==========================================
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Icon(
                Icons.store_outlined,
                color: context.accentColor,
                size: 20,
              ),
              title: Text(
                'Data Toko',
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
