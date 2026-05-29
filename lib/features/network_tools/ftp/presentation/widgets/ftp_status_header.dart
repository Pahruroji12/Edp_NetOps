import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// FtpStatusHeader — connection status banner di atas halaman FTP.
class FtpStatusHeader extends StatelessWidget {
  final bool isConnected;
  final String ip;

  const FtpStatusHeader({super.key, required this.isConnected, required this.ip});

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected ? context.successColor : context.dangerColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(builder: (_, c) {
        final isWide = c.maxWidth >= 360;
        final iconAndStatus = Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Icon(isConnected ? Icons.tv_rounded : Icons.tv_off_rounded, color: statusColor, size: 26),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("STATUS STB", style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Row(children: [
              Text(isConnected ? "ONLINE" : "OFFLINE", style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.7), blurRadius: 8)])),
            ]),
          ]),
        ]);
        final ipBox = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.borderColor)),
          child: Column(crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            Text("IP STB", style: TextStyle(color: context.textSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(ip, style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: 1)),
          ]),
        );
        if (isWide) return Row(children: [iconAndStatus, const Spacer(), ipBox]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [iconAndStatus, const SizedBox(height: 12), SizedBox(width: double.infinity, child: ipBox)]);
      }),
    );
  }
}
