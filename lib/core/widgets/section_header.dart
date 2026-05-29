import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// SectionHeader — reusable section header widget.
///
/// Lokasi: core/widgets/section_header.dart
///
/// Menggantikan _buildSectionHeader() yang sebelumnya duplicated di:
///   - profile_page.dart
///   - ftp_page.dart
///   - settings_page.dart
///   - about_page.dart
///   - ping_page.dart
///   - scan_wdcp_page.dart
///
/// Contoh pemakaian:
///   SectionHeader(title: "KEAMANAN AKUN", icon: Icons.shield_outlined)
///   SectionHeader(title: "TRANSFER FILE", icon: Icons.swap_horiz_rounded, trailing: myButton)
///
class SectionHeader extends StatelessWidget {
  /// Label teks section (uppercase recommended).
  final String title;

  /// Icon di kiri teks.
  final IconData icon;

  /// Subtitle opsional — ditampilkan di bawah title jika diberikan.
  final String? subtitle;

  /// Widget opsional di kanan — misalnya badge, counter, atau tombol kecil.
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.accentColor),
        const SizedBox(width: 8),
        if (subtitle == null)
          Text(
            title,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
