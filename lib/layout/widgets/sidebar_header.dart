import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/utils/responsive_helper.dart';
import 'package:edp_netops/features/auth/domain/auth_state.dart';

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Container(
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
    );
  }
}
