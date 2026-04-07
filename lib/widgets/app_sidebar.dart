import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Utils & Warna ---
import '../utils/app_colors.dart';
import '../utils/activity_logger.dart';
import '../screens/auth/login_page.dart';

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
  Future<void> _logout(BuildContext context) async {
    try {
      await ActivityLogger.updateOnlineStatus(false);
      await ActivityLogger.logAction(
        actionType: "LOGOUT",
        description: "Pengguna keluar dari sistem",
      );
      await Supabase.instance.client.auth.signOut();
      currentUserNik = '';
      currentUserName = '';
      currentUserRole = '';
      if (!context.mounted) return;
      context.go('/login'); // go_router — hapus semua history
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal logout: $e")));
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1520),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_outlined,
                        color: Color(0xFFFF6B6B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Keluar Aplikasi?",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Apakah Anda yakin ingin keluar dari aplikasi EDP NetOps?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _logout(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Ya, Keluar",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // KUNCI RESPONSIF: Cek apakah lebar layar >= 850 (PC/Laptop)
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    // --- Logika Warna & Inisial Role ---
    Color roleAccentD;
    IconData roleIconD;
    switch (currentUserRole.toLowerCase()) {
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

    final nameParts = currentUserName.trim().split(' ');
    final initialsD = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'U';

    final isAdmin = currentUserRole.toLowerCase() == 'administrator';

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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                            width: 60,
                            height: 60,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
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
                    currentUserName.isNotEmpty ? currentUserName : 'User',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
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
                        currentUserNik,
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
                          currentUserRole.toUpperCase(),
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

              const SizedBox(height: 8),

              // ── GRUP 1: NETWORK TOOLS ──
              _buildDrawerDropdown(
                title: 'Network Tools',
                icon: Icons.electrical_services_rounded,
                isExpanded: [
                  '/ping',
                  '/scan-wdcp',
                ].contains(widget.currentRoute),
                children: [
                  if (Platform.isWindows)
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

              const SizedBox(height: 8),

              // ── GRUP 2: PENGATURAN & SISTEM ──
              _buildDrawerDropdown(
                title: 'Pengaturan & Sistem',
                icon: Icons.manage_accounts_outlined,
                isExpanded: [
                  '/profile',
                  '/settings',
                  '/admin',
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
                  if (isAdmin) ...[
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
                  ],
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
            if (!isDesktop) Navigator.pop(context); // Tutup drawer kalau di HP
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
      // Tampilan PC: Sidebar Permanen Kiri
      return Container(
        width: 270,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
