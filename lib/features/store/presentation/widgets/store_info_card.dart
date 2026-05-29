import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../domain/store_model.dart';

/// StoreInfoCard — kode toko, nama, koneksi, SID.
class StoreInfoCard extends StatelessWidget {
  final StoreModel store;
  const StoreInfoCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final isVsat = (store.connectionType ?? '').toUpperCase().contains('VSAT');
    final hasSidUtama = (store.sidUtama ?? '').trim().isNotEmpty && (store.sidUtama ?? '') != '-';
    final hasSidBackup = (store.sidBackup ?? '').trim().isNotEmpty && (store.sidBackup ?? '') != '-';
    final showSid = !isVsat && hasSidUtama;
    final showSidBackup = !isVsat && hasSidBackup;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        _row(context, Icons.storefront_outlined, "Kode Toko", store.storeCode, isFirst: true, copyable: true),
        _divider(context),
        _row(context, Icons.badge_outlined, "Nama Toko", store.storeName, copyable: true),
        _divider(context),
        _row(context, Icons.cable_outlined, "Koneksi Utama", store.connectionType ?? "-"),
        _divider(context),
        _row(context, Icons.settings_backup_restore_outlined, "Koneksi Backup", store.connectionBackup ?? "-", isLast: !showSid),
        if (showSid) ...[
          _divider(context),
          _row(context, Icons.sim_card_outlined, "SID Utama", store.sidUtama!, isLast: !showSidBackup, copyable: true),
        ],
        if (showSidBackup) ...[
          _divider(context),
          _row(context, Icons.sim_card_outlined, "SID Backup", store.sidBackup!, isLast: true, copyable: true),
        ],
      ]),
    );
  }

  Widget _divider(BuildContext context) => Divider(height: 1, color: context.borderColor.withOpacity(0.6), indent: 16, endIndent: 16);

  Widget _row(BuildContext context, IconData icon, String label, String value, {bool isFirst = false, bool isLast = false, bool copyable = false}) {
    final valueWidget = copyable
        ? GestureDetector(
            onTap: () { Clipboard.setData(ClipboardData(text: value)); CustomSnackBar.show(context, '$label disalin!', const Color(0xFF00D4FF)); },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(value, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 5),
              Icon(Icons.copy_outlined, size: 12, color: context.textSecondary.withOpacity(0.45)),
            ]))
        : Text(value, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, color: context.textSecondary, size: 18),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12))),
        valueWidget,
      ]),
    );
  }
}
