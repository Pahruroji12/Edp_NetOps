import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/network_action_buttons.dart';
import '../../../../../core/permissions/permission_helper.dart';
import '../../../ticket/presentation/dialogs/ticket_dialog.dart';
import '../../domain/store_model.dart';
import '../../../../core/utils/connection_type_helper.dart';
import '../controllers/store_detail_controller.dart';

/// StorePingCard — status koneksi gateway + ping actions.
class StorePingCard extends StatelessWidget {
  final StoreDetailController ctrl;
  final StoreModel store;

  const StorePingCard({super.key, required this.ctrl, required this.store});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isMobile) return const SizedBox.shrink();

    final isOnline = ctrl.pingStatus == "ONLINE";
    final isChecking = ctrl.pingStatus == "Mengecek koneksi...";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ctrl.pingColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: ctrl.pingColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Text("STATUS KONEKSI GATEWAY", style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isChecking)
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: context.accentColor, strokeWidth: 2))
          else
            Container(width: 12, height: 12, decoration: BoxDecoration(color: ctrl.pingColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: ctrl.pingColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)])),
          const SizedBox(width: 12),
          Text(ctrl.pingStatus, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: ctrl.pingColor, letterSpacing: 1)),
          if (isOnline && ctrl.latency.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: ctrl.pingColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: ctrl.pingColor.withOpacity(0.3))),
              child: Text(ctrl.latency, style: TextStyle(color: ctrl.pingColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        if (store.ipGateway != null) ...[
          const SizedBox(height: 6),
          Text(store.ipGateway!, style: TextStyle(color: context.textSecondary, fontSize: 12, fontFamily: 'monospace', letterSpacing: 0.5)),
        ],
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SolidActionButton(label: "Cek Ulang", icon: Icons.refresh_rounded, color: context.accentColor, onTap: ctrl.checkAllIps),
          const SizedBox(width: 10),
          OutlineActionButton(label: "Ping CMD", icon: Icons.terminal_outlined, color: context.textSecondary,
            onTap: () { if (store.ipGateway?.isNotEmpty == true) ctrl.launchPingCmd(store.ipGateway!); }),
          if (!ctrl.isMobile && _foTicketProviders.isNotEmpty && PermissionHelper.can(AppPermission.openTicket)) ...[
            const SizedBox(width: 10),
            _buildTicketButton(context),
          ],
        ]),
      ]),
    );
  }

  List<Map<String, dynamic>> get _foTicketProviders => ConnectionTypeHelper.foTicketProviders(store.connectionType, store.connectionBackup);

  Widget _buildTicketButton(BuildContext context) {
    final providers = _foTicketProviders;
    if (providers.isEmpty) return const SizedBox.shrink();
    const ticketColor = Color(0xFFFF9800);

    if (providers.length == 1) {
      final p = providers.first;
      return Material(color: Colors.transparent, child: InkWell(
        onTap: () => TicketDialog.show(context, store, p['key'] as String, isBackup: p['isBackup'] as bool),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: ticketColor.withOpacity(0.08), borderRadius: BorderRadius.circular(9), border: Border.all(color: ticketColor.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.confirmation_number_outlined, color: ticketColor, size: 15),
            const SizedBox(width: 6),
            const Text('Open Tiket', style: TextStyle(color: ticketColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ));
    }

    return PopupMenuButton<int>(
      tooltip: 'Pilih provider untuk open tiket',
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, -8),
      onSelected: (idx) {
        final p = providers[idx];
        TicketDialog.show(context, store, p['key'] as String, isBackup: p['isBackup'] as bool);
      },
      itemBuilder: (_) => providers.asMap().entries.map((entry) {
        final p = entry.value;
        return PopupMenuItem<int>(value: entry.key, child: Row(children: [
          const Icon(Icons.confirmation_number_outlined, size: 15, color: ticketColor),
          const SizedBox(width: 10),
          Text('Tiket ${p['label']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ]));
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: ticketColor.withOpacity(0.08), borderRadius: BorderRadius.circular(9), border: Border.all(color: ticketColor.withOpacity(0.3))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.confirmation_number_outlined, color: ticketColor, size: 15),
          SizedBox(width: 6),
          Text('Open Tiket', style: TextStyle(color: ticketColor, fontSize: 12, fontWeight: FontWeight.w700)),
          SizedBox(width: 4),
          Icon(Icons.arrow_drop_down_rounded, color: ticketColor, size: 16),
        ]),
      ),
    );
  }
}
