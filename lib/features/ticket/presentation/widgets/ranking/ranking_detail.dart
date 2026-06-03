import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../../domain/ticket_model.dart';
import '../../../presentation/ticket_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Expanded rank detail section — shows ticket list for a store
// ─────────────────────────────────────────────────────────────────────────────

class RankingExpandedDetail extends StatelessWidget {
  const RankingExpandedDetail({
    super.key,
    required this.item,
    required this.tickets,
    required this.resolvedPct,
    required this.ctrl,
  });
  final Map<String, dynamic> item;
  final List<TicketModel> tickets;
  final int resolvedPct;
  final TicketController ctrl;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy  HH:mm');
    final sortedTickets = List<TicketModel>.from(tickets)
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
      );

    return Container(
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: context.borderColor.withOpacity(0.3)),
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                RankingStatChip(
                  'Total Tiket',
                  '${item['total']}',
                  context.accentColor,
                ),
                const SizedBox(width: 8),
                RankingStatChip(
                    'Resolved', '$resolvedPct%', const Color(0xFF81C784)),
                const SizedBox(width: 8),
                RankingStatChip(
                    'Open', '${item['open']}', const Color(0xFFE57373)),
              ],
            ),
          ),

          // Ticket list header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 11,
                  color: context.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'RIWAYAT TIKET',
                  style: TextStyle(
                    fontSize: 9,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.borderColor.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),

          // Recent tickets (max 5)
          ...sortedTickets.take(5).map((t) {
            final stColor = TicketController.statusColor(t.status);
            final dateStr =
                t.createdAt != null ? fmt.format(t.createdAt!) : '-';
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(7),
                border:
                    Border.all(color: context.borderColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 10,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              t.provider,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF5C9CE6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((t.nomorTiket ?? '').trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (t.nomorTiket ?? '').trim(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: (t.nomorTiket ?? '').trim())).then((_) {
                                          CustomSnackBar.info('Nomor tiket berhasil disalin!');
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(3),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 9,
                                          color: context.textSecondary.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.status,
                      style: TextStyle(
                        fontSize: 9,
                        color: stColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (sortedTickets.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                '+ ${sortedTickets.length - 5} tiket lainnya',
                style: TextStyle(
                  fontSize: 9,
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Stat chip for expanded detail ───────────────────────────────────────────
class RankingStatChip extends StatelessWidget {
  const RankingStatChip(this.label, this.value, this.color, {super.key});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
