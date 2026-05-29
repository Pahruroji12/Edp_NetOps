import 'package:flutter/material.dart';
import '../../../layout/main_layout.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/globals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/section_header.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';
import 'settings_sections.dart';

/// SettingsPage — thin UI page untuk pengaturan sistem.
///
/// Lokasi: features/settings/presentation/settings_page.dart
///
/// Arsitektur:
///   Page (UI) → Controller (logic) → Repository (data)
///
/// Page ini hanya:
///   - Render UI berdasarkan state dari SettingsController
///   - Listen notifikasi dan tampilkan snackbar
///   - Delegate semua aksi ke controller
///
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SettingsController();
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
    super.dispose();
  }

  /// React to controller state changes — show notifications.
  void _onControllerChanged() {
    if (!mounted) return;

    // Ambil notifikasi SEBELUM setState agar tidak hilang di rebuild.
    final notification = _ctrl.pendingNotification;
    if (notification != null) {
      _ctrl.clearNotification();
    }

    setState(() {}); // Rebuild UI dari state terbaru

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: _ctrl.isLoading
          ? const SettingsLoadingOverlay()
          : AnimatedOpacity(
              opacity: _ctrl.animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset:
                    _ctrl.animationsReady ? Offset.zero : const Offset(0, 0.04),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.pagePaddingH,
                          0,
                          context.pagePaddingH,
                          40,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            if (_ctrl.isAdministrator) ...[
                              const SectionHeader(
                                title: "MANAJEMEN PENGGUNA",
                                icon: Icons.people_outline,
                              ),
                              const SizedBox(height: 12),
                              UserManagementSection(ctrl: _ctrl),
                              const SizedBox(height: 24),
                              const SectionHeader(
                                title: "KONFIGURASI SISTEM",
                                icon: Icons.router_outlined,
                              ),
                              const SizedBox(height: 12),
                              RouterConfigSection(ctrl: _ctrl),
                              const SizedBox(height: 24),
                              const SectionHeader(
                                title: "KONFIGURASI SMTP",
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 12),
                              SmtpConfigSection(ctrl: _ctrl),
                              const SizedBox(height: 24),
                              const SectionHeader(
                                title: "KONFIGURASI IMAP",
                                icon: Icons.mail_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                              ImapConfigSection(ctrl: _ctrl),
                            ] else ...[
                              const SettingsRestrictedAccess(),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    final isDesktop = context.isDesktop;
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: isDesktop
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
                "PENGATURAN SISTEM",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                "Pengaturan & Sistem",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
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
}
