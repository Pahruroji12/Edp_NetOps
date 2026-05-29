import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../domain/user_model.dart';
import '../../../core/utils/notification_mixin.dart';

/// ProfileController — semua state dan logic untuk ProfilePage.
///
/// Lokasi: features/profile/presentation/profile_controller.dart
///
/// Tanggung jawab:
///   - Kelola state user list (fetch, filter, delete)
///   - Kelola state password change (loading, visibility toggle)
///   - Kelola state cache clearing
///   - Kelola animasi ready state
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung (gunakan notification state)
///   - Import widget selain ChangeNotifier
///
class ProfileController extends ChangeNotifier with NotificationMixin {
  final ProfileRepository _repo = ProfileRepository();

  // ── State: General ─────────────────────────────────────────────
  bool isLoading = false;
  bool animationsReady = false;

  // ── State: Password Visibility ─────────────────────────────────
  bool obscureOldPass = true;
  bool obscureNewPass = true;

  // ── State: User List ───────────────────────────────────────────
  List<UserModel> _allUsers = [];
  List<UserModel> filteredUsers = [];
  bool isLoadingUsers = true;
  String _searchKeyword = '';

  // ── State: Notification (via NotificationMixin) ────────────────

  // ── INIT ───────────────────────────────────────────────────────

  void init() {
    fetchUsers();
  }

  void markAnimationsReady() {
    animationsReady = true;
    notifyListeners();
  }

  // ── USER LIST ──────────────────────────────────────────────────

  int get userCount => filteredUsers.length;

  Future<void> fetchUsers() async {
    final result = await _repo.fetchUsers();
    result.fold(
      (failure) {
        debugPrint('Gagal mengambil data user: ${failure.message}');
        isLoadingUsers = false;
        notifyListeners();
      },
      (users) {
        _allUsers = users;
        _applyFilter();
        isLoadingUsers = false;
        notifyListeners();
      },
    );
  }

  void filterUsers(String keyword) {
    _searchKeyword = keyword;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchKeyword.isEmpty) {
      filteredUsers = List.from(_allUsers);
    } else {
      final lower = _searchKeyword.toLowerCase();
      filteredUsers = _allUsers.where((user) {
        return user.nama.toLowerCase().contains(lower) ||
            user.nik.toLowerCase().contains(lower);
      }).toList();
    }
  }

  // ── DELETE USER ────────────────────────────────────────────────

  /// Eksekusi delete user (panggil setelah dialog confirm di Page).
  Future<void> executeDeleteUser(String id, String nik, String nama) async {
    isLoadingUsers = true;
    notifyListeners();
    
    final result = await _repo.deleteUser(id, nama, nik);
    result.fold(
      (failure) {
        notifyError("Gagal menghapus: ${failure.message}");
        isLoadingUsers = false;
        notifyListeners();
      },
      (_) async {
        notifySuccess("Pengguna berhasil dihapus permanen!");
        await fetchUsers();
      },
    );
  }

  // ── PASSWORD ───────────────────────────────────────────────────

  void toggleOldPassVisibility() {
    obscureOldPass = !obscureOldPass;
    notifyListeners();
  }

  void toggleNewPassVisibility() {
    obscureNewPass = !obscureNewPass;
    notifyListeners();
  }

  /// Validasi dan update password.
  /// Return true jika berhasil (agar Page bisa clear text field).
  Future<bool> updatePassword(String oldPass, String newPass) async {
    if (oldPass.isEmpty || newPass.isEmpty) {
      notifyError("Password lama dan baru wajib diisi!");
      return false;
    }
    if (newPass.length < 6) {
      notifyError("Password baru minimal 6 karakter!");
      return false;
    }

    isLoading = true;
    notifyListeners();
    
    final result = await _repo.updatePassword(oldPassword: oldPass, newPassword: newPass);
    
    isLoading = false;
    notifyListeners();

    return result.fold(
      (failure) {
        notifyError("Gagal: ${failure.message}");
        return false;
      },
      (_) {
        notifySuccess("Password berhasil diubah!");
        return true;
      },
    );
  }

  // ── CACHE ──────────────────────────────────────────────────────

  Future<void> clearAppCache() async {
    isLoading = true;
    notifyListeners();
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await Future.delayed(const Duration(milliseconds: 1500));
      notifySuccess("Cache & Memori sistem berhasil dibersihkan! Aplikasi lebih ringan.");
    } catch (e) {
      notifyError("Gagal membersihkan cache: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
