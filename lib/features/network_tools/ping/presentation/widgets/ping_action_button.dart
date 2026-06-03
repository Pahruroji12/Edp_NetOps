import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import '../ping_controller.dart';

class PingActionButton extends StatelessWidget {
  final PingController engine;

  const PingActionButton({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final isScanning = engine.isScanning;
    final color = isScanning ? context.textSecondary : context.accentColor;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isScanning ? null : () => engine.startPing(isAutoRun: false),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isScanning
                  ? null
                  : LinearGradient(
                      colors: [
                        context.accentColor,
                        context.accentColor.withOpacity(0.75),
                      ],
                    ),
              color: isScanning ? context.cardColor : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: isScanning
                  ? null
                  : [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isScanning)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: context.textSecondary,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.radar_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  isScanning ? "Memindai Jaringan..." : "Mulai Ping",
                  style: TextStyle(
                    color: isScanning ? context.textSecondary : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
