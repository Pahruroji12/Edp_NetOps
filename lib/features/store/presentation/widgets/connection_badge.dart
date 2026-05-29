import 'package:flutter/material.dart';
import '../controllers/store_list_controller.dart';

/// ConnectionBadge — badge kecil untuk menampilkan tipe koneksi toko.
///
/// Lokasi: features/store/presentation/widgets/connection_badge.dart
///
/// Dipakai di StoreListPage dan StoreDetailPage.
///
class ConnectionBadge extends StatelessWidget {
  final String label;

  const ConnectionBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty || label == '-') return const SizedBox.shrink();

    final color = StoreListController.connColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
