import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/utils/export_helper.dart';
import '../../../layout/main_layout.dart';
import 'ticket_controller.dart';
import '../domain/ticket_model.dart';
import 'widgets/ticket_card.dart';
import 'widgets/ticket_dialogs.dart';
import 'widgets/ticket_filter_panel.dart';
import 'widgets/ticket_ranking_tab.dart';
import 'widgets/ticket_skeleton.dart';

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
  bool _animationsReady = false;

  List<TicketModel> get _filtered => _ctrl.filteredTickets;
  bool get _isLoading => _ctrl.isLoading;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ctrl.searchCtrl.addListener(_ctrl.applyFilter);
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    _ctrl.loadTickets();
    _ctrl.fetchWorkerStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _loadTickets() => _ctrl.loadTickets();

  Future<void> _updateTicket({
    required String id,
    required String nomorTiket,
    required String status,
  }) async {
    try {
      await _ctrl.updateTicket(id: id, nomorTiket: nomorTiket, status: status);
      if (mounted) {
        CustomSnackBar.show(context, 'Tiket berhasil diperbarui!', Colors.green);
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
      if (mounted) CustomSnackBar.show(context, 'Tiket dihapus.', Colors.orange);
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
      body: AnimatedOpacity(
        opacity: _animationsReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _isLoading
                      ? const RankingListSkeleton()
                      : TicketRankingTab(
                          ctrl: _ctrl,
                          onFilterChanged: () => setState(() {}),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final isDesktop = context.isDesktop;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16, right: 16, bottom: 10,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            _iconBtn(
              icon: Icons.menu_rounded,
              onTap: () => MainLayout.scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: context.accentColor.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HISTORY TIKET',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    'Rekap & monitoring tiket provider',
                    style: TextStyle(color: context.textSecondary, fontSize: isMobile ? 9 : 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (RoleHelper.isAdminOrAbove) ...[
            _buildWorkerStatusIndicator(),
            const SizedBox(width: 8),
          ],
          _actionBtn(
            icon: Icons.download_rounded,
            label: 'Export',
            color: const Color(0xFF81C784),
            onTap: _exportExcel,
          ),
          const SizedBox(width: 6),
          _actionBtn(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            color: context.accentColor,
            onTap: _loadTickets,
          ),
        ],
      ),
    );
  }


  Widget _buildWorkerStatusIndicator() {
    final statusMap = _ctrl.workerStatus;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_ctrl.isWorkerLoading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    void showWorkerManagerDialog() {
      showDialog(
        context: context,
        builder: (ctx) {
          final isUnknown = statusMap == null;
          final status = isUnknown ? 'unknown' : (statusMap['status']?.toString().toLowerCase() ?? 'idle');
          final lastSuccessStr = !isUnknown && statusMap['last_success'] != null
              ? DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(statusMap['last_success']).toLocal())
              : 'Belum pernah';
          final lastRunStr = !isUnknown && statusMap['last_run'] != null
              ? DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(statusMap['last_run']).toLocal())
              : 'Belum pernah';
          final errorMsg = !isUnknown ? (statusMap['error_message']?.toString() ?? '') : '';
          final processedCount = !isUnknown ? (statusMap['processed_count']?.toString() ?? '0') : '0';

          // Tentukan apakah worker hidup (idle/running/success/error) atau mati (unknown)
          final bool isWorkerAlive = !isUnknown && status != 'unknown';
          final bool isRunning = status == 'running';

          Color statusColor;
          String statusText;
          IconData statusIcon;

          switch (status) {
            case 'running':
              statusColor = const Color(0xFFFFB74D);
              statusText = 'RUNNING';
              statusIcon = Icons.sync_rounded;
              break;
            case 'success':
              statusColor = const Color(0xFF81C784);
              statusText = 'ACTIVE';
              statusIcon = Icons.check_circle_rounded;
              break;
            case 'error':
              statusColor = const Color(0xFFE57373);
              statusText = 'ERROR';
              statusIcon = Icons.error_rounded;
              break;
            case 'idle':
              statusColor = Colors.blue;
              statusText = 'IDLE';
              statusIcon = Icons.pause_circle_rounded;
              break;
            case 'unknown':
            default:
              statusColor = Colors.grey;
              statusText = 'OFFLINE';
              statusIcon = Icons.power_settings_new_rounded;
              break;
          }

          // ── Helper: Buat tombol aksi dengan ikon ──
          Widget actionTile({
            required IconData icon,
            required String label,
            required Color color,
            required VoidCallback onTap,
          }) {
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            title: Row(
              children: [
                Icon(Icons.settings_suggest_rounded, color: context.accentColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Worker Manager',
                    style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                // Status badge kecil di title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol X merah di pojok kanan atas
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(16),
                    hoverColor: Colors.red.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Info Detail Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.schedule_rounded, 'Terakhir Run', lastRunStr),
                        const SizedBox(height: 6),
                        _infoRow(Icons.check_circle_outline_rounded, 'Terakhir Sukses', lastSuccessStr),
                        const SizedBox(height: 6),
                        _infoRow(Icons.sync_rounded, 'Tiket Diproses', '$processedCount tiket'),
                        const SizedBox(height: 6),
                        _infoRow(Icons.timer_rounded, 'Interval Sync', '10 menit'),
                        const SizedBox(height: 6),
                        _infoRow(Icons.access_time_rounded, 'Jam Operasional', '06:00 - 22:30'),
                      ],
                    ),
                  ),

                  // ── Error Box (jika ada) ──
                  if (status == 'error' && errorMsg.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(maxHeight: 80),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE57373).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE57373).withOpacity(0.2)),
                      ),
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFE57373)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                errorMsg,
                                style: const TextStyle(color: Color(0xFFE57373), fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Tombol Aksi (Kontekstual — 2 baris) ──
                  // Baris 1: Start / Stop / Restart (Hanya untuk Komputer Utama/Host)
                  if (_ctrl.isHostMachine) ...[
                    Row(
                      children: [
                        // Start: tampil hanya jika worker MATI atau UNKNOWN
                        if (!isWorkerAlive || status == 'error')
                          actionTile(
                            icon: Icons.play_arrow_rounded,
                            label: 'Start',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.pop(ctx);
                              _ctrl.startBackgroundWorker();
                            },
                          ),
                        if (!isWorkerAlive || status == 'error') const SizedBox(width: 8),

                        // Stop: tampil hanya jika worker HIDUP (idle/running/success)
                        if (isWorkerAlive && !isRunning)
                          actionTile(
                            icon: Icons.stop_rounded,
                            label: 'Stop',
                            color: const Color(0xFFE57373),
                            onTap: () async {
                              Navigator.pop(ctx);
                              // Konfirmasi sebelum stop
                              final confirmed = await showConfirmDialog(
                                context,
                                title: 'Hentikan Worker?',
                                message: 'Worker akan dinonaktifkan dan sinkronisasi otomatis akan terhenti.',
                                confirmLabel: 'Hentikan',
                                cancelLabel: 'Batal',
                                icon: Icons.stop_circle_outlined,
                                isDanger: true,
                              );
                              if (confirmed == true) {
                                _ctrl.stopBackgroundWorker();
                              }
                            },
                          ),
                        if (isWorkerAlive && !isRunning) const SizedBox(width: 8),

                        // Restart: tampil hanya jika worker HIDUP
                        if (isWorkerAlive)
                          actionTile(
                            icon: Icons.restart_alt_rounded,
                            label: 'Restart',
                            color: const Color(0xFFFFB74D),
                            onTap: () async {
                              Navigator.pop(ctx);
                              CustomSnackBar.info('Merestart worker...');
                              await _ctrl.stopBackgroundWorker();
                              await Future.delayed(const Duration(seconds: 2));
                              await _ctrl.startBackgroundWorker();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    // Tampilan informatif jika diakses dari komputer Client
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.borderColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: context.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kontrol worker (Start/Stop/Restart) hanya dapat diakses dari Komputer Utama.',
                              style: TextStyle(color: context.textSecondary, fontSize: 10, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Baris 2: Trigger Sync / Cek Status
                  Row(
                    children: [
                      // Trigger Sync: tampil hanya jika worker HIDUP dan tidak sedang sync
                      if (isWorkerAlive && !isRunning)
                        actionTile(
                          icon: Icons.sync_rounded,
                          label: 'Sync Manual',
                          color: const Color(0xFF81C784),
                          onTap: () {
                            Navigator.pop(ctx);
                            _ctrl.triggerWorkerSync();
                          },
                        ),
                      if (isWorkerAlive && !isRunning) const SizedBox(width: 8),

                      // Cek Status: selalu tampil
                      actionTile(
                        icon: Icons.refresh_rounded,
                        label: 'Cek Status',
                        color: context.accentColor,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _ctrl.fetchWorkerStatus();
                          CustomSnackBar.success('Status worker diperbarui.');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (statusMap == null) {
      return Tooltip(
        message: 'Status worker tidak aktif atau mati. Klik untuk mengelola.',
        child: InkWell(
          onTap: showWorkerManagerDialog,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline_rounded, size: 12, color: Colors.grey),
                if (!isMobile) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'Worker: Unknown',
                    style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final status = statusMap['status']?.toString().toLowerCase() ?? 'idle';
    final lastSuccessStr = statusMap['last_success'] != null
        ? DateFormat('dd/MM HH:mm').format(DateTime.parse(statusMap['last_success']).toLocal())
        : 'Belum pernah';

    Color color;
    IconData icon;
    String label;
    String tooltipMsg;

    switch (status) {
      case 'running':
        color = const Color(0xFFFFB74D); // Orange
        icon = Icons.sync_rounded;
        label = 'Running';
        tooltipMsg = 'Worker sedang memproses sinkronisasi tiket dari email...';
        break;
      case 'success':
        color = const Color(0xFF81C784); // Green
        icon = Icons.check_circle_outline_rounded;
        label = 'Active';
        tooltipMsg = 'Terakhir sukses: $lastSuccessStr. Worker aktif & sehat.';
        break;
      case 'error':
        color = const Color(0xFFE57373); // Red
        icon = Icons.error_outline_rounded;
        label = 'Error';
        tooltipMsg = 'Worker terhenti dengan error. Klik untuk info/menyalakan kembali.';
        break;
      case 'idle':
      default:
        color = Colors.blue;
        icon = Icons.play_arrow_rounded;
        label = 'Idle';
        tooltipMsg = 'Worker stand-by. Terakhir sukses: $lastSuccessStr. Klik untuk mengelola.';
        break;
    }

    return Tooltip(
      message: tooltipMsg,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showWorkerManagerDialog,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 6),
                Text(
                  'Worker: $label',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget: baris info dengan ikon untuk dialog Worker Manager
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: context.textSecondary, fontSize: 11)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor.withOpacity(0.5)),
          ),
          child: Icon(icon, color: context.textPrimary, size: 16),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, color: color, size: 13),
              if (!isMobile) ...[
                const SizedBox(width: 5),
                Text(label, style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
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
        labelStyle: TextStyle(fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

    return Column(
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
                  ? _buildDesktopTable()
                  : _buildMobileList(),
        ),
        // ── Footer info bar ──
        if (_filtered.isNotEmpty)
          _buildFooterBar(isDesktop),
      ],
    );
  }

  Widget _buildFooterBar(bool isDesktop) {
    final total = _ctrl.allTickets.length;
    final shown = _filtered.length;
    final isFiltered = shown != total;

    final open = _filtered.where((t) => t.status == 'Open').length;
    final prog = _filtered.where((t) => t.status == 'In Progress').length;
    final resolved = _filtered.where((t) => t.status == 'Resolved').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(color: context.borderColor.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 12, color: context.textSecondary),
          const SizedBox(width: 6),
          Text(
            isFiltered
                ? 'Menampilkan $shown dari $total tiket'
                : 'Total $total tiket',
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 16),
            _footerDot(const Color(0xFFE57373), 'Open $open'),
            const SizedBox(width: 10),
            _footerDot(const Color(0xFFFFB74D), 'Progress $prog'),
            const SizedBox(width: 10),
            _footerDot(const Color(0xFF81C784), 'Resolved $resolved'),
          ],
        ],
      ),
    );
  }

  Widget _footerDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Desktop: enterprise table with sticky header ──────────────────────────

  Widget _buildDesktopTable() {
    return Column(
      children: [
        TicketTableHeader(ctrl: _ctrl),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _filtered.length,
            itemBuilder: (_, i) => TicketCard(
              ticket: _filtered[i],
              index: i,
              onDetail: () => showTicketDetailDialog(
                context,
                ticket: _filtered[i],
                onUpdate: _updateTicket,
              ),
              onUpdate: () => showTicketUpdateDialog(
                context,
                ticket: _filtered[i],
                onUpdate: _updateTicket,
              ),
              onDelete: () => _deleteTicket(_filtered[i].id),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: compact card list ─────────────────────────────────────────────

  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        context.pagePaddingH, 8, context.pagePaddingH, 24,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => TicketCard(
        ticket: _filtered[i],
        index: i,
        onDetail: () => showTicketDetailDialog(
          context,
          ticket: _filtered[i],
          onUpdate: _updateTicket,
        ),
        onUpdate: () => showTicketUpdateDialog(
          context,
          ticket: _filtered[i],
          onUpdate: _updateTicket,
        ),
        onDelete: () => _deleteTicket(_filtered[i].id),
      ),
    );
  }
}
