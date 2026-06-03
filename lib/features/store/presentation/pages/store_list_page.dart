import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/store_model.dart';
import '../../presentation/controllers/store_list_controller.dart';

import '../../presentation/widgets/store_card.dart';
import 'store_detail_page.dart';
import 'store_form_page.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/export_helper.dart';
import '../../../../../layout/main_layout.dart';
import 'package:edp_netops/core/widgets/app_loading_indicator.dart';
import 'package:edp_netops/core/widgets/app_empty_state.dart';
import 'package:edp_netops/core/widgets/page_entry_transition.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final _controller = StoreListController();

  // Shortcuts untuk kemudahan baca di build
  List<StoreModel> get _allStores => _controller.allStores;
  List<StoreModel> get _filteredStores => _controller.filteredStores;
  bool get _isLoading => _controller.isLoading;
  bool get _isAdminOrAbove => _controller.isAdminOrAbove;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.fetchStores();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() => _controller.fetchStores();
  void _applyFilters() => _controller.applyFilters();

  // Delegate ke StoreListController.connColor agar konsisten di semua halaman
  // Color _connColor(String label) => StoreListController.connColor(label);

  // ========================================== //
  // _logout & drawer sudah dipindah ke AppSidebar
  // ========================================== //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      floatingActionButton: _isAdminOrAbove ? _buildFab() : null,
      body: _isLoading
          ? _buildLoadingState()
          : PageEntryTransition(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _filteredStores.isEmpty
                        ? _buildEmptyState()
                        : _buildStoreList(),
                  ),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // FAB
  // ==========================================
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.accentColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const StoreFormPage()),
          );
          if (result == true) _fetchStores();
        },
        backgroundColor: context.accentColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.add_rounded, color: context.primaryColor, size: 20),
        label: Text(
          "Toko Baru",
          style: TextStyle(
            color: context.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER — Responsif
  // ==========================================
  Widget _buildHeader() {
    final isDesktop = context.isDesktop;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 480;
              return Row(
                children: [
                  // Hamburger hanya di mobile — buka drawer MainLayout
                  if (!isDesktop) ...[
                    _buildIconButton(
                      icon: Icons.menu_rounded,
                      onTap: () =>
                          MainLayout.scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: context.accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.accentColor.withOpacity(0.7),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "DATA TOKO",
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_filteredStores.length} dari ${_allStores.length} toko",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isWide) ...[
                    _buildStatBadge(
                      "${_allStores.length}",
                      "TOTAL",
                      context.accentColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildExportButton(),
                  const SizedBox(width: 8),
                  _buildRefreshButton(),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderColor),
          ),
          child: Icon(icon, color: context.textPrimary, size: 18),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            // Tangkap pesan kembaliannya
            final message = await ExportHelper.exportToCSV(_filteredStores);

            if (mounted) {
              // Tampilkan pesan sukses warna hijau
              CustomSnackBar.show(context, message, Colors.green);
            }
          } catch (e) {
            if (mounted) {
              CustomSnackBar.show(context, e.toString(), context.dangerColor);
            }
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.successColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.download_rounded,
                color: context.successColor,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                "Export",
                style: TextStyle(
                  color: context.successColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _fetchStores,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.accentColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: context.accentColor, size: 14),
              const SizedBox(width: 5),
              Text(
                "Refresh",
                style: TextStyle(
                  color: context.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: context.accentColor,
            selectionColor: context.accentColor.withOpacity(0.3),
            selectionHandleColor: context.accentColor,
          ),
        ),
        child: TextField(
          controller: _controller.searchController,
          onChanged: (_) => _applyFilters(),
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Cari kode, nama, atau IP gateway...",
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 12),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.textSecondary,
              size: 18,
            ),
            suffixIcon: _controller.searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.textSecondary,
                      size: 16,
                    ),
                    onPressed: () {
                      _controller.clearSearch();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StoreListController.filterChips.map((chip) {
          final isActive = _controller.activeFilter == chip;
          final Color chipColor = chip == 'Semua'
              ? context.accentColor
              : chip == 'FO'
              ? const Color(0xFF29B6F6)
              : chip == 'VSAT'
              ? const Color(0xFFFFB74D)
              : chip == 'GSM'
              ? const Color(0xFFFF7043)
              : const Color(0xFFAB47BC);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _controller.setFilter(chip),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? chipColor : chipColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? chipColor : chipColor.withOpacity(0.25),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: chipColor.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        chip,
                        style: TextStyle(
                          color: isActive ? context.primaryColor : chipColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // LOADING STATE
  // ==========================================
  Widget _buildLoadingState() {
    return const AppLoadingIndicator(
      message: "MEMUAT DATA TOKO...",
      size: 32,
      isCard: true,
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState() {
    final hasActiveFilterOrSearch = _controller.searchController.text.isNotEmpty ||
        _controller.activeFilter != 'Semua';
    return AppEmptyState(
      title: "Tidak Ada Hasil",
      message: hasActiveFilterOrSearch
          ? "Coba ubah filter atau kata pencarian"
          : "Belum ada data toko tersedia",
      icon: Icons.storefront_outlined,
      actionLabel: hasActiveFilterOrSearch ? "Reset Filter" : null,
      onAction: hasActiveFilterOrSearch
          ? () {
              _controller.setFilter('Semua');
              _controller.clearSearch();
            }
          : null,
    );
  }


  // ==========================================
  // STORE LIST — Grid 2 kolom di desktop, 1 di mobile
  // ==========================================
  Widget _buildStoreList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        context.pagePaddingH,
        context.scaledPadding(16),
        context.pagePaddingH,
        100,
      ),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) {
        final store = _filteredStores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StoreCard(
            store: store,
            onTap: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => StoreDetailPage(store: store),
                ),
              );
              if (changed == true) _fetchStores();
            },
          ),
        );
      },
    );
  }
}
