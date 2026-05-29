import 'package:flutter/material.dart';

import '../../domain/store_model.dart';
import '../controllers/store_detail_controller.dart';
import 'store_form_page.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../../../../core/globals.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../widgets/store_ping_card.dart';
import '../widgets/store_info_card.dart';
import '../widgets/store_device_card.dart';

/// StoreDetailPage — thin UI orchestrator.
///
/// Arsitektur: Page (layout) → StoreDetailController (logic) → Repository (data)
///
/// UI sections extracted ke presentation/widgets/:
///   - StorePingCard       — gateway connection status
///   - StoreInfoCard       — kode toko, nama, koneksi, SID
///   - StoreDeviceCard     — IP management, stations, CCTV, STB
///
class StoreDetailPage extends StatefulWidget {
  final StoreModel store;
  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final _ctrl = StoreDetailController();
  bool _animationsReady = false;

  StoreModel get _currentStore => _ctrl.currentStore;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerChanged);
    _ctrl.init(widget.store);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
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

    // Ambil notifikasi SEBELUM setState agar tidak hilang di rebuild.
    final notification = _ctrl.pendingNotification;
    if (notification != null) {
      _ctrl.clearNotification();
    }

    setState(() {});

    // Snackbar notification — via postFrameCallback agar aman.
    if (notification != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CustomSnackBar.showFromKey(
          globalMessengerKey,
          notification.message,
          notification.color,
        );
      });
    }
    // Error dialog
    if (_ctrl.pendingErrorTitle != null) {
      _showErrorDialog(_ctrl.pendingErrorTitle!, _ctrl.pendingErrorContent ?? '');
      _ctrl.clearErrorDialog();
    }
  }

  // ── Navigation & Dialogs (require BuildContext) ────────────────

  Future<void> _editStore() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StoreFormPage(store: _currentStore)));
    if (result == true) {
      try { await _ctrl.refreshStore(); }
      catch (e) { if (mounted) CustomSnackBar.show(context, "Gagal memuat ulang data: $e", Colors.red); }
    }
  }

  Future<void> _deleteStore() async {
    final confirm = await showDialog<bool>(
      context: context, barrierColor: Colors.black54,
      builder: (context) => Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth(base: 420)),
        child: Material(color: Colors.transparent, child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.dialogMargin),
          decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.borderColor),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30, offset: Offset(0, 10))]),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF2A1520), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3))),
              child: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 28)),
            const SizedBox(height: 16),
            Text("Hapus Toko?", style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Data toko ${_currentStore.storeCode} akan dihapus permanen.", textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(side: BorderSide(color: context.borderColor), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text("Batal", style: TextStyle(color: context.textSecondary)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B), padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
            ]),
          ]),
        )),
      )),
    );
    if (confirm == true) {
      final success = await _ctrl.deleteStore();
      if (success && mounted) {
        CustomSnackBar.show(context, "Toko berhasil dihapus", Colors.green);
        Navigator.pop(context, true);
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(context: context, barrierColor: Colors.black54,
      builder: (context) => Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth(base: 380)),
        child: Material(color: Colors.transparent, child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.dialogMargin),
          decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 8))]),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(content, style: TextStyle(color: context.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: context.primaryColor),
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
        )),
      )),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: _ctrl.isLoading
          ? _buildLoadingState()
          : AnimatedOpacity(
              opacity: _animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.pagePaddingH,
                        context.scaledPadding(20),
                        context.pagePaddingH,
                        60,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        StorePingCard(ctrl: _ctrl, store: _currentStore),
                        const SizedBox(height: 20),
                        _buildSectionLabel("INFORMASI TOKO", Icons.store_outlined),
                        const SizedBox(height: 12),
                        StoreInfoCard(store: _currentStore),
                        const SizedBox(height: 20),
                        _buildSectionLabel(
                          _ctrl.isMobile ? "INFORMASI IP" : "MANAJEMEN PERANGKAT",
                          _ctrl.isMobile ? Icons.lan_outlined : Icons.device_hub_outlined,
                        ),
                        const SizedBox(height: 12),
                        StoreDeviceCard(ctrl: _ctrl, store: _currentStore),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(color: context.primaryColor, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: context.accentColor, strokeWidth: 2.5)),
      const SizedBox(height: 14),
      Text("MEMUAT...", style: TextStyle(color: context.textSecondary, fontSize: 11, letterSpacing: 2.5)),
    ])));
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true, backgroundColor: context.cardColor, elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context, _ctrl.hasChanged)),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${_currentStore.storeCode} — ${_currentStore.storeName}", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text("Detail & Manajemen", style: TextStyle(color: context.textSecondary, fontSize: 10)),
      ]),
      actions: [
        if (_ctrl.isAdminOrAbove) ...[
          _buildAppBarAction(icon: Icons.edit_outlined, onTap: _editStore, color: context.accentColor),
          const SizedBox(width: 4),
          _buildAppBarAction(icon: Icons.delete_outline, onTap: _deleteStore, color: const Color(0xFFFF6B6B)),
        ],
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, context.accentColor.withOpacity(0.3), Colors.transparent])))),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required VoidCallback onTap, required Color color}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.25))),
        child: Icon(icon, color: color, size: 16))));
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 13, color: context.accentColor),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [context.borderColor, Colors.transparent])))),
    ]);
  }
}
