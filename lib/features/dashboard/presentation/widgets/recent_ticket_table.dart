import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ticket/domain/ticket_model.dart';
import '../dashboard_controller.dart';

/// Recent critical/unresolved ticket table for dashboard.
class RecentTicketTable extends StatelessWidget {
  const RecentTicketTable({super.key, required this.ctrl});
  final DashboardController ctrl;

  static const _statusColors = {
    'Open': Color(0xFFFF6B6B),
    'In Progress': Color(0xFFFFA726),
    'Resolved': Color(0xFF00E676),
  };

  @override
  Widget build(BuildContext context) {
    final tickets = ctrl.recentCriticalTickets;
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Icon(Icons.priority_high_rounded, size: 16, color: const Color(0xFFFF6B6B)),
                const SizedBox(width: 8),
                Text('RECENT CRITICAL TICKETS', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: context.textSecondary, letterSpacing: 1.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('${tickets.length} unresolved', style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B6B))),
                ),
              ]),
            ),
            Divider(color: context.borderColor.withOpacity(0.2), height: 1),

            // ── Mobile Rows ──
            if (tickets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Semua tiket sudah resolved ✓', style: TextStyle(
                  color: context.textSecondary, fontSize: 12))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.length,
                separatorBuilder: (context, index) => Divider(
                  color: context.borderColor.withOpacity(0.15),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final t = tickets[index];
                  final stColor = _statusColors[t.status] ?? context.textSecondary;
                  final time = t.createdAt != null
                      ? DateFormat('dd MMM yyyy  HH:mm').format(t.createdAt!)
                      : '-';

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: context.accentColor.withOpacity(0.15)),
                                  ),
                                  child: Text(
                                    t.storeCode,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: context.accentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C9CE6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    t.provider.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5C9CE6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: stColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: stColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.storeName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 11, color: context.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 4),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Icon(Icons.priority_high_rounded, size: 16, color: const Color(0xFFFF6B6B)),
              const SizedBox(width: 8),
              Text('RECENT CRITICAL TICKETS', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: context.textSecondary, letterSpacing: 1.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('${tickets.length} unresolved', style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B6B))),
              ),
            ]),
          ),

          // ── Table header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.5),
              border: Border(
                top: BorderSide(color: context.borderColor.withOpacity(0.3)),
                bottom: BorderSide(color: context.borderColor.withOpacity(0.3)),
              ),
            ),
            child: Row(children: [
              _HeaderCell('Kode', width: 70),
              _HeaderCell('Nama Toko', flex: 3),
              _HeaderCell('Provider', width: 72),
              _HeaderCell('Status', width: 90),
              _HeaderCell('Waktu', width: 130),
            ]),
          ),

          // ── Rows ──
          if (tickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Semua tiket sudah resolved ✓', style: TextStyle(
                color: context.textSecondary, fontSize: 12))),
            )
          else
            ...tickets.map((t) => _TicketRow(ticket: t)),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.width, this.flex});
  final String label;
  final double? width;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, style: TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: context.textSecondary, letterSpacing: 0.5));
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }
}

class _TicketRow extends StatefulWidget {
  const _TicketRow({required this.ticket});
  final TicketModel ticket;

  @override
  State<_TicketRow> createState() => _TicketRowState();
}

class _TicketRowState extends State<_TicketRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final stColor = RecentTicketTable._statusColors[t.status] ?? context.textSecondary;
    final time = t.createdAt != null
        ? DateFormat('dd MMM yyyy  HH:mm').format(t.createdAt!)
        : '-';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? context.accentColor.withOpacity(0.03) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: context.borderColor.withOpacity(0.15)),
            left: BorderSide(
              color: _hovered ? context.accentColor.withOpacity(0.5) : Colors.transparent,
              width: 2),
          ),
        ),
        child: Row(children: [
          SizedBox(width: 70, child: Text(t.storeCode, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimary),
            overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(t.storeName, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: context.textPrimary),
            overflow: TextOverflow.ellipsis)),
          SizedBox(width: 72, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF5C9CE6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4)),
            child: Text(t.provider, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5C9CE6)),
              textAlign: TextAlign.center),
          )),
          SizedBox(width: 90, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: stColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Text(t.status, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: stColor),
              textAlign: TextAlign.center),
          )),
          SizedBox(width: 130, child: Text(time, style: TextStyle(
            fontSize: 10, color: context.textSecondary))),
        ]),
      ),
    );
  }
}
