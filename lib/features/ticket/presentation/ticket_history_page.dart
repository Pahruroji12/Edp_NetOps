import 'package:flutter/material.dart';
import '../../../core/widgets/page_entry_transition.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/custom_snackbar.dart';

import '../../../core/utils/export_helper.dart';
import 'ticket_controller.dart';
import 'controllers/worker_controller.dart';
import '../domain/ticket_model.dart';
import 'widgets/ticket_dialogs.dart';
import 'widgets/ticket_filter_panel.dart';
import 'widgets/ticket_ranking_tab.dart';
import 'widgets/ticket_skeleton.dart';

// Newly extracted widgets
import 'widgets/ticket_history_header.dart';
import 'widgets/ticket_history_action_bar.dart';
import 'widgets/ticket_desktop_table.dart';
import 'widgets/ticket_mobile_list.dart';
import 'widgets/ticket_empty_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TicketHistoryPage — enterprise monitoring dashboard
// Hybrid responsive: desktop table / mobile card layout
// ─────────────────────────────────────────────────────────────────────────────
class TicketHistoryPage extends StatefulWidget {
  const TicketHistoryPage({super.key});
  @override
  State<TicketHistoryPage> createState() => _TicketHistoryPageState();
}

class _TicketHistoryPageState extends State<TicketHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _ctrl = TicketController();
  final _workerCtrl = WorkerController();

  List<TicketModel> get _filtered => _ctrl.filteredTickets;
  bool get _isLoading => _ctrl.isLoading;

  void _onWorkerStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ctrl.searchCtrl.addListener(_ctrl.applyFilter);
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _workerCtrl.addListener(_onWorkerStateChanged);
    _ctrl.loadTickets();
    _workerCtrl.fetchWorkerStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrl.dispose();
    _workerCtrl.removeListener(_onWorkerStateChanged);
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _loadTickets() => _ctrl.loadTickets();

  Future<void> _updateTicket({
    required String id,
    required String nomorTiket,
    required String status,
    required String keterangan,
  }) async {
    try {
      await _ctrl.updateTicket(
        id: id,
        nomorTiket: nomorTiket,
        status: status,
        keterangan: keterangan,
      );
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Tiket berhasil diperbarui!',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, 'Gagal update: $e', Colors.red);
    }
  }

  Future<void> _deleteTicket(String id) async {
    final confirm = await showTicketDeleteConfirm(context);
    if (!confirm) return;
    try {
      await _ctrl.deleteTicket(id);
      if (mounted)
        CustomSnackBar.show(context, 'Tiket dihapus.', Colors.orange);
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, 'Gagal hapus: $e', Colors.red);
    }
  }

  Future<void> _exportExcel() async {
    try {
      final message = await ExportHelper.exportTicketHistory(
        filtered: _ctrl.filteredAsMaps,
        allTickets: _ctrl.allAsMaps,
        ranking: _ctrl.buildRanking(_ctrl.allTickets),
      );
      if (mounted) CustomSnackBar.show(context, message, Colors.green);
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, 'Gagal export: $e', Colors.red);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: Column(
        children: [
          TicketHistoryHeader(
            ctrl: _ctrl,
            workerCtrl: _workerCtrl,
            onExport: _exportExcel,
            onRefresh: _loadTickets,
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _isLoading
                    ? const RankingListSkeleton()
                    : PageEntryTransition(
                        child: TicketRankingTab(
                          ctrl: _ctrl,
                          onFilterChanged: () => setState(() {}),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TabBar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Container(
      color: context.cardColor,
      child: TabBar(
        controller: _tabController,
        labelColor: context.accentColor,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: context.accentColor,
        indicatorWeight: 2,
        labelStyle: TextStyle(
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
        dividerHeight: 0,
        labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 16),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_outlined, size: 14),
                const SizedBox(width: 6),
                const Text('History Tiket'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_filtered.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bar_chart_outlined, size: 14),
                const SizedBox(width: 6),
                const Text('Sering Gangguan'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_ctrl.buildRanking(_ctrl.allTickets).length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab History ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return TicketListSkeleton(isTableMode: context.screenWidth >= 1200);
    }

    final isDesktop = context.screenWidth >= 1200;

    return PageEntryTransition(
      child: Column(
        children: [
          TicketFilterPanel(
            ctrl: _ctrl,
            allTickets: _ctrl.allTickets,
            onChanged: () => setState(() {}),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const TicketEmptyState()
                : isDesktop
                ? TicketDesktopTable(
                    ctrl: _ctrl,
                    filtered: _filtered,
                    onDetail: (ticket) => showTicketDetailDialog(
                      context,
                      ticket: ticket,
                      onUpdate: _updateTicket,
                    ),
                    onUpdate: (ticket) => showTicketUpdateDialog(
                      context,
                      ticket: ticket,
                      onUpdate: _updateTicket,
                    ),
                    onDelete: (ticket) => _deleteTicket(ticket.id),
                  )
                : TicketMobileList(
                    filtered: _filtered,
                    onDetail: (ticket) => showTicketDetailDialog(
                      context,
                      ticket: ticket,
                      onUpdate: _updateTicket,
                    ),
                    onUpdate: (ticket) => showTicketUpdateDialog(
                      context,
                      ticket: ticket,
                      onUpdate: _updateTicket,
                    ),
                    onDelete: (ticket) => _deleteTicket(ticket.id),
                  ),
          ),
          if (_filtered.isNotEmpty)
            TicketHistoryActionBar(
              ctrl: _ctrl,
              filtered: _filtered,
              isDesktop: isDesktop,
            ),
        ],
      ),
    );
  }
}
