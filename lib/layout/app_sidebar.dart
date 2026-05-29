import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/responsive_helper.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/custom_snackbar.dart';
import '../core/error/failures.dart';
import '../core/permissions/feature_access.dart';
import '../core/platform/feature_availability.dart';

import '../features/auth/domain/auth_state.dart'; // ← ganti login_page import
import '../features/auth/data/auth_repository.dart'; // ← logout lewat repository

class AppSidebar extends StatefulWidget {
  final String currentRoute; // Penanda menu mana yang sedang aktif

  const AppSidebar({super.key, required this.currentRoute});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  // ==========================================
  // FUNGSI LOGOUT (Dari desain Mas Pahruroji)
  // ==========================================
  Future<void> _logout(BuildContext ctx) async {
    // Simpan referensi router sebelum async gap — context bisa mati kapan saja
    final router = GoRouter.of(ctx);

    final result = await AuthRepository().signOut();

    result.fold(
      (Failure failure) {
        CustomSnackBar.error('Gagal logout: ${failure.message}');
      },
      (_) {
        router.go('/login');
      },
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar Aplikasi?',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi EDP NetOps?',
      confirmLabel: 'Ya, Keluar',
      cancelLabel: 'Batal',
      icon: Icons.logout_outlined,
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      // Tutup drawer SETELAH dialog selesai, SEBELUM logout
      // agar context masih valid saat showConfirmDialog berjalan
      final isDesktop = context.isDesktop;
      if (!isDesktop) {
        Navigator.of(context).pop(); // Tutup drawer
      }

      // Sedikit delay agar drawer animation selesai sebelum navigasi
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        _logout(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // KUNCI RESPONSIF: Gunakan ResponsiveHelper
    final isDesktop = context.isDesktop;
    final sf = context.scaleFactor;

    // ─── Ambil data user dari AuthState ──────────────────────────
    final userRole = AuthState.instance.role;
    final userName = AuthState.instance.name;
    final userNik = AuthState.instance.nik;

    // --- Logika Warna & Inisial Role ---
    Color roleAccentD;
    IconData roleIconD;
    switch (userRole.toLowerCase()) {
      case 'administrator':
        roleAccentD = const Color(0xFFFF6B6B);
        roleIconD = Icons.admin_panel_settings_outlined;
        break;
      case 'admin':
        roleAccentD = const Color(0xFFFFB347);
        roleIconD = Icons.manage_accounts_outlined;
        break;
      default:
        roleAccentD = context.accentColor;
        roleIconD = Icons.person_outline;
    }

    final nameParts = userName.trim().split(' ');
    final initialsD = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : userName.isNotEmpty
        ? userName[0].toUpperCase()
        : 'U';

    // ==========================================
    // KONTEN MENU UTAMA
    // ==========================================
    final menuContent = Column(
      children: [
        // ── HEADER DRAWER ──
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [roleAccentD.withOpacity(0.13), context.cardColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(bottom: BorderSide(color: context.borderColor)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * sf, 20 * sf, 16 * sf, 16 * sf),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48 * sf,
                            height: 48 * sf,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  roleAccentD,
                                  roleAccentD.withOpacity(0.55),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: roleAccentD.withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initialsD,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18 * sf,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -5,
                            bottom: -5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: roleAccentD.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                roleIconD,
                                size: 12,
                                color: roleAccentD,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00E676).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00E676,
                                    ).withOpacity(0.7),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName.isNotEmpty ? userName : 'User',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: context.scaledFont(14),
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 12,
                        color: context.textSecondary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        userNik,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: roleAccentD.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: roleAccentD.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIconD, size: 11, color: roleAccentD),
                        const SizedBox(width: 6),
                        Text(
                          userRole.toUpperCase(),
                          style: TextStyle(
                            color: roleAccentD,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── MENU LIST ──
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerTile(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                isActive: widget.currentRoute == '/dashboard',
                onTap: () {
                  if (!isDesktop)
                    Navigator.pop(context); // Tutup laci kalau di HP
                  context.go('/dashboard');
                },
              ),
              _buildDrawerTile(
                icon: Icons.store_outlined,
                label: 'Data Toko',
                isActive: widget.currentRoute == '/store-list',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/store-list');
                },
              ),

              _buildDrawerTile(
                icon: Icons.confirmation_number_outlined,
                label: 'History Ticket',
                isActive: widget.currentRoute == '/ticket-history',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/ticket-history');
                },
              ),

              // ── GRUP 1: NETWORK TOOLS ──
              // Hanya muncul jika:
              //   1. Platform mendukung (Desktop only, bukan Android/Web)
              //   2. Role adalah admin/administrator
              if (FeatureAccess.canShowNetworkTools) ...[
                const SizedBox(height: 8),

                _buildDrawerDropdown(
                  title: 'Network Tools',
                  icon: Icons.electrical_services_rounded,
                  isExpanded: [
                    '/ping',
                    '/scan-wdcp',
                  ].contains(widget.currentRoute),
                  children: [
                    // Ping Scanner — hanya di Windows
                    if (FeatureAvailability.canUsePing)
                      _buildDrawerTile(
                        icon: Icons.network_check,
                        label: 'Ping Scanner',
                        isActive: widget.currentRoute == '/ping',
                        isSubMenu: true,
                        onTap: () {
                          if (!isDesktop) Navigator.pop(context);
                          if (widget.currentRoute != '/ping') {
                            context.go('/ping');
                          }
                        },
                      ),
                    // Scan RbWDCP — Desktop only
                    if (FeatureAvailability.canUseWdcpScan)
                      _buildDrawerTile(
                        icon: Icons.security_rounded,
                        label: 'Scan RbWDCP',
                        isActive: widget.currentRoute == '/scan-wdcp',
                        isSubMenu: true,
                        onTap: () {
                          if (!isDesktop) Navigator.pop(context);
                          if (widget.currentRoute != '/scan-wdcp') {
                            context.go('/scan-wdcp');
                          }
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // ── GRUP 2: PENGATURAN & SISTEM ──
              _buildDrawerDropdown(
                title: 'Pengaturan & Sistem',
                icon: Icons.manage_accounts_outlined,
                isExpanded: [
                  '/profile',
                  '/settings',
                  '/admin-panel',
                  '/about',
                ].contains(widget.currentRoute),
                children: [
                  _buildDrawerTile(
                    icon: Icons.person_outline,
                    label: 'Profil Saya',
                    isActive: widget.currentRoute == '/profile',
                    isSubMenu: true,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      if (widget.currentRoute != '/profile') {
                        context.go('/profile');
                      }
                    },
                  ),
                  // Settings — hanya administrator (super admin)
                  if (FeatureAccess.canShowSettings)
                    _buildDrawerTile(
                      icon: Icons.settings_outlined,
                      label: 'Setting',
                      isActive: widget.currentRoute == '/settings',
                      isSubMenu: true,
                      onTap: () {
                        if (!isDesktop) Navigator.pop(context);
                        if (widget.currentRoute != '/settings') {
                          context.go('/settings');
                        }
                      },
                    ),
                  // Control Center — hanya administrator (super admin)
                  if (FeatureAccess.canShowAdminPanel)
                    _buildDrawerTile(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Control Center',
                      isActive: widget.currentRoute == '/admin',
                      isSubMenu: true,
                      onTap: () {
                        if (!isDesktop) Navigator.pop(context);
                        if (widget.currentRoute != '/admin') {
                          context.go('/admin');
                        }
                      },
                    ),
                  _buildDrawerTile(
                    icon: Icons.info_outline,
                    label: 'Tentang Aplikasi',
                    isActive: widget.currentRoute == '/about',
                    isSubMenu: true,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      if (widget.currentRoute != '/about') {
                        context.go('/about');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── BAGIAN BAWAH (LOGOUT) ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 1,
          color: context.borderColor,
        ),
        const SizedBox(height: 8),
        _buildDrawerTile(
          icon: Icons.logout_outlined,
          label: 'Keluar Aplikasi',
          iconColor: const Color(0xFFFF6B6B),
          labelColor: const Color(0xFFFF6B6B),
          onTap: () {
            _showLogoutDialog();
          },
        ),
        const SizedBox(height: 24),
      ],
    );

    // ==========================================
    // RETURN WIDGET BERDASARKAN LAYAR
    // ==========================================
    if (isDesktop) {
      // Tampilan PC: Sidebar Permanen Kiri — lebar adaptive
      return Container(
        width: context.sidebarWidth,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(right: BorderSide(color: context.borderColor)),
        ),
        child: menuContent,
      );
    } else {
      // Tampilan HP: Laci yang bisa ditarik
      return Drawer(backgroundColor: context.surfaceColor, child: menuContent);
    }
  }

  // ==========================================
  // WIDGET HELPER
  // ==========================================
  Widget _buildDrawerDropdown({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        iconColor: context.accentColor,
        collapsedIconColor: context.textSecondary,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            icon,
            size: 20,
            color: isExpanded ? context.accentColor : context.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
            color: isExpanded ? context.accentColor : context.textPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    bool isActive = false,
    bool isSubMenu = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: isSubMenu ? 28 : 12,
        right: 12,
        bottom: 2,
        top: 2,
      ),
      decoration: isActive
          ? BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            )
          : BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12 * context.scaleFactor, vertical: 0),
        dense: context.isCompact,
        visualDensity: context.isCompact ? VisualDensity.compact : VisualDensity.standard,
        leading: Icon(
          icon,
          color: isActive
              ? context.accentColor
              : (iconColor ?? context.textSecondary),
          size: isSubMenu ? 18 : 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive
                ? context.accentColor
                : (labelColor ?? context.textPrimary),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
