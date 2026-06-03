import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import '../ping_controller.dart';

class PingTargetSelector extends StatelessWidget {
  final PingController engine;

  const PingTargetSelector({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final targets = [
      {
        'key': 'GW',
        'label': 'IP Gateway',
        'icon': Icons.router_outlined,
        'value': engine.config.gateway,
      },
      {
        'key': 'S1',
        'label': 'IP Station 1',
        'icon': Icons.computer_outlined,
        'value': engine.config.station1,
      },
      {
        'key': 'STB',
        'label': 'IP STB',
        'icon': Icons.tv_outlined,
        'value': engine.config.stb,
      },
      {
        'key': 'RB',
        'label': 'IP RB WDCP',
        'icon': Icons.settings_input_antenna_outlined,
        'value': engine.config.rbWdcp,
      },
      {
        'key': 'C1',
        'label': 'IP CCTV 1',
        'icon': Icons.videocam_outlined,
        'value': engine.config.cctv1,
      },
      {
        'key': 'C2',
        'label': 'IP CCTV 2',
        'icon': Icons.videocam_outlined,
        'value': engine.config.cctv2,
      },
    ];

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            left: 28,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                context,
                "Pilih Target IP",
                "Pilih jenis IP yang akan di-ping",
                Icons.my_location_outlined,
                context.accentColor,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final cols = constraints.maxWidth >= 480 ? 3 : 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: targets.map((t) {
                        final checked = t['value'] as bool;
                        final key = t['key'] as String;
                        final label = t['label'] as String;
                        final icon = t['icon'] as IconData;
                        final color = checked
                            ? context.accentColor
                            : context.textSecondary.withOpacity(0.4);

                        return SizedBox(
                          width: (constraints.maxWidth - (cols - 1) * 8) / cols,
                          child: GestureDetector(
                            onTap: engine.isScanning
                                ? null
                                : () => engine.setCheckbox(key, !checked),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: checked
                                    ? context.accentColor.withOpacity(0.08)
                                    : context.cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: checked
                                      ? context.accentColor.withOpacity(0.35)
                                      : context.borderColor,
                                  width: checked ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, size: 14, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: checked
                                            ? context.textPrimary
                                            : context.textSecondary,
                                        fontSize: 12,
                                        fontWeight: checked
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: checked
                                          ? context.accentColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: checked
                                            ? context.accentColor
                                            : context.borderColor,
                                      ),
                                    ),
                                    child: checked
                                        ? const Icon(
                                            Icons.check,
                                            size: 11,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
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
                colors: [context.accentColor, context.accentColor.withOpacity(0.25)],
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

  Widget _buildCardHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
