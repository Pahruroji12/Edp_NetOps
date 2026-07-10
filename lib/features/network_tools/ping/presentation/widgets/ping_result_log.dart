import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/widgets/custom_snackbar.dart';
import '../ping_controller.dart';

class PingResultLog extends StatelessWidget {
  final PingController engine;

  const PingResultLog({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    if (!engine.isScanning && engine.progressValue == 0.0) {
      return const SizedBox.shrink();
    }

    final isScanning = engine.isScanning;
    final isDone = engine.progressValue == 1.0 && !isScanning;
    final color = isDone ? context.successColor : context.accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Console
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.amberAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "CONSOLE LOGS",
                style: TextStyle(
                  color: context.textPrimary.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (isScanning)
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "RUNNING",
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                )
              else
                Text(
                  "COMPLETED",
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          Divider(color: context.borderColor, height: 20),

          // Log output (Terminal Console Box)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogLine(
                  context: context,
                  time: _formattedTime(engine.scanStartTime),
                  prefix: "[system]",
                  message: "Inisialisasi pemindaian ping...",
                  color: Colors.grey,
                ),
                const SizedBox(height: 6),
                _buildLogLine(
                  context: context,
                  time: _formattedTime(engine.scanStartTime),
                  prefix: "[target]",
                  message: "Mengecek ${engine.totalTarget} IP perangkat...",
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 6),
                _buildLogLine(
                  context: context,
                  time: _formattedTime(isScanning ? null : engine.scanEndTime),
                  prefix: "[status]",
                  message: isScanning
                      ? "Mengeksekusi Ping... (${engine.okCount + engine.nokCount} / ${engine.totalTarget} IP)"
                      : "Pemindaian selesai.",
                  color: color,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Divider pemisah console dengan progress bar info
          Container(
            height: 1,
            color: context.borderColor,
          ),
          const SizedBox(height: 16),

          // ── Progress Bar & Keterangan Section ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: isScanning
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.check_circle_outline, color: color, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isScanning ? "Sedang Memindai..." : "Pemindaian Selesai",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isScanning 
                          ? "Memproses ping perangkat..." 
                          : "Seluruh target IP telah selesai dipindai.",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Persentase
              Text(
                "${(engine.progressValue * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: engine.progressValue,
              minHeight: 5,
              backgroundColor: context.textPrimary.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          // ── Stat Chips OK / NOK ──
          if (engine.okCount > 0 || engine.nokCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  context: context,
                  label: 'OK',
                  value: '${engine.okCount}',
                  color: context.successColor,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context: context,
                  label: 'NOK',
                  value: '${engine.nokCount}',
                  color: context.dangerColor,
                  icon: Icons.cancel_outlined,
                ),
                const Spacer(),
                Text(
                  '${engine.okCount + engine.nokCount} / ${engine.totalTarget}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],

          // ── Save Location Box ──
          if (isDone) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.textPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.textPrimary.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Penyimpanan Hasil Ping",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          engine.lastFilePath ?? engine.outputDir,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, color: context.textSecondary, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: engine.lastFilePath ?? engine.outputDir));
                      CustomSnackBar.success('Path file disalin ke clipboard!');
                    },
                    tooltip: 'Salin Path',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogLine({
    required BuildContext context,
    required String time,
    required String prefix,
    required String message,
    required Color color,
    bool isBold = false,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
          color: context.textPrimary,
        ),
        children: [
          TextSpan(
            text: "$time ",
            style: TextStyle(color: context.textSecondary.withOpacity(0.5)),
          ),
          TextSpan(
            text: "$prefix ",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: message,
            style: TextStyle(
              color: context.textPrimary.withOpacity(0.85),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formattedTime(DateTime? time) {
    final targetTime = time ?? DateTime.now();
    return "${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}:${targetTime.second.toString().padLeft(2, '0')}";
  }

  Widget _buildStatChip({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.75),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
