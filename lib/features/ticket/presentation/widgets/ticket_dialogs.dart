import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/permissions/permission_helper.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../domain/ticket_model.dart';
import '../../presentation/ticket_controller.dart';

// ── Kumpulan dialog / bottom-sheet yang dipakai TicketHistoryPage ──

/// Dialog detail tiket (read-only + tombol buka update)
Future<void> showTicketDetailDialog(
  BuildContext context, {
  required TicketModel ticket,
  required Future<void> Function({
    required String id,
    required String nomorTiket,
    required String status,
    required String keterangan,
  })
  onUpdate,
}) async {
  final status = ticket.status;
  final noTiket = (ticket.nomorTiket ?? '').trim();
  final createdAt = ticket.createdAt != null
      ? DateFormat('dd MMMM yyyy, HH:mm').format(ticket.createdAt!)
      : '-';
  final createdBy = (ticket.createdBy ?? '').contains('@')
      ? ticket.createdBy!.split('@').first
      : (ticket.createdBy ?? '-');
  final stColor = TicketController.statusColor(status);
  const pvColor = Color(0xFF2196F3);

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth(base: 460)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.dialogMargin),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pvColor.withOpacity(0.18), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                _DialogHeader(
                  icon: Icons.confirmation_number_outlined,
                  iconColor: pvColor,
                  title: 'Detail Tiket',
                  subtitle: '${ticket.storeCode} — ${ticket.storeName}',
                  badge: status,
                  badgeColor: stColor,
                  onClose: () => Navigator.pop(ctx),
                ),

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    children: [
                      _DetailRow(
                        'Provider',
                        ticket.provider,
                        icon: Icons.router_outlined,
                        valueColor: pvColor,
                        bold: true,
                      ),
                      _DetailRow(
                        'Nomor Tiket',
                        noTiket.isEmpty ? '— belum diisi —' : noTiket,
                        icon: Icons.tag_rounded,
                        valueColor: noTiket.isEmpty
                            ? context.textSecondary.withOpacity(0.4)
                            : null,
                        italic: noTiket.isEmpty,
                        trailing: noTiket.isNotEmpty
                            ? Material(
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
                              )
                            : null,
                      ),
                      _DetailRow(
                        'Kode Toko',
                        ticket.storeCode,
                        icon: Icons.store_outlined,
                      ),
                      _DetailRow(
                        'Nama Toko',
                        ticket.storeName,
                        icon: Icons.store_mall_directory_outlined,
                      ),
                      _DetailRow(
                        'Tanggal Open',
                        createdAt,
                        icon: Icons.calendar_today_outlined,
                      ),
                      _DetailRow(
                        'Dibuat Oleh',
                        createdBy,
                        icon: Icons.person_outline_rounded,
                      ),
                      _DetailRow(
                        'Keterangan',
                        ticket.keterangan?.trim().isEmpty ?? true ? '—' : ticket.keterangan!,
                        icon: Icons.description_outlined,
                      ),
                    ],
                  ),
                ),

                // ── Footer ──
                _DialogFooter(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Tutup',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Update Tiket — hanya admin/administrator
                    if (PermissionHelper.can(AppPermission.updateTicket)) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await showTicketUpdateDialog(
                              context,
                              ticket: ticket,
                              onUpdate: onUpdate,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text(
                            'Update Tiket',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dialog update nomor tiket + status
Future<void> showTicketUpdateDialog(
  BuildContext context, {
  required TicketModel ticket,
  required Future<void> Function({
    required String id,
    required String nomorTiket,
    required String status,
    required String keterangan,
  })
  onUpdate,
}) async {
  final nomorCtrl = TextEditingController(text: ticket.nomorTiket ?? '');
  final keteranganCtrl = TextEditingController(text: ticket.keterangan ?? '');
  String selectedStatus = ticket.status;
  const pvColor = Color(0xFF2196F3);

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: context.accentColor.withOpacity(0.3),
            cursorColor: context.accentColor,
            selectionHandleColor: context.accentColor,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.dialogMaxWidth(base: 460)),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: context.dialogMargin),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: pvColor.withOpacity(0.18),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogHeader(
                      icon: Icons.edit_outlined,
                      iconColor: pvColor,
                      title: 'Update Tiket',
                      subtitle: '${ticket.storeCode} — ${ticket.storeName}',
                      onClose: () => Navigator.pop(ctx),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(
                            icon: Icons.tag_rounded,
                            label: 'Nomor Tiket',
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nomorCtrl,
                            cursorColor: context.accentColor,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textPrimary,
                            ),
                            onChanged: (val) {
                              final text = val.trim();
                              if (text.isNotEmpty && selectedStatus == 'Open') {
                                setS(() => selectedStatus = 'In Progress');
                              } else if (text.isEmpty && selectedStatus == 'In Progress') {
                                setS(() => selectedStatus = 'Open');
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Contoh: INC12345678',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                              filled: true,
                              fillColor: context.primaryColor,
                              prefixIcon: Icon(
                                Icons.confirmation_number_outlined,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: context.accentColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _FieldLabel(
                            icon: Icons.description_outlined,
                            label: 'Keterangan',
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: keteranganCtrl,
                            cursorColor: context.accentColor,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan keterangan tambahan...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                              filled: true,
                              fillColor: context.primaryColor,
                              prefixIcon: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: context.accentColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status chips
                          _FieldLabel(
                            icon: Icons.flag_outlined,
                            label: 'Status',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Open', 'In Progress', 'Resolved'].map((s) {
                              final color = TicketController.statusColor(s);
                              final isSelected = selectedStatus == s;
                              return GestureDetector(
                                onTap: () => setS(() => selectedStatus = s),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: color.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // ── Footer ──
                    _DialogFooter(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await onUpdate(
                                id: ticket.id,
                                nomorTiket: nomorCtrl.text.trim(),
                                status: selectedStatus,
                                keterangan: keteranganCtrl.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 15),
                            label: const Text(
                              'Simpan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Konfirmasi hapus tiket. Return true jika user konfirmasi.
Future<bool> showTicketDeleteConfirm(BuildContext context) async {
  final result = await showConfirmDialog(
    context,
    title: 'Hapus Tiket?',
    message: 'Data tiket ini akan dihapus permanen.',
    confirmLabel: 'Hapus',
    cancelLabel: 'Batal',
    icon: Icons.delete_outline,
    isDanger: true,
  );
  return result == true;
}

// Shared internal widgets
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: iconColor.withOpacity(0.12))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null && badgeColor != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor!.withOpacity(0.3)),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: context.textSecondary,
              size: 18,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
    this.label,
    this.value, {
    required this.icon,
    this.valueColor,
    this.bold = false,
    this.italic = false,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool bold;
  final bool italic;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: context.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: valueColor ?? context.textPrimary,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: context.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
