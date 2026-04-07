import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/app_colors.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  bool _animationsReady = false;
  bool _isLoadingUsers = false;
  bool _isLoadingLogs = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _logs = [];

  final _searchUserCtrl = TextEditingController();
  final _searchLogCtrl = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _filteredLogs = [];

  // Filter log
  String _selectedLogFilter = 'SEMUA';
  final List<String> _logFilters = [
    'SEMUA',
    'LOGIN',
    'LOGOUT',
    'TAMBAH',
    'EDIT',
    'HAPUS',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchUserCtrl.dispose();
    _searchLogCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // DATA
  // ══════════════════════════════════════════════════════════

  Future<void> _fetchAll() async {
    await Future.wait([_fetchUsers(), _fetchLogs()]);
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .order('is_online', ascending: false);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(res);
          _filterUsers(_searchUserCtrl.text);
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Gagal muat pengguna: $e",
          context.dangerColor,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchLogs() async {
    if (!mounted) return;
    setState(() => _isLoadingLogs = true);
    try {
      final res = await _supabase
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(res);
          _filterLogs(_searchLogCtrl.text);
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, "Gagal muat log: $e", context.dangerColor);
      }
    } finally {
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }

  void _filterUsers(String q) {
    setState(() {
      if (q.isEmpty) {
        _filteredUsers = _users;
      } else {
        final lower = q.toLowerCase();
        _filteredUsers = _users.where((u) {
          return (u['nama'] ?? '').toString().toLowerCase().contains(lower) ||
              (u['nik'] ?? '').toString().toLowerCase().contains(lower) ||
              (u['role'] ?? '').toString().toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  void _filterLogs(String q) {
    setState(() {
      List<Map<String, dynamic>> base = _logs;
      if (_selectedLogFilter != 'SEMUA') {
        base = base
            .where(
              (l) => (l['action_type'] ?? '').toString().toUpperCase().contains(
                _selectedLogFilter,
              ),
            )
            .toList();
      }
      if (q.isNotEmpty) {
        final lower = q.toLowerCase();
        base = base.where((l) {
          return (l['description'] ?? '').toString().toLowerCase().contains(
                lower,
              ) ||
              (l['user_name'] ?? '').toString().toLowerCase().contains(lower);
        }).toList();
      }
      _filteredLogs = base;
    });
  }

  // ══════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: AnimatedOpacity(
        opacity: _animationsReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _animationsReady ? Offset.zero : const Offset(0, 0.03),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
            body: Column(
              children: [
                // ── Tab Bar ──────────────────────────────────
                Container(
                  color: context.primaryColor,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      padding: const EdgeInsets.all(4),
                      labelPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.accentColor,
                            context.accentColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: context.accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: context.textSecondary,
                      tabs: const [
                        Tab(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 16),
                              SizedBox(width: 6),
                              Text("Pengguna Aktif"),
                            ],
                          ),
                        ),
                        Tab(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_edu_outlined, size: 16),
                              SizedBox(width: 6),
                              Text("Log Aktivitas"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Content ───────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildUsersTab(), _buildLogsTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ══════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final accent = context.accentColor; // Ungu — warna khas Control Center
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.primaryColor,
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "CONTROL CENTER",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Refresh button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _fetchAll,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
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
          const SizedBox(width: 8),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                accent.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1 — PENGGUNA AKTIF
  // ══════════════════════════════════════════════════════════

  Widget _buildUsersTab() {
    final onlineCount = _users.where((u) => u['is_online'] == true).length;
    final offlineCount = _users.length - onlineCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row ───────────────────────────────────
          Row(
            children: [
              _buildStatChip(
                label: "Total",
                value: _users.length.toString(),
                color: context.accentColor,
                icon: Icons.people_outline,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: "Online",
                value: onlineCount.toString(),
                color: const Color(0xFF00E676),
                icon: Icons.circle,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: "Offline",
                value: offlineCount.toString(),
                color: context.textSecondary,
                icon: Icons.circle_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Search + list card ───────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  _buildListHeader(
                    title: "Daftar Pengguna",
                    subtitle: "Semua akun yang terdaftar di sistem",
                    icon: Icons.manage_accounts_outlined,
                    iconColor: context.accentColor,
                    count: "${_filteredUsers.length} Akun",
                    countColor: context.accentColor,
                    searchCtrl: _searchUserCtrl,
                    onSearch: _filterUsers,
                    onRefresh: _fetchUsers,
                  ),
                  // Content
                  Expanded(
                    child: _isLoadingUsers
                        ? _buildLoadingWidget("Memuat data pengguna...")
                        : _filteredUsers.isEmpty
                        ? _buildEmptyWidget(
                            icon: Icons.person_search_outlined,
                            message: "Tidak ada pengguna ditemukan",
                          )
                        : RefreshIndicator(
                            color: context.accentColor,
                            onRefresh: _fetchUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (_, i) =>
                                  _buildUserTile(_filteredUsers[i], i),
                            ),
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

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final isOnline = user['is_online'] == true;
    final nama = user['nama'] ?? 'Unknown';
    final nik = user['nik'] ?? '-';
    final role = (user['role'] ?? 'user').toString().toUpperCase();
    final isLast = index == _filteredUsers.length - 1;

    Color roleColor;
    IconData roleIcon;
    if (role == 'ADMINISTRATOR') {
      roleColor = const Color(0xFFFF6B6B);
      roleIcon = Icons.admin_panel_settings_outlined;
    } else if (role == 'ADMIN') {
      roleColor = const Color(0xFFFFB347);
      roleIcon = Icons.manage_accounts_outlined;
    } else {
      roleColor = context.accentColor;
      roleIcon = Icons.person_outline;
    }

    final parts = nama.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : nama.isNotEmpty
        ? nama[0].toUpperCase()
        : 'U';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: roleColor.withOpacity(0.25)),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(roleIcon, size: 10, color: roleColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 11,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          nik,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Role badge + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF00E676)
                              : context.textSecondary.withOpacity(0.4),
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00E676,
                                    ).withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF00E676)
                              : context.textSecondary.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: context.borderColor,
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2 — LOG AKTIVITAS
  // ══════════════════════════════════════════════════════════

  Widget _buildLogsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _logFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final f = _logFilters[i];
                final selected = _selectedLogFilter == f;
                final chipColor = _logFilterColor(f);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedLogFilter = f);
                    _filterLogs(_searchLogCtrl.text);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? chipColor.withOpacity(0.15)
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? chipColor.withOpacity(0.5)
                            : context.borderColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: selected ? chipColor : context.textSecondary,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Log list card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildListHeader(
                    title: "Log Aktivitas",
                    subtitle: "Riwayat 200 aksi terakhir",
                    icon: Icons.history_edu_outlined,
                    iconColor: const Color(0xFF54C5F8),
                    count: "${_filteredLogs.length} Log",
                    countColor: const Color(0xFF54C5F8),
                    searchCtrl: _searchLogCtrl,
                    onSearch: _filterLogs,
                    onRefresh: _fetchLogs,
                  ),
                  Expanded(
                    child: _isLoadingLogs
                        ? _buildLoadingWidget("Memuat log aktivitas...")
                        : _filteredLogs.isEmpty
                        ? _buildEmptyWidget(
                            icon: Icons.history_toggle_off_outlined,
                            message: "Tidak ada log ditemukan",
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF54C5F8),
                            onRefresh: _fetchLogs,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filteredLogs.length,
                              itemBuilder: (_, i) =>
                                  _buildLogTile(_filteredLogs[i], i),
                            ),
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

  Widget _buildLogTile(Map<String, dynamic> log, int index) {
    final action = (log['action_type'] ?? '').toString().toUpperCase();
    final desc = log['description'] ?? 'Tidak ada deskripsi';
    final userName = log['user_name'] ?? '-';
    final userRole = (log['user_role'] ?? '').toString().toUpperCase();
    final isLast = index == _filteredLogs.length - 1;

    final rawDate = log['created_at'] != null
        ? DateTime.parse(log['created_at']).toLocal()
        : DateTime.now();
    final dateStr =
        "${rawDate.day.toString().padLeft(2, '0')}/${rawDate.month.toString().padLeft(2, '0')}/${rawDate.year}";
    final timeStr =
        "${rawDate.hour.toString().padLeft(2, '0')}:${rawDate.minute.toString().padLeft(2, '0')}";

    final color = _logFilterColor(action);
    final icon = _logIcon(action);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 11,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            "$userName · $userRole",
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Waktu + badge — SizedBox 68px agar tidak dorong Expanded kiri
              SizedBox(
                width: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        action.length > 8 ? action.substring(0, 6) : action,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: context.textSecondary.withOpacity(0.5),
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: context.borderColor,
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String count,
    required Color countColor,
    required TextEditingController searchCtrl,
    required void Function(String) onSearch,
    required Future<void> Function() onRefresh,
  }) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 420;

        final titleWidget = Row(
          mainAxisSize: MainAxisSize.max, // max agar ikuti constraint Expanded
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withOpacity(0.25)),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 10),
            // Flexible agar teks tidak meluber saat ruang sempit
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final badgeWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: countColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: countColor.withOpacity(0.3)),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: countColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

        final searchWidget = SizedBox(
          width: isWide ? 180 : double.infinity,
          height: 36,
          child: Theme(
            data: Theme.of(context).copyWith(
              // Warna teks ter-select (blok)
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: context.accentColor,
                selectionColor: context.accentColor.withOpacity(0.3),
                selectionHandleColor: context.accentColor,
              ),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: TextStyle(color: context.textPrimary, fontSize: 12),
              cursorColor: context.accentColor,
              decoration: InputDecoration(
                hintText: "Cari...",
                hintStyle: TextStyle(
                  color: context.textSecondary.withOpacity(0.5),
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: context.textSecondary,
                ),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 14,
                          color: context.textSecondary,
                        ),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: EdgeInsets.zero,
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
              ),
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: context.borderColor)),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: titleWidget),
                    searchWidget,
                    const SizedBox(width: 10),
                    badgeWidget,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: titleWidget),
                        badgeWidget,
                      ],
                    ),
                    const SizedBox(height: 10),
                    searchWidget,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: context.accentColor,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: context.textSecondary.withOpacity(0.35)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _logFilterColor(String action) {
    if (action.contains('LOGIN')) return const Color(0xFF00E676);
    if (action.contains('LOGOUT')) return const Color(0xFFFFB347);
    if (action.contains('TAMBAH')) return const Color(0xFF54C5F8);
    if (action.contains('EDIT')) return context.accentColor;
    if (action.contains('HAPUS')) return const Color(0xFFFF6B6B);
    return context.accentColor;
  }

  IconData _logIcon(String action) {
    if (action.contains('LOGIN')) return Icons.login_rounded;
    if (action.contains('LOGOUT')) return Icons.logout_rounded;
    if (action.contains('TAMBAH')) return Icons.add_circle_outline;
    if (action.contains('EDIT')) return Icons.edit_outlined;
    if (action.contains('HAPUS')) return Icons.delete_outline;
    return Icons.info_outline;
  }
}
