import 'package:flutter/material.dart';
import '../../../layout/main_layout.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/globals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import 'admin_panel_controller.dart';
import 'admin_panel_widgets.dart';

/// AdminPanelPage — thin UI page untuk Control Center.
///
/// Lokasi: features/profile/presentation/admin_panel_page.dart
///
/// Arsitektur:
///   Page (UI) → Controller (logic) → Repository (data)
///
/// Page ini hanya:
///   - Render UI berdasarkan state dari AdminPanelController
///   - Listen notifikasi dan tampilkan snackbar
///   - Delegate semua aksi ke controller
///
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AdminPanelController _ctrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ctrl = AdminPanelController();
    _ctrl.addListener(_onControllerChanged);
    _ctrl.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.markAnimationsReady();
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// React to controller state changes — show notifications.
  void _onControllerChanged() {
    if (!mounted) return;

    final notification = _ctrl.pendingNotification;
    if (notification != null) {
      _ctrl.clearNotification();
    }

    setState(() {});

    if (notification != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CustomSnackBar.showFromKey(
          globalMessengerKey,
          notification.message,
          notification.color,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: AnimatedOpacity(
        opacity: _ctrl.animationsReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset:
              _ctrl.animationsReady ? Offset.zero : const Offset(0, 0.03),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
            body: Column(
              children: [
                _buildTabBar(),
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
    final accent = context.accentColor;
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: context.isDesktop
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
              onTap: _ctrl.fetchAll,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
  // TAB BAR
  // ══════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
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
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1 — PENGGUNA AKTIF
  // ══════════════════════════════════════════════════════════

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row ──
          Row(
            children: [
              AdminStatChip(
                label: "Total",
                value: _ctrl.totalUsers.toString(),
                color: context.accentColor,
                icon: Icons.people_outline,
              ),
              const SizedBox(width: 8),
              AdminStatChip(
                label: "Online",
                value: _ctrl.onlineCount.toString(),
                color: const Color(0xFF00E676),
                icon: Icons.circle,
              ),
              const SizedBox(width: 8),
              AdminStatChip(
                label: "Offline",
                value: _ctrl.offlineCount.toString(),
                color: context.textSecondary,
                icon: Icons.circle_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── User list card ──
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
                  AdminListHeader(
                    title: "Daftar Pengguna",
                    subtitle: "Semua akun yang terdaftar di sistem",
                    icon: Icons.manage_accounts_outlined,
                    iconColor: context.accentColor,
                    count: "${_ctrl.filteredUsers.length} Akun",
                    countColor: context.accentColor,
                    searchCtrl: _ctrl.searchUserCtrl,
                    onSearch: _ctrl.filterUsers,
                    onRefresh: _ctrl.fetchUsers,
                  ),
                  Expanded(
                    child: _ctrl.isLoadingUsers
                        ? const AdminLoadingWidget(
                            message: "Memuat data pengguna...")
                        : _ctrl.filteredUsers.isEmpty
                            ? const AdminEmptyWidget(
                                icon: Icons.person_search_outlined,
                                message: "Tidak ada pengguna ditemukan",
                              )
                            : RefreshIndicator(
                                color: context.accentColor,
                                onRefresh: _ctrl.fetchUsers,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 4, 0, 16),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _ctrl.filteredUsers.length,
                                  itemBuilder: (_, i) => AdminUserTile(
                                    user: _ctrl.filteredUsers[i],
                                    isLast:
                                        i == _ctrl.filteredUsers.length - 1,
                                  ),
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

  // ══════════════════════════════════════════════════════════
  // TAB 2 — LOG AKTIVITAS
  // ══════════════════════════════════════════════════════════

  Widget _buildLogsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // ── Filter chips ──
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AdminPanelController.logFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final f = AdminPanelController.logFilters[i];
                return AdminLogFilterChip(
                  label: f,
                  selected: _ctrl.selectedLogFilter == f,
                  onTap: () => _ctrl.setLogFilter(f),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Log list card ──
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
                  AdminListHeader(
                    title: "Log Aktivitas",
                    subtitle: "Riwayat 200 aksi terakhir",
                    icon: Icons.history_edu_outlined,
                    iconColor: const Color(0xFF54C5F8),
                    count: "${_ctrl.filteredLogs.length} Log",
                    countColor: const Color(0xFF54C5F8),
                    searchCtrl: _ctrl.searchLogCtrl,
                    onSearch: _ctrl.filterLogs,
                    onRefresh: _ctrl.fetchLogs,
                  ),
                  Expanded(
                    child: _ctrl.isLoadingLogs
                        ? const AdminLoadingWidget(
                            message: "Memuat log aktivitas...")
                        : _ctrl.filteredLogs.isEmpty
                            ? const AdminEmptyWidget(
                                icon: Icons.history_toggle_off_outlined,
                                message: "Tidak ada log ditemukan",
                              )
                            : RefreshIndicator(
                                color: const Color(0xFF54C5F8),
                                onRefresh: _ctrl.fetchLogs,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 4, 0, 16),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _ctrl.filteredLogs.length,
                                  itemBuilder: (_, i) => AdminLogTile(
                                    log: _ctrl.filteredLogs[i],
                                    isLast:
                                        i == _ctrl.filteredLogs.length - 1,
                                  ),
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
}
