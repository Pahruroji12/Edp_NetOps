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
  bool _isDisposed = false;

  final searchController = TextEditingController();

  static const filterChips = [
    'Semua',
    'Astinet',
    'Icon',
    'Astinet SDWAN',
    'Icon SDWAN',
    'Fiberstar SDWAN',
    'Starlink SDWAN',
    'VSAT',
    'GSM',
    'XL',
  ];

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
        case 'Astinet':
          return conn.contains('astinet') && !conn.contains('sdwan');
        case 'Icon':
          return conn.contains('icon') && !conn.contains('sdwan');
        case 'Astinet SDWAN':
          return conn.contains('astinet') && conn.contains('sdwan');
        case 'Icon SDWAN':
          return conn.contains('icon') && conn.contains('sdwan');
        case 'Fiberstar SDWAN':
          return conn.contains('fiberstar') && conn.contains('sdwan');
        case 'Starlink SDWAN':
          return conn.contains('starlink') && conn.contains('sdwan');
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

  int getActiveFilterCount() {
    if (activeFilter == 'Semua') return allStores.length;
    return allStores.where((store) {
      final conn = (store.connectionType ?? '').toLowerCase();
      switch (activeFilter) {
        case 'Astinet':
          return conn.contains('astinet') && !conn.contains('sdwan');
        case 'Icon':
          return conn.contains('icon') && !conn.contains('sdwan');
        case 'Astinet SDWAN':
          return conn.contains('astinet') && conn.contains('sdwan');
        case 'Icon SDWAN':
          return conn.contains('icon') && conn.contains('sdwan');
        case 'Fiberstar SDWAN':
          return conn.contains('fiberstar') && conn.contains('sdwan');
        case 'Starlink SDWAN':
          return conn.contains('starlink') && conn.contains('sdwan');
        case 'VSAT':
          return conn.contains('vsat') || (store.ipVsat?.isNotEmpty == true);
        case 'GSM':
          return conn.contains('gsm') || conn.contains('orbit');
        case 'XL':
          return conn.contains('xl');
        default:
          return false;
      }
    }).length;
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
    if (l.contains('starlink')) return const Color(0xFF5C6BC0);
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
    _isDisposed = true;
    searchController.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
