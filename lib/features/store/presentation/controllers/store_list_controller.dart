import 'package:flutter/material.dart';
import '../../domain/store_model.dart';
import '../../data/store_repository.dart';
import '../../../../../core/utils/role_helper.dart';

/// StoreListController — semua state dan logic untuk StoreListPage.
///
/// Lokasi: features/store/presentation/controllers/store_list_controller.dart
///
/// StoreListPage hanya tangani UI dan animasi — data & logic ada di sini.
///
class StoreListController extends ChangeNotifier {
  final _repo = StoreRepository();

  // ── State ─────────────────────────────────────────────────────
  List<StoreModel> allStores = [];
  List<StoreModel> filteredStores = [];
  bool isLoading = true;
  String activeFilter = 'Semua';
  String? errorMessage;

  final searchController = TextEditingController();

  static const filterChips = ['Semua', 'FO', 'VSAT', 'GSM', 'XL'];

  // ── Auth ──────────────────────────────────────────────────────
  bool get isAdminOrAbove => RoleHelper.isAdminOrAbove;

  // ── Data ──────────────────────────────────────────────────────

  Future<void> fetchStores() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.fetchAll();
    
    result.fold(
      (failure) {
        errorMessage = 'Gagal memuat data: ${failure.message}';
        isLoading = false;
        notifyListeners();
      },
      (data) {
        allStores = data;
        applyFilters();
        isLoading = false;
      },
    );
  }

  void applyFilters() {
    final q = searchController.text.toLowerCase();

    filteredStores = allStores.where((store) {
      final matchText =
          q.isEmpty ||
          store.storeCode.toLowerCase().contains(q) ||
          store.storeName.toLowerCase().contains(q) ||
          (store.ipGateway ?? '').toLowerCase().contains(q);

      if (!matchText) return false;
      if (activeFilter == 'Semua') return true;

      final conn = (store.connectionType ?? '').toLowerCase();
      switch (activeFilter) {
        case 'FO':
          return conn.contains('astinet') ||
              conn.contains('icon') ||
              conn.contains('fiberstar');
        case 'VSAT':
          return conn.contains('vsat') || (store.ipVsat?.isNotEmpty == true);
        case 'GSM':
          return conn.contains('gsm') || conn.contains('orbit');
        case 'XL':
          return conn.contains('xl');
        default:
          return true;
      }
    }).toList();

    notifyListeners();
  }

  void setFilter(String filter) {
    activeFilter = filter;
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    applyFilters();
  }

  // ── Color helper ──────────────────────────────────────────────

  /// Warna badge berdasarkan label koneksi — centralized agar konsisten
  /// di StoreListPage dan StoreDetailPage.
  static Color connColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('astinet')) return const Color(0xFF29B6F6);
    if (l.contains('icon')) return const Color(0xFF26C6DA);
    if (l.contains('fiberstar')) return const Color(0xFF66BB6A);
    if (l.contains('orbit')) return const Color(0xFFEF5350);
    if (l.contains('xl') || l.contains('tun')) return const Color(0xFFAB47BC);
    if (l.contains('indosat') || l.contains('isat')) {
      return const Color(0xFFFFCA28);
    }
    if (l.contains('vsat')) return const Color(0xFFFFB74D);
    if (l.contains('gsm')) return const Color(0xFFFF7043);
    return const Color(0xFF7A9CC4);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
