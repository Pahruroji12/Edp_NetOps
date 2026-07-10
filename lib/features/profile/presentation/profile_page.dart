import 'package:flutter/material.dart';

import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/globals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/section_header.dart';
import 'profile_controller.dart';
import '../../../core/widgets/page_entry_transition.dart';
import 'widgets/profile_hero_card.dart';
import 'widgets/security_card.dart';
import 'widgets/user_list_card.dart';

/// ProfilePage — halaman profil pengguna (refactored).
///
/// Lokasi: features/profile/presentation/profile_page.dart
///
/// Arsitektur:
///   - ProfileController  → state & business logic
///   - ProfileHeroCard    → avatar, nama, role, NIK
///   - SecurityCard       → form ubah password
///   - UserListCard       → daftar tim EDP + search + delete
///
/// Page ini hanya bertugas:
///   1. Membuat dan menghubungkan controller
///   2. Mendengarkan notifikasi dari controller → tampilkan Snackbar
///   3. Merangkai layout dari widget-widget modular
///
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _ctrl = ProfileController();

  // UI-only controllers — tetap di Page karena terkait lifecycle widget.
  final _searchUserCtrl = TextEditingController();
  final _userListScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
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
    _searchUserCtrl.dispose();
    _userListScrollCtrl.dispose();
    super.dispose();
  }

  /// Listener tunggal untuk semua perubahan controller.
  void _onControllerChanged() {
    if (!mounted) return;

    // Ambil notifikasi SEBELUM setState agar tidak hilang di rebuild.
    final notification = _ctrl.pendingNotification;
    if (notification != null) {
      _ctrl.clearNotification();
    }

    setState(() {});

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
          ? _buildLoadingOverlay()
          : PageEntryTransition(
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
                          ProfileHeroCard(
                            onClearCache: _ctrl.clearAppCache,
                          ),
                          const SizedBox(height: 24),

                          const SectionHeader(
                            title: "KEAMANAN AKUN",
                            icon: Icons.shield_outlined,
                          ),
                          const SizedBox(height: 12),
                          SecurityCard(
                            obscureOld: _ctrl.obscureOldPass,
                            obscureNew: _ctrl.obscureNewPass,
                            onToggleOldVisibility:
                                _ctrl.toggleOldPassVisibility,
                            onToggleNewVisibility:
                                _ctrl.toggleNewPassVisibility,
                            onSubmit: _ctrl.updatePassword,
                          ),
                          const SizedBox(height: 24),

                          const SectionHeader(
                            title: "DAFTAR TIM EDP",
                            icon: Icons.group_outlined,
                          ),
                          const SizedBox(height: 12),
                          UserListCard(
                            users: _ctrl.filteredUsers,
                            isLoading: _ctrl.isLoadingUsers,
                            searchController: _searchUserCtrl,
                            scrollController: _userListScrollCtrl,
                            onSearch: _ctrl.filterUsers,
                            onDeleteUser: _ctrl.executeDeleteUser,
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }


  // ── WIDGET KECIL — tetap di Page karena sangat sederhana ──────

  Widget _buildLoadingOverlay() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Memproses...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: context.isDesktop
          ? null
          : const Center(child: AppHamburgerButton()),
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
          Text(
            "PROFIL SAYA",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
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
