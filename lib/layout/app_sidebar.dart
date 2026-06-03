import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/utils/responsive_helper.dart';
import 'package:edp_netops/core/widgets/confirm_dialog.dart';
import 'package:edp_netops/core/widgets/custom_snackbar.dart';
import 'package:edp_netops/core/error/failures.dart';
import 'package:edp_netops/core/permissions/feature_access.dart';
import 'package:edp_netops/core/platform/feature_availability.dart';
import 'package:edp_netops/features/auth/data/auth_repository.dart';

import 'widgets/sidebar_item.dart';
import 'widgets/sidebar_header.dart';
import 'widgets/sidebar_footer.dart';
import 'widgets/sidebar_collapse_button.dart';
import 'widgets/mobile_navigation_drawer.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute; // Penanda menu mana yang sedang aktif

  const AppSidebar({super.key, required this.currentRoute});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  // ==========================================
  // FUNGSI LOGOUT
  // ==========================================
  Future<void> _logout(BuildContext ctx) async {
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
      final isDesktop = context.isDesktop;
      if (!isDesktop) {
        Navigator.of(context).pop(); // Tutup drawer
      }

      // Delay agar drawer animation selesai sebelum navigasi
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        _logout(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    final menuContent = Column(
      children: [
        const SidebarHeader(),
        const SidebarCollapseButton(),
        const SizedBox(height: 12),

        // ── MENU LIST ──
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SidebarItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                isActive: widget.currentRoute == '/dashboard',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/dashboard');
                },
              ),
              SidebarItem(
                icon: Icons.store_outlined,
                label: 'Data Toko',
                isActive: widget.currentRoute == '/store-list',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/store-list');
                },
              ),
              SidebarItem(
                icon: Icons.confirmation_number_outlined,
                label: 'History Ticket',
                isActive: widget.currentRoute == '/ticket-history',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/ticket-history');
                },
              ),

              // ── GRUP 1: NETWORK TOOLS ──
              if (FeatureAccess.canShowNetworkTools &&
                  FeatureAvailability.canUseNetworkTools) ...[
                const SizedBox(height: 8),
                SidebarDropdown(
                  title: 'Network Tools',
                  icon: Icons.electrical_services_rounded,
                  isExpanded: [
                    '/ping',
                    '/scan-wdcp',
                  ].contains(widget.currentRoute),
                  children: [
                    if (FeatureAvailability.canUsePing)
                      SidebarItem(
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
                    if (FeatureAvailability.canUseWdcpScan)
                      SidebarItem(
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
              SidebarDropdown(
                title: 'Pengaturan & Sistem',
                icon: Icons.manage_accounts_outlined,
                isExpanded: [
                  '/profile',
                  '/settings',
                  '/admin',
                  '/about',
                ].contains(widget.currentRoute),
                children: [
                  SidebarItem(
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
                  if (FeatureAccess.canShowSettings)
                    SidebarItem(
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
                  if (FeatureAccess.canShowAdminPanel)
                    SidebarItem(
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
                  SidebarItem(
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

        SidebarFooter(onLogoutTap: _showLogoutDialog),
      ],
    );

    if (isDesktop) {
      return Container(
        width: context.sidebarWidth,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(right: BorderSide(color: context.borderColor)),
        ),
        child: menuContent,
      );
    } else {
      return MobileNavigationDrawer(child: menuContent);
    }
  }
}
