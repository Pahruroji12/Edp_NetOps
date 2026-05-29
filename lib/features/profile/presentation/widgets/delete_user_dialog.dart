import 'package:flutter/material.dart';
import '../../../../core/widgets/confirm_dialog.dart';

/// Menampilkan dialog konfirmasi hapus user.
///
/// [onConfirm] dipanggil ketika user menekan "Ya, Hapus".
///
Future<void> showDeleteUserDialog(
  BuildContext context, {
  required String nama,
  required String nik,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: "Hapus Pengguna?",
    message: "Apakah Anda yakin ingin menghapus $nama (NIK: $nik) dari sistem? Tindakan ini tidak dapat dibatalkan.",
    confirmLabel: "Ya, Hapus",
    cancelLabel: "Batal",
    icon: Icons.person_remove_outlined,
    isDanger: true,
  );

  if (confirmed == true) {
    onConfirm();
  }
}
