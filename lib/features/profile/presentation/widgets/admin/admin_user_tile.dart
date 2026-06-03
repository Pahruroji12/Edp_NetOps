import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/features/profile/presentation/helpers/role_style.dart';

class AdminUserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isLast;

  const AdminUserTile({
    super.key,
    required this.user,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = user['is_online'] == true;
    final nama = user['nama'] ?? 'Unknown';
    final nik = user['nik'] ?? '-';
    final role = (user['role'] ?? 'user').toString();

    final roleStyle = RoleStyle.fromRole(role, fallbackAccent: context.accentColor);
    final roleColor = roleStyle.accent;
    final roleIcon = roleStyle.icon;
    final initials = RoleStyle.initialsFrom(nama);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: roleColor.withOpacity(0.25)),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(roleIcon, size: 10, color: roleColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 11,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          nik,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Role badge + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF00E676)
                              : context.textSecondary.withOpacity(0.4),
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00E676,
                                    ).withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF00E676)
                              : context.textSecondary.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: context.borderColor,
          ),
      ],
    );
  }
}
