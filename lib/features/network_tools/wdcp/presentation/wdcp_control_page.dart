import 'package:flutter/material.dart';
import '../../../../core/widgets/page_entry_transition.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'wdcp_controller.dart';
import 'wdcp_control_widgets.dart';

/// WdcpControlPage — thin UI page untuk WDCP Router Control.
///
/// Arsitektur: Page (UI) → WdcpController (logic) → WdcpRepository (data)
///
class WdcpControlPage extends StatefulWidget {
  final String ip;
  final String storeName;
  final String storeCode;

  const WdcpControlPage({
    super.key,
    required this.ip,
    required this.storeName,
    required this.storeCode,
  });

  @override
  State<WdcpControlPage> createState() => _WdcpControlPageState();
}

class _WdcpControlPageState extends State<WdcpControlPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final WdcpController _ctrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ctrl = WdcpController(
      ip: widget.ip,
      storeName: widget.storeName,
      storeCode: widget.storeCode,
    );
    _ctrl.addListener(_onControllerChanged);
    _ctrl.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.markAnimationsReady();
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_ctrl.pendingNotification != null) {
      CustomSnackBar.show(context, _ctrl.pendingNotification!.message, _ctrl.pendingNotification!.color);
      if (_ctrl.pendingTabSwitch != null) _tabController.animateTo(_ctrl.pendingTabSwitch!);
      _ctrl.clearNotification();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: _ctrl.isLoading
          ? WdcpLoadingState(ip: widget.ip)
          : PageEntryTransition(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      child: !_ctrl.isConnected
                          ? WdcpErrorView(ip: widget.ip, onRetry: _ctrl.connectAndLoad)
                          : Column(children: [
                              WdcpStatusHeader(ip: widget.ip),
                              const SizedBox(height: 16),
                              LayoutBuilder(builder: (_, constraints) {
                                final isWide = constraints.maxWidth >= 700;
                                final rightPanels = Column(children: [
                                  WdcpSecurityPanel(isEnabled: _ctrl.defaultAuthStatus, onToggle: _ctrl.toggleAuth),
                                  const SizedBox(height: 16),
                                  WdcpAddMacPanel(macCtrl: _ctrl.macController, commentCtrl: _ctrl.commentController, onAdd: () { FocusScope.of(context).unfocus(); _ctrl.addMac(); }),
                                  const SizedBox(height: 16),
                                  WdcpRouterInfoPanel(sysInfo: _ctrl.systemInfo, onWinbox: _ctrl.launchWinbox),
                                ]);
                                if (isWide) {
                                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(flex: 6, child: _buildLeftTabPanel()),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 4, child: rightPanels),
                                  ]);
                                }
                                return Column(children: [
                                  _buildLeftTabPanel(compact: true),
                                  const SizedBox(height: 16),
                                  rightPanels,
                                ]);
                              }),
                            ]),
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
    final dotColor = _ctrl.isConnected ? context.successColor : context.dangerColor;
    return SliverAppBar(
      pinned: true, backgroundColor: context.cardColor, elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      title: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: dotColor.withOpacity(0.7), blurRadius: 8)])),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("RB WDCP — ${widget.storeCode}", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          Text(widget.storeName, style: TextStyle(color: context.textSecondary, fontSize: 10)),
        ]),
      ]),
      actions: [
        Material(color: Colors.transparent, child: InkWell(
          onTap: _ctrl.isConnected ? _ctrl.connectAndLoad : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: context.accentColor.withOpacity(0.25))),
            child: Row(children: [
              Icon(Icons.refresh_rounded, color: context.accentColor, size: 14),
              const SizedBox(width: 5),
              Text("Reconnect", style: TextStyle(color: context.accentColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        )),
        const SizedBox(width: 10),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, context.accentColor.withOpacity(0.3), Colors.transparent])))),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LEFT TAB PANEL
  // ══════════════════════════════════════════════════════════
  Widget _buildLeftTabPanel({bool compact = false}) {
    return Container(
      height: compact ? 500 : 600,
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        // Tab header
        Container(
          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), border: Border(bottom: BorderSide(color: context.borderColor))),
          child: TabBar(
            controller: _tabController,
            labelColor: context.accentColor, unselectedLabelColor: context.textSecondary,
            indicatorColor: context.accentColor, indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.smartphone_outlined, size: 15), const SizedBox(width: 6), Text("ONLINE (${_ctrl.deviceCount})")])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.list_alt_outlined, size: 15), const SizedBox(width: 6), Text("WHITELIST (${_ctrl.accessListCount})")])),
            ],
          ),
        ),
        // Tab content
        Expanded(child: TabBarView(controller: _tabController, children: [
          WdcpListContent(data: _ctrl.connectedDevices, isAccessList: false, emptyIcon: Icons.wifi_find_outlined, emptyText: "Tidak ada perangkat terhubung"),
          Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), child: Theme(
              data: Theme.of(context).copyWith(textSelectionTheme: TextSelectionThemeData(cursorColor: context.accentColor, selectionColor: context.accentColor.withOpacity(0.3), selectionHandleColor: context.accentColor)),
              child: TextField(
                controller: _ctrl.searchController, onChanged: _ctrl.filterAccessList,
                style: TextStyle(color: context.textPrimary, fontSize: 12), cursorColor: context.accentColor,
                decoration: InputDecoration(
                  hintText: "Cari MAC Address atau Nama...", hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5), fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 16, color: context.textSecondary),
                  contentPadding: EdgeInsets.zero, filled: true, fillColor: context.surfaceColor,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.accentColor, width: 1.5)),
                  suffixIcon: _ctrl.searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: 14, color: context.textSecondary), onPressed: () { _ctrl.searchController.clear(); _ctrl.filterAccessList(''); }) : null,
                ),
              ),
            )),
            Expanded(child: WdcpListContent(
              data: _ctrl.filteredAccessList, isAccessList: true,
              emptyIcon: Icons.search_off_outlined,
              emptyText: _ctrl.searchController.text.isEmpty ? "Access List kosong" : "Tidak ditemukan",
              onDelete: (id, mac) => _showDeleteDialog(id, mac),
            )),
          ]),
        ])),
        // Footer
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
          child: Material(color: Colors.transparent, child: InkWell(
            onTap: _ctrl.isRefreshing ? null : _ctrl.refreshData,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ctrl.isRefreshing
                  ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: context.accentColor, strokeWidth: 2))
                  : Icon(Icons.refresh_rounded, size: 14, color: context.accentColor),
              const SizedBox(width: 6),
              Text(_ctrl.isRefreshing ? "Memuat..." : "Refresh Data", style: TextStyle(color: context.accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
          )),
        ),
      ]),
    );
  }

  void _showDeleteDialog(String id, String mac) {
    showDialog(context: context, barrierColor: Colors.black54, builder: (_) => WdcpDeleteMacDialog(id: id, mac: mac, onConfirm: _ctrl.removeMac));
  }
}
