import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
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
        color: const Color(0xFF0F172A), // Slate 900 (Gelap pekat ala terminal)
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
                  color: Colors.white.withOpacity(0.7),
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
          const Divider(color: Colors.white10, height: 20),

          // Log output
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogLine(
                  time: _formattedTime(),
                  prefix: "[system]",
                  message: "Inisialisasi pemindaian ping...",
                  color: Colors.grey,
                ),
                const SizedBox(height: 6),
                _buildLogLine(
                  time: _formattedTime(),
                  prefix: "[target]",
                  message: "Mengecek ${engine.totalTarget} IP perangkat...",
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 6),
                _buildLogLine(
                  time: _formattedTime(),
                  prefix: "[status]",
                  message: engine.statusText,
                  color: color,
                  isBold: true,
                ),
                if (isDone) ...[
                  const SizedBox(height: 6),
                  _buildLogLine(
                    time: _formattedTime(),
                    prefix: "[export]",
                    message: "Hasil tersimpan di: ${engine.outputDir}",
                    color: Colors.amberAccent,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine({
    required String time,
    required String prefix,
    required String message,
    required Color color,
    bool isBold = false,
  }) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: "$time ",
            style: TextStyle(color: Colors.white.withOpacity(0.35)),
          ),
          TextSpan(
            text: "$prefix ",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formattedTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }
}
