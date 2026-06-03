import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'sidebar_item.dart';

class SidebarFooter extends StatelessWidget {
  final VoidCallback onLogoutTap;

  const SidebarFooter({
    super.key,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 1,
          color: context.borderColor,
        ),
        const SizedBox(height: 8),
        SidebarItem(
          icon: Icons.logout_outlined,
          label: 'Keluar Aplikasi',
          iconColor: const Color(0xFFFF6B6B),
          labelColor: const Color(0xFFFF6B6B),
          onTap: onLogoutTap,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
