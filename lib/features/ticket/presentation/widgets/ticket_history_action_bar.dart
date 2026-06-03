import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../ticket_controller.dart';
import '../../domain/ticket_model.dart';

class TicketHistoryActionBar extends StatelessWidget {
  final TicketController ctrl;
  final List<TicketModel> filtered;
  final bool isDesktop;

  const TicketHistoryActionBar({
    key,
    required this.ctrl,
    required this.filtered,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = ctrl.allTickets.length;
    final shown = filtered.length;
    final isFiltered = shown != total;

    final open = filtered.where((t) => t.status == 'Open').length;
    final prog = filtered.where((t) => t.status == 'In Progress').length;
    final resolved = filtered.where((t) => t.status == 'Resolved').length;

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
            _footerDot(context, const Color(0xFFE57373), 'Open $open'),
            const SizedBox(width: 10),
            _footerDot(context, const Color(0xFFFFB74D), 'Progress $prog'),
            const SizedBox(width: 10),
            _footerDot(context, const Color(0xFF81C784), 'Resolved $resolved'),
          ],
        ],
      ),
    );
  }

  Widget _footerDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
