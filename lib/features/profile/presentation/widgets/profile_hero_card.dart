import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../helpers/role_style.dart';

/// ProfileHeroCard — menampilkan avatar, nama, role, NIK user yang login.
///
/// Lokasi: features/profile/presentation/widgets/profile_hero_card.dart
///
class ProfileHeroCard extends StatelessWidget {
  final VoidCallback onClearCache;

  const ProfileHeroCard({super.key, required this.onClearCache});

  @override
  Widget build(BuildContext context) {
    final roleStyle = RoleStyle.fromRole(
      AuthState.instance.role,
      fallbackAccent: context.accentColor,
    );
    final initials = RoleStyle.initialsFrom(AuthState.instance.name);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: roleStyle.accent.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── ATAS: gradient banner + avatar ───────────────────
          _buildBannerSection(context, roleStyle, initials),

          // ── BAWAH: quick actions ────────────────────────────
          _buildActionsSection(context),
        ],
      ),
    );
  }

  Widget _buildBannerSection(
    BuildContext context,
    RoleStyle roleStyle,
    String initials,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleStyle.accent.withOpacity(0.13),
            context.accentColor.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final avatar = _buildAvatar(context, roleStyle, initials);
          final info = _buildInfo(context, roleStyle);

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(width: 20),
                      Expanded(child: info),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [avatar, const SizedBox(height: 16), info],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    RoleStyle roleStyle,
    String initials,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [roleStyle.accent, roleStyle.accent.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: roleStyle.accent.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: roleStyle.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: roleStyle.accent.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(roleStyle.icon, size: 14, color: roleStyle.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, RoleStyle roleStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AuthState.instance.name,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: roleStyle.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleStyle.accent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleStyle.icon, size: 11, color: roleStyle.accent),
              const SizedBox(width: 5),
              Text(
                roleStyle.label,
                style: TextStyle(
                  color: roleStyle.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // NIK row
        Row(
          children: [
            Icon(Icons.badge_outlined, size: 13, color: context.textSecondary),
            const SizedBox(width: 5),
            Text(
              'NIK  ',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
            Text(
              AuthState.instance.nik,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: onClearCache,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFB347).withOpacity(0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cleaning_services_outlined,
                  size: 14,
                  color: Color(0xFFFFB347),
                ),
                SizedBox(width: 6),
                Text(
                  'Clear Cache',
                  style: TextStyle(
                    color: Color(0xFFFFB347),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
