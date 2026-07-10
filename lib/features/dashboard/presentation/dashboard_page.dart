import 'package:flutter/material.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../auth/domain/auth_state.dart';
import 'dashboard_controller.dart';
import '../../ticket/presentation/controllers/worker_controller.dart';
import 'widgets/welcome_section.dart';
import 'widgets/stats_grid.dart';
import 'widgets/ticket_chart_section.dart';
import 'widgets/ranking_section.dart';
import 'widgets/provider_chart_section.dart';
import 'widgets/recent_ticket_table.dart';
import '../../../core/widgets/page_entry_transition.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _ctrl = DashboardController();

  // UI-only animation flags
  bool _showAppBar = false;
  bool _showWelcome = false;
  bool _showStats = false;
  bool _showAnalytics = false;
  bool _showProviderChart = false;
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (AuthState.instance.showWelcomeOnDashboard) {
        AuthState.instance.showWelcomeOnDashboard = false;
        CustomSnackBar.success("Selamat datang, ${AuthState.instance.name}!");
        WorkerController.autoStartWorkerIfNeeded();
      }

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
        if (mounted) setState(() => _showAnalytics = true);
      });
      Future.delayed(const Duration(milliseconds: 760), () {
        if (mounted) setState(() => _showProviderChart = true);
      });
      Future.delayed(const Duration(milliseconds: 940), () {
        if (mounted) setState(() => _showRecent = true);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: _ctrl.isLoading
          ? _buildLoadingScreen()
          : PageEntryTransition(
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
                      padding: EdgeInsets.fromLTRB(
                        context.pagePaddingH,
                        context.scaledPadding(20),
                        context.pagePaddingH,
                        context.scaledPadding(40),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Welcome section ──
                          _animSection(
                            visible: _showWelcome,
                            child: WelcomeSection(
                              timeString: _ctrl.timeString,
                              dateString: _ctrl.dateString,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Stats grid ──
                          _animSection(
                            visible: _showStats,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(
                                  'STATISTIK JARINGAN',
                                  Icons.analytics_outlined,
                                ),
                                const SizedBox(height: 12),
                                StatsGrid(
                                  totalStores: _ctrl.totalStores,
                                  foStores: _ctrl.foStores,
                                  backupVsat: _ctrl.backupVsat,
                                  singleVsat: _ctrl.singleVsat,
                                  gsmStores: _ctrl.gsmStores,
                                  xlStores: _ctrl.xlStores,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Analytics: Chart + Ranking ──
                          _animSection(
                            visible: _showAnalytics,
                            child: _buildAnalyticsRow(context),
                          ),
                          const SizedBox(height: 24),

                          // ── Provider disruption chart ──
                          _animSection(
                            visible: _showProviderChart,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(
                                  'ANALISIS PROVIDER',
                                  Icons.router_outlined,
                                ),
                                const SizedBox(height: 12),
                                ProviderChartSection(ctrl: _ctrl),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Recent critical tickets ──
                          _animSection(
                            visible: _showRecent,
                            child: RecentTicketTable(ctrl: _ctrl),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Analytics row: Chart (70%) + Ranking (30%) ────────────────
  Widget _buildAnalyticsRow(BuildContext context) {
    final isWide = context.screenWidth >= 1000;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: TicketChartSection(ctrl: _ctrl)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: RankingSection(ctrl: _ctrl)),
        ],
      );
    }

    // Stacked for tablet/mobile
    return Column(
      children: [
        TicketChartSection(ctrl: _ctrl),
        const SizedBox(height: 16),
        RankingSection(ctrl: _ctrl),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _animSection({
    required bool visible,
    required Widget child,
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
              'MEMUAT DATA...',
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
    final isDesktop = context.isDesktop;
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: isDesktop
          ? null
          : const Center(child: AppHamburgerButton()),
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Builder(
        builder: (ctx) {
          final isWide = MediaQuery.of(ctx).size.width > 600;
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
              if (isWide)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EDP NETOPS',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      '  DASHBOARD',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EDP NETOPS',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'DASHBOARD',
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
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _ctrl.fetchData,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.accentColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: context.accentColor,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: context.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
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
}
