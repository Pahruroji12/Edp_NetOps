import 'package:flutter/material.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/role_helper.dart';
import '../ticket_controller.dart';
import '../controllers/worker_controller.dart';
import '../dialogs/worker_manager_dialog.dart';

class TicketHistoryHeader extends StatelessWidget {
  final TicketController ctrl;
  final WorkerController workerCtrl;
  final VoidCallback onExport;
  final VoidCallback onRefresh;

  const TicketHistoryHeader({
    key,
    required this.ctrl,
    required this.workerCtrl,
    required this.onExport,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            const AppHamburgerButton(),
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
                      width: 6,
                      height: 6,
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
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: isMobile ? 9 : 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (RoleHelper.isAdminOrAbove) ...[
            AnimatedBuilder(
              animation: workerCtrl,
              builder: (context, _) => _buildWorkerStatusIndicator(context),
            ),
            const SizedBox(width: 8),
          ],
          _actionBtn(
            context: context,
            icon: Icons.download_rounded,
            label: 'Export',
            color: const Color(0xFF81C784),
            onTap: onExport,
          ),
          const SizedBox(width: 6),
          _actionBtn(
            context: context,
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            color: context.accentColor,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerStatusIndicator(BuildContext context) {
    final statusMap = workerCtrl.workerStatus;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (workerCtrl.isWorkerLoading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (statusMap == null) {
      return Tooltip(
        message: 'Status worker tidak aktif atau mati. Klik untuk mengelola.',
        child: InkWell(
          onTap: () => showWorkerManagerDialog(context, ticketCtrl: ctrl, workerCtrl: workerCtrl),
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
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
          onTap: () => showWorkerManagerDialog(context, ticketCtrl: ctrl, workerCtrl: workerCtrl),
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
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _actionBtn({
    required BuildContext context,
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
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: 7,
          ),
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
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
