import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../ticket_controller.dart';
import '../controllers/worker_controller.dart';

void showWorkerManagerDialog(
  BuildContext context, {
  required TicketController ticketCtrl,
  required WorkerController workerCtrl,
}) {
  showDialog(
    context: context,
    builder: (ctx) {
      // Listen to WorkerController changes inside the dialog content
      return AnimatedBuilder(
        animation: workerCtrl,
        builder: (context, _) {
          final statusMap = workerCtrl.workerStatus;
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

          Widget infoRow(IconData icon, String label, String value) {
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: context.accentColor.withOpacity(0.5), width: 3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(Icons.auto_awesome_rounded, size: 13, color: context.accentColor.withOpacity(0.7)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sistem otomatis yang membaca email notifikasi provider dan mengupdate nomor tiket secara real-time tanpa input manual.',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        infoRow(Icons.schedule_rounded, 'Terakhir Run', lastRunStr),
                        const SizedBox(height: 6),
                        infoRow(Icons.check_circle_outline_rounded, 'Terakhir Sukses', lastSuccessStr),
                        const SizedBox(height: 6),
                        infoRow(Icons.sync_rounded, 'Tiket Diproses', '$processedCount tiket'),
                        const SizedBox(height: 6),
                        infoRow(Icons.timer_rounded, 'Interval Sync', '10 menit'),
                        const SizedBox(height: 6),
                        infoRow(Icons.access_time_rounded, 'Jam Operasional', '06:00 - 22:30'),
                      ],
                    ),
                  ),
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
                  if (workerCtrl.isHostMachine) ...[
                    Row(
                      children: [
                        if (!isWorkerAlive || status == 'error')
                          actionTile(
                            icon: Icons.play_arrow_rounded,
                            label: 'Start',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.pop(ctx);
                              workerCtrl.startBackgroundWorker();
                            },
                          ),
                        if (!isWorkerAlive || status == 'error') const SizedBox(width: 8),
                        if (isWorkerAlive && !isRunning)
                          actionTile(
                            icon: Icons.stop_rounded,
                            label: 'Stop',
                            color: const Color(0xFFE57373),
                            onTap: () async {
                              Navigator.pop(ctx);
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
                                workerCtrl.stopBackgroundWorker();
                              }
                            },
                          ),
                        if (isWorkerAlive && !isRunning) const SizedBox(width: 8),
                        if (isWorkerAlive)
                          actionTile(
                            icon: Icons.restart_alt_rounded,
                            label: 'Restart',
                            color: const Color(0xFFFFB74D),
                            onTap: () async {
                              Navigator.pop(ctx);
                              CustomSnackBar.info('Merestart worker...');
                              await workerCtrl.stopBackgroundWorker();
                              await Future.delayed(const Duration(seconds: 2));
                              await workerCtrl.startBackgroundWorker();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
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
                  Row(
                    children: [
                      if (isWorkerAlive && !isRunning)
                        actionTile(
                          icon: Icons.sync_rounded,
                          label: 'Sync Manual',
                          color: const Color(0xFF81C784),
                          onTap: () {
                            Navigator.pop(ctx);
                            workerCtrl.triggerWorkerSync(onLoadTickets: ticketCtrl.loadTickets);
                          },
                        ),
                      if (isWorkerAlive && !isRunning) const SizedBox(width: 8),
                      actionTile(
                        icon: Icons.refresh_rounded,
                        label: 'Cek Status',
                        color: context.accentColor,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await workerCtrl.fetchWorkerStatus();
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
    },
  );
}
