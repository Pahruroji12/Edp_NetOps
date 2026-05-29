import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/ticket_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ranking summary cards — Total / Open / Progress / Resolved
// ─────────────────────────────────────────────────────────────────────────────

class RankingSummaryRow extends StatelessWidget {
  const RankingSummaryRow({super.key, required this.data});
  final List<TicketModel> data;

  @override
  Widget build(BuildContext context) {
     final total = data.length;
     final open = data.where((t) => t.status == 'Open').length;
     final prog = data.where((t) => t.status == 'In Progress').length;
     final resolved = data.where((t) => t.status == 'Resolved').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  RankingSummaryCard(
                    'Total',
                    '$total',
                    Icons.confirmation_number_outlined,
                    context.accentColor,
                  ),
                  const SizedBox(width: 8),
                  RankingSummaryCard(
                    'Open',
                    '$open',
                    Icons.error_outline,
                    const Color(0xFFE57373),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RankingSummaryCard(
                    'Progress',
                    '$prog',
                    Icons.pending_outlined,
                    const Color(0xFFFFB74D),
                  ),
                  const SizedBox(width: 8),
                  RankingSummaryCard(
                    'Resolved',
                    '$resolved',
                    Icons.check_circle_outline,
                    const Color(0xFF81C784),
                  ),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            RankingSummaryCard(
              'Total',
              '$total',
              Icons.confirmation_number_outlined,
              context.accentColor,
            ),
            const SizedBox(width: 8),
            RankingSummaryCard(
              'Open',
              '$open',
              Icons.error_outline,
              const Color(0xFFE57373),
            ),
            const SizedBox(width: 8),
            RankingSummaryCard(
              'Progress',
              '$prog',
              Icons.pending_outlined,
              const Color(0xFFFFB74D),
            ),
            const SizedBox(width: 8),
            RankingSummaryCard(
              'Resolved',
              '$resolved',
              Icons.check_circle_outline,
              const Color(0xFF81C784),
            ),
          ],
        );
      },
    );
  }
}

class RankingSummaryCard extends StatelessWidget {
  const RankingSummaryCard(this.label, this.value, this.icon, this.color,
      {super.key});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(0.7), size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
