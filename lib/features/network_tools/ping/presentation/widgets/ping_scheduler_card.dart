import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import '../ping_controller.dart';

class PingSchedulerCard extends StatelessWidget {
  final PingController engine;

  const PingSchedulerCard({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final active = engine.isAutoPingSTBActive;
    final color = const Color(0xFF6C63FF); // indigo/purple

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: active ? 28 : 24,
            right: 24,
            top: 24,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(active ? 0.12 : 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(active ? 0.25 : 0.1),
                  ),
                ),
                child: Icon(
                  Icons.nightlight_round_outlined,
                  color: active ? color : context.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Auto-Ping STB",
                      style: TextStyle(
                        color: active ? context.textPrimary : context.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Otomatis ping seluruh IP STB setiap jam 00:00 – 03:00 pagi.",
                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                    ),
                    if (active) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Scheduler Aktif",
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: active,
                onChanged: engine.isScanning ? null : engine.toggleAutoPing,
                activeColor: color,
                activeTrackColor: color.withOpacity(0.25),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active
                    ? [color, color.withOpacity(0.25)]
                    : [context.borderColor, context.borderColor.withOpacity(0.25)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
