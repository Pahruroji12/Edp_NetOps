import 'package:flutter/material.dart';

/// RoleStyle — mapping terpusat role → warna, ikon, label.
///
/// Lokasi: features/profile/presentation/helpers/role_style.dart
///
/// Ini adalah UI helper, BUKAN domain entity.
/// Berada di presentation layer karena menggunakan Color, IconData
/// (dependency Flutter/Material).
///
/// Menghilangkan duplikasi switch/if role di banyak widget profile.
///
class RoleStyle {
  final Color accent;
  final Color background;
  final IconData icon;
  final String label;

  const RoleStyle({
    required this.accent,
    required this.background,
    required this.icon,
    required this.label,
  });

  /// Style untuk hero card / profile utama.
  factory RoleStyle.fromRole(String role, {Color? fallbackAccent}) {
    switch (role.toLowerCase()) {
      case 'administrator':
        return const RoleStyle(
          accent: Color(0xFFFF6B6B),
          background: Color(0xFF2A1520),
          icon: Icons.admin_panel_settings_outlined,
          label: 'ADMINISTRATOR',
        );
      case 'admin':
        return const RoleStyle(
          accent: Color(0xFFFFB347),
          background: Color(0xFF241D10),
          icon: Icons.manage_accounts_outlined,
          label: 'ADMIN',
        );
      default:
        return RoleStyle(
          accent: fallbackAccent ?? const Color(0xFF00D4FF),
          background: const Color(0xFF0A2030),
          icon: Icons.person_outline,
          label: 'USER',
        );
    }
  }

  /// Style untuk list item (ikon lebih compact).
  factory RoleStyle.forListItem(String role, {Color? fallbackAccent}) {
    switch (role.toLowerCase()) {
      case 'administrator':
        return const RoleStyle(
          accent: Color(0xFFFF6B6B),
          background: Color(0xFF2A1520),
          icon: Icons.shield_outlined,
          label: 'ADMINISTRATOR',
        );
      case 'admin':
        return const RoleStyle(
          accent: Color(0xFFFFB347),
          background: Color(0xFF241D10),
          icon: Icons.manage_accounts_outlined,
          label: 'ADMIN',
        );
      default:
        return RoleStyle(
          accent: fallbackAccent ?? const Color(0xFF00D4FF),
          background: const Color(0xFF0A2030),
          icon: Icons.person_outline,
          label: 'USER',
        );
    }
  }

  /// Ambil inisial dari nama (maks 2 huruf).
  static String initialsFrom(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
