import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/ftp_service.dart';
import '../ftp_controller.dart';

/// FtpTransferQueuePanel — active jobs + transfer history.
class FtpTransferQueuePanel extends StatelessWidget {
  final FtpService ftpService;
  final Future<void> Function(TransferJob job) onCancelJob;

  const FtpTransferQueuePanel({super.key, required this.ftpService, required this.onCancelJob});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ftpService,
      builder: (context, _) {
        final jobs = ftpService.activeJobs;
        final hasActive = jobs.any((j) => j.isActive);
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (hasActive ? context.successColor : context.textSecondary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: (hasActive ? context.successColor : context.textSecondary).withOpacity(0.2)),
                ),
                child: Icon(hasActive ? Icons.swap_horiz_rounded : Icons.inbox_rounded, color: hasActive ? context.successColor : context.textSecondary, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                hasActive ? "Proses Transfer (${jobs.where((j) => j.isActive).length})" : "Antrian Transfer",
                style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ]),
            // Active Jobs
            if (jobs.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...jobs.map((job) => _FtpJobRow(job: job, onCancel: () => onCancelJob(job))),
            ] else ...[
              const SizedBox(height: 8),
              Text("Tidak ada proses berjalan", style: TextStyle(color: context.textSecondary, fontSize: 12)),
            ],
            // History
            if (ftpService.history.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: context.borderColor.withOpacity(0.5)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.history_rounded, size: 12, color: context.textSecondary),
                const SizedBox(width: 6),
                Text("RIWAYAT TRANSFER", style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ]),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  padding: EdgeInsets.zero, shrinkWrap: true,
                  itemCount: ftpService.history.length,
                  itemBuilder: (_, i) => _FtpHistoryRow(item: ftpService.history[i]),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}

// ── JOB ROW ────────────────────────────────────────────────────
class _FtpJobRow extends StatelessWidget {
  final TransferJob job;
  final VoidCallback onCancel;
  const _FtpJobRow({required this.job, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isUpload = job.type == TransferType.upload;
    final color = job.status == TransferJobStatus.failed ? context.dangerColor
        : job.status == TransferJobStatus.cancelled ? context.warningColor
        : isUpload ? context.successColor : context.accentColor;
    final isDone = job.status == TransferJobStatus.done;
    final isFailed = job.status == TransferJobStatus.failed;
    final isCancelled = job.status == TransferJobStatus.cancelled;

    return ListenableBuilder(
      listenable: job,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(0.25))),
              child: Icon(isDone ? Icons.check_rounded : isCancelled ? Icons.block_rounded : isFailed ? Icons.error_outline_rounded : isUpload ? Icons.upload_rounded : Icons.download_rounded, size: 14, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (job.storeCode.isNotEmpty) ...[
                  Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.accentColor.withOpacity(0.3))),
                    child: Text(job.storeCode, style: TextStyle(color: context.accentColor, fontSize: 9, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 6),
                ],
                Expanded(child: Text(job.fileName, style: TextStyle(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 2),
              Text(job.statusText, style: TextStyle(color: context.textSecondary, fontSize: 10), overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            if (job.isActive) ...[
              Text("${(job.progress * 100).toStringAsFixed(1)}%", style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(width: 8),
              Tooltip(message: "Batalkan transfer", child: Material(color: Colors.transparent, child: InkWell(
                onTap: job.cancelRequested ? null : onCancel,
                borderRadius: BorderRadius.circular(6),
                child: Container(padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: context.dangerColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: context.dangerColor.withOpacity(0.25))),
                  child: Icon(Icons.close_rounded, size: 12, color: job.cancelRequested ? context.textSecondary : context.dangerColor)),
              ))),
            ],
          ]),
          if (job.isActive) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: job.progress > 0 ? job.progress : null, backgroundColor: context.borderColor, color: color, minHeight: 5)),
          ],
        ]),
      ),
    );
  }
}

// ── HISTORY ROW ────────────────────────────────────────────────
class _FtpHistoryRow extends StatelessWidget {
  final TransferHistoryItem item;
  const _FtpHistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUpload = item.type == TransferType.upload;
    final color = item.success ? (isUpload ? context.successColor : context.accentColor) : context.dangerColor;
    final t = item.time;
    final timeStr = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.day.toString().padLeft(2, '0')} ${FtpController.monthName(t.month)}";

    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(0.25))),
        child: Icon(item.success ? (isUpload ? Icons.upload_rounded : Icons.download_rounded) : Icons.error_outline_rounded, size: 13, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.fileName, style: TextStyle(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        if (!item.success) Text(item.detail, style: TextStyle(color: context.dangerColor, fontSize: 9), overflow: TextOverflow.ellipsis),
      ])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (item.storeCode.isNotEmpty)
            Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.accentColor.withOpacity(0.3))),
              child: Text(item.storeCode, style: TextStyle(color: context.accentColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(item.success ? Icons.check_rounded : Icons.close_rounded, size: 9, color: color),
              const SizedBox(width: 2),
              Text(item.success ? "Berhasil" : "Gagal", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            ])),
        ]),
        const SizedBox(height: 3),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (item.detail.isNotEmpty && item.success) Text("${item.detail}  ", style: TextStyle(color: context.textSecondary, fontSize: 9)),
          Text(timeStr, style: TextStyle(color: context.textSecondary, fontSize: 9, fontFamily: 'monospace')),
        ]),
      ]),
    ]));
  }
}
