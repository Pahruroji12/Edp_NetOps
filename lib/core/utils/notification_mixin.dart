import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_snackbar.dart';
import '../globals.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION MIXIN — standardized notification pattern for controllers
//
// Cara pakai:
//   class MyController extends ChangeNotifier with NotificationMixin { ... }
//
//   // Di controller — gunakan semantic level:
//   notifySuccess('Data berhasil disimpan');
//   notifyError('Gagal menyimpan data');
//   notifyWarning('Periksa koneksi Anda');
//   notifyInfo('Memproses data...');
//
//   // Di page — konsumsi notifikasi:
//   void _onControllerChanged() {
//     if (ctrl.pendingNotification != null) {
//       CustomSnackBar.show(context, ctrl.pendingNotification!.message,
//                                     ctrl.pendingNotification!.color);
//       ctrl.clearNotification();
//     }
//   }
// ══════════════════════════════════════════════════════════════════════════════

/// Semantic notification level — digunakan bersama oleh controller & service.
///
/// Mapping ke warna dilakukan secara terpusat di [NotifMessage.color],
/// sehingga controller tidak perlu import Color secara eksplisit.
enum NotifLevel {
  success,
  warning,
  error,
  info,
}

/// Immutable notification message — menggabungkan pesan dan level.
class NotifMessage {
  final String message;
  final NotifLevel level;

  const NotifMessage(this.message, this.level);

  /// Mapping otomatis level → warna dari AppStatusColors.
  Color get color {
    switch (level) {
      case NotifLevel.success:
        return AppStatusColors.success;
      case NotifLevel.warning:
        return AppStatusColors.warning;
      case NotifLevel.error:
        return AppStatusColors.danger;
      case NotifLevel.info:
        return AppStatusColors.info;
    }
  }
}

/// Mixin untuk ChangeNotifier controllers yang memerlukan notification state.
///
/// Menghilangkan boilerplate ~15 baris per controller:
///   - `String? pendingNotifMessage` / `Color? pendingNotifColor`
///   - `void _notify(String, Color)`
///   - `void clearNotification()`
///
/// Diganti menjadi single `pendingNotification` field + semantic helper methods.
mixin NotificationMixin on ChangeNotifier {
  /// Notification yang menunggu untuk ditampilkan oleh Page.
  NotifMessage? pendingNotification;

  /// Emit notification — dipanggil dari controller logic.
  void notify(String message, NotifLevel level) {
    final notif = NotifMessage(message, level);
    pendingNotification = notif;
    final color = notif.color;

    notifyListeners();

    // Tampilkan snackbar secara global agar tetap muncul meskipun halaman tidak aktif
    final state = globalMessengerKey.currentState;
    if (state != null) {
      CustomSnackBar.showFromKey(
        globalMessengerKey,
        message,
        color,
      );
    }
  }

  /// Shorthand helpers — agar controller code lebih readable.
  void notifySuccess(String message) => notify(message, NotifLevel.success);
  void notifyError(String message) => notify(message, NotifLevel.error);
  void notifyWarning(String message) => notify(message, NotifLevel.warning);
  void notifyInfo(String message) => notify(message, NotifLevel.info);

  /// Clear notification — dipanggil oleh Page setelah menampilkan snackbar.
  void clearNotification() {
    pendingNotification = null;
  }
}
