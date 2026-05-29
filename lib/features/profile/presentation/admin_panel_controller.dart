import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../../../core/utils/notification_mixin.dart';

/// AdminPanelController — semua state dan logic untuk AdminPanelPage.
///
/// Lokasi: features/profile/presentation/admin_panel_controller.dart
///
/// Tanggung jawab:
///   - Fetch users & activity logs dari repository
///   - Filter users dan logs (search + category)
///   - Kelola loading state
///   - Notification state untuk Page
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung
///   - Import widget selain ChangeNotifier
///   - Query Supabase langsung (harus via repository)
///
class AdminPanelController extends ChangeNotifier with NotificationMixin {
  final ProfileRepository _repo = ProfileRepository();

  // ── State: Animation ────────────────────────────────────────
  bool animationsReady = false;

  // ── State: Loading ──────────────────────────────────────────
  bool isLoadingUsers = false;
  bool isLoadingLogs = false;

  // ── State: Raw Data ─────────────────────────────────────────
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _logs = [];

  // ── State: Filtered Data ────────────────────────────────────
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> filteredLogs = [];

  // ── State: Search Controllers ───────────────────────────────
  final searchUserCtrl = TextEditingController();
  final searchLogCtrl = TextEditingController();

  // ── State: Log Filter ───────────────────────────────────────
  String selectedLogFilter = 'SEMUA';

  static const List<String> logFilters = [
    'SEMUA',
    'LOGIN',
    'LOGOUT',
    'TAMBAH',
    'EDIT',
    'HAPUS',
  ];

  // ── State: Notification (via NotificationMixin) ─────────────

  // ── Computed: User Stats ────────────────────────────────────
  int get totalUsers => _users.length;
  int get onlineCount => _users.where((u) => u['is_online'] == true).length;
  int get offlineCount => totalUsers - onlineCount;

  // ── INIT ────────────────────────────────────────────────────

  void init() {
    fetchAll();
  }

  void markAnimationsReady() {
    animationsReady = true;
    notifyListeners();
  }

  // ── FETCH DATA ──────────────────────────────────────────────

  Future<void> fetchAll() async {
    await Future.wait([fetchUsers(), fetchLogs()]);
  }

  Future<void> fetchUsers() async {
    isLoadingUsers = true;
    notifyListeners();
    
    final result = await _repo.fetchUsersOnlineFirst();
    isLoadingUsers = false;
    
    result.fold(
      (failure) {
        notifyError('Gagal muat pengguna: ${failure.message}');
      },
      (users) {
        _users = users.map((u) => u.toJson()).toList();
        _applyUserFilter();
      },
    );
    notifyListeners();
  }

  Future<void> fetchLogs() async {
    isLoadingLogs = true;
    notifyListeners();
    
    final result = await _repo.fetchLogs();
    isLoadingLogs = false;
    
    result.fold(
      (failure) {
        notifyError('Gagal muat log: ${failure.message}');
      },
      (logs) {
        _logs = logs;
        _applyLogFilter();
      },
    );
    notifyListeners();
  }

  // ── FILTER: USERS ───────────────────────────────────────────

  void filterUsers(String query) {
    _applyUserFilter(query: query);
    notifyListeners();
  }

  void _applyUserFilter({String? query}) {
    final q = query ?? searchUserCtrl.text;
    if (q.isEmpty) {
      filteredUsers = _users;
    } else {
      final lower = q.toLowerCase();
      filteredUsers = _users.where((u) {
        return (u['nama'] ?? '').toString().toLowerCase().contains(lower) ||
            (u['nik'] ?? '').toString().toLowerCase().contains(lower) ||
            (u['role'] ?? '').toString().toLowerCase().contains(lower);
      }).toList();
    }
  }

  // ── FILTER: LOGS ────────────────────────────────────────────

  void setLogFilter(String filter) {
    selectedLogFilter = filter;
    _applyLogFilter();
    notifyListeners();
  }

  void filterLogs(String query) {
    _applyLogFilter(query: query);
    notifyListeners();
  }

  void _applyLogFilter({String? query}) {
    final q = query ?? searchLogCtrl.text;
    List<Map<String, dynamic>> base = _logs;

    // Kategori filter
    if (selectedLogFilter != 'SEMUA') {
      base = base
          .where(
            (l) => (l['action_type'] ?? '')
                .toString()
                .toUpperCase()
                .contains(selectedLogFilter),
          )
          .toList();
    }

    // Search filter
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      base = base.where((l) {
        return (l['description'] ?? '')
                .toString()
                .toLowerCase()
                .contains(lower) ||
            (l['user_name'] ?? '').toString().toLowerCase().contains(lower);
      }).toList();
    }

    filteredLogs = base;
  }

  // ── DISPOSE ─────────────────────────────────────────────────

  @override
  void dispose() {
    searchUserCtrl.dispose();
    searchLogCtrl.dispose();
    super.dispose();
  }
}
