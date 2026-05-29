import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// AdminPanelWidgets — reusable UI components untuk AdminPanelPage.
///
/// Lokasi: features/profile/presentation/admin_panel_widgets.dart
///
/// Widget yang di-extract:
///   - AdminStatChip — badge statistik (Total, Online, Offline)
///   - AdminListHeader — header card dengan search + badge count
///   - AdminUserTile — baris data user
///   - AdminLogTile — baris data log aktivitas
///   - AdminLoadingWidget — spinner saat loading
///   - AdminEmptyWidget — pesan kosong
///   - AdminLogFilterChip — filter chip kategori log

// ══════════════════════════════════════════════════════════════
// STAT CHIP
// ══════════════════════════════════════════════════════════════

class AdminStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const AdminStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LIST HEADER (search + badge + title)
// ══════════════════════════════════════════════════════════════

class AdminListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String count;
  final Color countColor;
  final TextEditingController searchCtrl;
  final void Function(String) onSearch;
  final Future<void> Function() onRefresh;

  const AdminListHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.countColor,
    required this.searchCtrl,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 420;

        final titleWidget = Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withOpacity(0.25)),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final badgeWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: countColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: countColor.withOpacity(0.3)),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: countColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

        final searchWidget = SizedBox(
          width: isWide ? 180 : double.infinity,
          height: 36,
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: context.accentColor,
                selectionColor: context.accentColor.withOpacity(0.3),
                selectionHandleColor: context.accentColor,
              ),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: TextStyle(color: context.textPrimary, fontSize: 12),
              cursorColor: context.accentColor,
              decoration: InputDecoration(
                hintText: "Cari...",
                hintStyle: TextStyle(
                  color: context.textSecondary.withOpacity(0.5),
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: context.textSecondary,
                ),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 14,
                          color: context.textSecondary,
                        ),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: context.accentColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: context.borderColor)),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: titleWidget),
                    searchWidget,
                    const SizedBox(width: 10),
                    badgeWidget,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: titleWidget),
                        badgeWidget,
                      ],
                    ),
                    const SizedBox(height: 10),
                    searchWidget,
                  ],
                ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// USER TILE
// ══════════════════════════════════════════════════════════════

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
    final role = (user['role'] ?? 'user').toString().toUpperCase();

    Color roleColor;
    IconData roleIcon;
    if (role == 'ADMINISTRATOR') {
      roleColor = const Color(0xFFFF6B6B);
      roleIcon = Icons.admin_panel_settings_outlined;
    } else if (role == 'ADMIN') {
      roleColor = const Color(0xFFFFB347);
      roleIcon = Icons.manage_accounts_outlined;
    } else {
      roleColor = context.accentColor;
      roleIcon = Icons.person_outline;
    }

    final parts = nama.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : nama.isNotEmpty
            ? nama[0].toUpperCase()
            : 'U';

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
                      role,
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

// ══════════════════════════════════════════════════════════════
// LOG TILE
// ══════════════════════════════════════════════════════════════

class AdminLogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isLast;

  const AdminLogTile({
    super.key,
    required this.log,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final action = (log['action_type'] ?? '').toString().toUpperCase();
    final desc = log['description'] ?? 'Tidak ada deskripsi';
    final userName = log['user_name'] ?? '-';
    final userRole = (log['user_role'] ?? '').toString().toUpperCase();

    final rawDate = log['created_at'] != null
        ? DateTime.parse(log['created_at']).toLocal()
        : DateTime.now();
    final dateStr =
        "${rawDate.day.toString().padLeft(2, '0')}/${rawDate.month.toString().padLeft(2, '0')}/${rawDate.year}";
    final timeStr =
        "${rawDate.hour.toString().padLeft(2, '0')}:${rawDate.minute.toString().padLeft(2, '0')}";

    final color = logFilterColor(action);
    final icon = logIcon(action);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 11,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            "$userName · $userRole",
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time + badge
              SizedBox(
                width: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        action.length > 8
                            ? action.substring(0, 6)
                            : action,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: context.textSecondary.withOpacity(0.5),
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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

// ══════════════════════════════════════════════════════════════
// LOG FILTER CHIP
// ══════════════════════════════════════════════════════════════

class AdminLogFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AdminLogFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = logFilterColor(label);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withOpacity(0.15)
              : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? chipColor.withOpacity(0.5)
                : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : context.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LOADING WIDGET
// ══════════════════════════════════════════════════════════════

class AdminLoadingWidget extends StatelessWidget {
  final String message;

  const AdminLoadingWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: context.accentColor,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EMPTY WIDGET
// ══════════════════════════════════════════════════════════════

class AdminEmptyWidget extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyWidget({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: context.textSecondary.withOpacity(0.35)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS (shared between widgets)
// ══════════════════════════════════════════════════════════════

/// Warna berdasarkan kategori aksi log.
Color logFilterColor(String action) {
  if (action.contains('LOGIN')) return const Color(0xFF00E676);
  if (action.contains('LOGOUT')) return const Color(0xFFFFB347);
  if (action.contains('TAMBAH')) return const Color(0xFF54C5F8);
  if (action.contains('EDIT')) return const Color(0xFF00D4FF);
  if (action.contains('HAPUS')) return const Color(0xFFFF6B6B);
  // Fallback — SEMUA dan lainnya
  return const Color(0xFF00D4FF);
}

/// Icon berdasarkan kategori aksi log.
IconData logIcon(String action) {
  if (action.contains('LOGIN')) return Icons.login_rounded;
  if (action.contains('LOGOUT')) return Icons.logout_rounded;
  if (action.contains('TAMBAH')) return Icons.add_circle_outline;
  if (action.contains('EDIT')) return Icons.edit_outlined;
  if (action.contains('HAPUS')) return Icons.delete_outline;
  return Icons.info_outline;
}
