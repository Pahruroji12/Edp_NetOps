import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

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

/// Warna berdasarkan kategori aksi log.
Color logFilterColor(String action) {
  if (action.contains('LOGIN')) return const Color(0xFF00E676);
  if (action.contains('LOGOUT')) return const Color(0xFFFFB347);
  if (action.contains('TAMBAH')) return const Color(0xFF54C5F8);
  if (action.contains('EDIT')) return const Color(0xFF00D4FF);
  if (action.contains('HAPUS')) return const Color(0xFFFF6B6B);
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
