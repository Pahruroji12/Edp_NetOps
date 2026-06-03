import 'package:flutter/material.dart';
import '../../../../core/widgets/page_entry_transition.dart';
import 'package:flutter/services.dart';

import '../../../../layout/main_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'scan_wdcp_controller.dart';
import 'scan_wdcp_widgets.dart';
import 'wdcp_control_page.dart';

/// ScanWdcpPage — thin UI page untuk Scan RBWDCP.
///
/// Lokasi: features/network_tools/wdcp/presentation/scan_wdcp_page.dart
///
/// Arsitektur:
///   Page (UI) → Controller (logic) → Repository (data)
///
/// Page ini hanya:
///   - Render UI berdasarkan state dari ScanWdcpController
///   - Listen notifikasi dan tampilkan snackbar
///   - Delegate semua aksi ke controller
///
class ScanWdcpPage extends StatefulWidget {
  const ScanWdcpPage({super.key});

  @override
  State<ScanWdcpPage> createState() => _ScanWdcpPageState();
}

class _ScanWdcpPageState extends State<ScanWdcpPage> {
  late final ScanWdcpController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScanWdcpController();
    _ctrl.addListener(_onControllerChanged);
    _ctrl.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.triggerAnimations();
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    if (_ctrl.pendingNotification != null) {
      CustomSnackBar.show(
        context,
        _ctrl.pendingNotification!.message,
        _ctrl.pendingNotification!.color,
      );
      _ctrl.clearNotification();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: _ctrl.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: context.accentColor,
              ),
            )
          : PageEntryTransition(
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.pagePaddingH,
                        context.scaledPadding(20),
                        context.pagePaddingH,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'SCAN RBWDCP',
                            icon: Icons.radar_rounded,
                          ),
                          const SizedBox(height: 12),
                          WdcpScannerPanel(
                            scan: _ctrl.scan,
                            onFixNoTargets: () => CustomSnackBar.show(
                              context,
                              'Tidak ada router dengan default-auth aktif.',
                              context.successColor,
                            ),
                            onCsvTap: () => CustomSnackBar.show(
                              context,
                              'Disimpan di: ${_ctrl.scan.scanFilePath}',
                              context.successColor,
                            ),
                          ),
                          const SizedBox(height: 28),

                          const SectionHeader(
                            title: 'DAFTAR TOKO',
                            icon: Icons.store_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildStoreListCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }


  // ══════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ══════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: context.isDesktop
          ? null
          : IconButton(
              icon: Icon(Icons.menu_rounded, color: context.textPrimary),
              onPressed: () =>
                  MainLayout.scaffoldKey.currentState?.openDrawer(),
            ),
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SCAN WDCP",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                "Scan RbWDCP — Network Tools",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _ctrl.fetchStores,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.accentColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: context.accentColor,
                    size: 14,
                  ),
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
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STORE LIST CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildStoreListCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER ──
          WdcpStoreListHeader(
            searchCtrl: _ctrl.searchController,
            filteredCount: _ctrl.filteredStores.length,
            totalCount: _ctrl.totalStores,
            onSearch: _ctrl.applyFilters,
          ),
          Divider(height: 1, color: context.borderColor.withOpacity(0.5)),

          // ── CONTENT ──
          SizedBox(
            height: 450,
            child: _ctrl.isLoading
                ? WdcpLoadingWidget(color: context.accentColor)
                : _ctrl.filteredStores.isEmpty
                    ? WdcpEmptyWidget(
                        hasSearchText:
                            _ctrl.searchController.text.isNotEmpty,
                      )
                    : Scrollbar(
                        controller: _ctrl.listScrollController,
                        thumbVisibility: true,
                        radius: const Radius.circular(10),
                        child: ListView.separated(
                          controller: _ctrl.listScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: _ctrl.filteredStores.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: context.borderColor.withOpacity(0.5),
                          ),
                          itemBuilder: (_, i) => WdcpStoreRow(
                            store: _ctrl.filteredStores[i],
                            onOpenWdcp: (ip, name, code) =>
                                Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WdcpControlPage(
                                  ip: ip,
                                  storeName: name,
                                  storeCode: code,
                                ),
                              ),
                            ),
                            onWinbox: _ctrl.launchWinbox,
                            onPing: _ctrl.launchPingCmd,
                            onCopyInfo: (text) {
                              Clipboard.setData(ClipboardData(text: text));
                              CustomSnackBar.show(
                                context,
                                'Info toko disalin!',
                                context.accentColor,
                              );
                            },
                            onCopyIp: (ip) {
                              Clipboard.setData(ClipboardData(text: ip));
                              CustomSnackBar.show(
                                context,
                                'IP disalin!',
                                const Color(0xFF00D4FF),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
