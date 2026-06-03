import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/permissions/permission_helper.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'package:edp_netops/core/widgets/app_empty_state.dart';
import '../../domain/ticket_model.dart';
import '../../presentation/ticket_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TicketCard — hybrid responsive ticket item
// Desktop (>= 1200): compact enterprise table row
// Tablet/Mobile: compact card
// ─────────────────────────────────────────────────────────────────────────────

class TicketCard extends StatefulWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onDetail,
    required this.onUpdate,
    required this.onDelete,
    this.index = 0,
  });

  final TicketModel ticket;
  final VoidCallback onDetail;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final int index;

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  bool _isHovered = false;


  @override
  Widget build(BuildContext context) {
    final isDesktop = context.screenWidth >= 1200;
    return isDesktop ? _buildTableRow(context) : _buildCompactCard(context);
  }

  // ── Desktop: Enterprise table row ─────────────────────────────────────────

  Widget _buildTableRow(BuildContext context) {
    final t = widget.ticket;
    final stColor = TicketController.statusColor(t.status);
    final noTiket = (t.nomorTiket ?? '').trim();
    final createdAt = t.createdAt != null
        ? DateFormat('dd MMM yyyy  HH:mm').format(t.createdAt!)
        : '-';
    final createdBy = _formatCreatedBy(t.createdBy);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered
              ? context.accentColor.withOpacity(0.04)
              : context.cardColor,
          border: Border(
            bottom: BorderSide(color: context.borderColor.withOpacity(0.4)),
            left: BorderSide(
              color: _isHovered ? context.accentColor.withOpacity(0.5) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Store code
                  SizedBox(
                    width: 80,
                    child: Text(
                      t.storeCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Store name
                  SizedBox(
                    width: 200,
                    child: Text(
                      t.storeName,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Provider
                  SizedBox(
                    width: 70,
                    child: _ProviderBadge(provider: t.provider),
                  ),
                  const SizedBox(width: 12),

                  // No. Tiket
                  SizedBox(
                    width: 120,
                    child: noTiket.isEmpty
                        ? Text(
                            '—',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary.withOpacity(0.4),
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  noTiket,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: noTiket)).then((_) {
                                      CustomSnackBar.info('Nomor tiket berhasil disalin!');
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.copy_rounded,
                                      size: 12,
                                      color: context.textSecondary.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Status badge
                  SizedBox(
                    width: 85,
                    child: _StatusBadge(status: t.status, color: stColor),
                  ),
                  const SizedBox(width: 12),

                  // Date
                  SizedBox(
                    width: 125,
                    child: Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // PIC
                  SizedBox(
                    width: 80,
                    child: Text(
                      createdBy,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Keterangan
                  Expanded(
                    child: Text(
                      t.keterangan?.trim().isEmpty ?? true ? '—' : t.keterangan!,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Actions
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: _CompactActions(
                        onDetail: widget.onDetail,
                        onUpdate: widget.onUpdate,
                        onDelete: widget.onDelete,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile/Tablet: Compact card ───────────────────────────────────────────

  Widget _buildCompactCard(BuildContext context) {
    final t = widget.ticket;
    final stColor = TicketController.statusColor(t.status);
    final noTiket = (t.nomorTiket ?? '').trim();
    final createdAt = t.createdAt != null
        ? DateFormat('dd MMM yyyy  HH:mm').format(t.createdAt!)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Header — provider + store + status
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                _ProviderBadge(provider: t.provider),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${t.storeCode} — ${t.storeName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: t.status, color: stColor),
              ],
            ),
          ),

          // Body — ticket + date + PIC
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 320;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tag_rounded, size: 11, color: context.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  noTiket.isEmpty ? '— belum diisi —' : noTiket,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: noTiket.isEmpty
                                        ? context.textSecondary.withOpacity(0.4)
                                        : context.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: noTiket.isEmpty ? FontStyle.italic : FontStyle.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (noTiket.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: noTiket)).then((_) {
                                        CustomSnackBar.info('Nomor tiket berhasil disalin!');
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 11,
                                        color: context.textSecondary.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule_outlined, size: 11, color: context.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                createdAt,
                                style: TextStyle(fontSize: 10, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.tag_rounded, size: 11, color: context.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  noTiket.isEmpty ? '— belum diisi —' : noTiket,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: noTiket.isEmpty
                                        ? context.textSecondary.withOpacity(0.4)
                                        : context.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: noTiket.isEmpty ? FontStyle.italic : FontStyle.normal,
                                  ),
                                   overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (noTiket.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: noTiket)).then((_) {
                                        CustomSnackBar.info('Nomor tiket berhasil disalin!');
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 11,
                                        color: context.textSecondary.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_outlined, size: 11, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          createdAt,
                          style: TextStyle(fontSize: 10, color: context.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
                if (t.keterangan?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 11,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.keterangan!,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Footer — actions
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.borderColor.withOpacity(0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (t.createdBy != null)
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 11, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatCreatedBy(t.createdBy),
                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                _CompactActions(
                  onDetail: widget.onDetail,
                  onUpdate: widget.onUpdate,
                  onDelete: widget.onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreatedBy(String? createdBy) {
    if (createdBy == null) return '-';
    return createdBy.contains('@') ? createdBy.split('@').first : createdBy;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge — flat clean chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider badge — small flat chip
// ─────────────────────────────────────────────────────────────────────────────

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.provider});
  final String provider;

  static const _pvColor = Color(0xFF5C9CE6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _pvColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        provider,
        style: const TextStyle(
          fontSize: 10,
          color: _pvColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact action buttons — icon + tooltip (minimalis)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactActions extends StatelessWidget {
  const _CompactActions({
    required this.onDetail,
    required this.onUpdate,
    required this.onDelete,
  });

  final VoidCallback onDetail;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(
          icon: Icons.visibility_outlined,
          tooltip: 'Detail',
          color: context.textSecondary,
          onTap: onDetail,
        ),
        if (PermissionHelper.can(AppPermission.updateTicket)) ...[
          const SizedBox(width: 2),
          _IconAction(
            icon: Icons.edit_outlined,
            tooltip: 'Update',
            color: context.accentColor,
            onTap: onUpdate,
          ),
        ],
        if (PermissionHelper.can(AppPermission.deleteTicket)) ...[
          const SizedBox(width: 2),
          _IconAction(
            icon: Icons.delete_outline,
            tooltip: 'Hapus',
            color: const Color(0xFFE57373),
            onTap: onDelete,
          ),
        ],
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Desktop table header (sticky)
// ─────────────────────────────────────────────────────────────────────────────

class TicketTableHeader extends StatelessWidget {
  const TicketTableHeader({super.key, required this.ctrl});
  final TicketController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor,
        border: Border(bottom: BorderSide(color: context.borderColor.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          _HeaderCell('Kode', width: 80, column: TicketSortColumn.storeCode, ctrl: ctrl),
          const SizedBox(width: 12),
          _HeaderCell('Nama Toko', width: 200, column: TicketSortColumn.storeName, ctrl: ctrl),
          const SizedBox(width: 12),
          _HeaderCell('Provider', width: 70, column: TicketSortColumn.provider, ctrl: ctrl),
          const SizedBox(width: 12),
          _HeaderCell('No. Tiket', width: 120, column: TicketSortColumn.nomorTiket, ctrl: ctrl),
          const SizedBox(width: 12),
          _HeaderCell('Status', width: 85, column: TicketSortColumn.status, ctrl: ctrl),
          const SizedBox(width: 12),
          _HeaderCell('Tanggal', width: 125, column: TicketSortColumn.createdAt, ctrl: ctrl),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              'PIC',
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keterangan',
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              'Aksi',
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    required this.width,
    required this.column,
    required this.ctrl,
  });

  final String label;
  final double width;
  final TicketSortColumn column;
  final TicketController ctrl;

  @override
  Widget build(BuildContext context) {
    final isActive = ctrl.sortColumn == column;
    final child = InkWell(
      onTap: () => ctrl.setSort(column),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? context.accentColor : context.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            if (isActive)
              Icon(
                ctrl.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 10,
                color: context.accentColor,
              ),
          ],
        ),
      ),
    );

    return SizedBox(width: width, child: child);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state widget (dipakai di History & Ranking tab)
// ─────────────────────────────────────────────────────────────────────────────

class TicketEmptyState extends StatelessWidget {
  const TicketEmptyState({super.key, this.message, this.subtitle});

  final String? message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: message ?? 'Tidak ada tiket ditemukan',
      message: subtitle ?? 'Coba ubah filter atau kata kunci pencarian',
      icon: Icons.inbox_outlined,
    );
  }
}

