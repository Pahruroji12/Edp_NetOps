import 'package:flutter/material.dart';
import '../../../../core/widgets/confirm_dialog.dart';

/// Menampilkan dialog konfirmasi hapus toko.
///
/// Return true jika user confirm, false/null jika batal.
///
Future<bool?> showDeleteStoreDialog(
  BuildContext context, {
  required String storeCode,
}) {
  return showConfirmDialog(
    context,
    title: "Hapus Toko?",
    message: "Data toko $storeCode akan dihapus permanen.",
    confirmLabel: "Hapus",
    cancelLabel: "Batal",
    icon: Icons.delete_outline,
    isDanger: true,
  );
}

/// Menampilkan dialog error sederhana.
Future<void> showErrorInfoDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showInfoDialog(
    context,
    title: title,
    message: content,
    icon: Icons.error_outline_rounded,
    iconColor: const Color(0xFFFF6B6B),
  );
}
