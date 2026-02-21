import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message, Color color) {
    _SnackConfig cfg;

    if (color == Colors.red || color == const Color(0xFFFF6B6B)) {
      cfg = const _SnackConfig(
        icon: Icons.error_rounded,
        title: "Gagal!",
        accentColor: Color(0xFFE53935),
        iconBg: Color(0xFFFFEBEE),
        leftBarColor: Color(0xFFE53935),
      );
    } else if (color == Colors.green || color == const Color(0xFF00E676)) {
      cfg = const _SnackConfig(
        icon: Icons.check_circle_rounded,
        title: "Berhasil!",
        accentColor: Color(0xFF2E7D32),
        iconBg: Color(0xFFE8F5E9),
        leftBarColor: Color(0xFF43A047),
      );
    } else if (color == Colors.orange || color == const Color(0xFFFFB347)) {
      cfg = const _SnackConfig(
        icon: Icons.warning_rounded,
        title: "Perhatian!",
        accentColor: Color(0xFFE65100),
        iconBg: Color(0xFFFFF3E0),
        leftBarColor: Color(0xFFFF6D00),
      );
    } else {
      // Info / Blue / Cyan / lainnya
      cfg = const _SnackConfig(
        icon: Icons.info_rounded,
        title: "Info",
        accentColor: Color(0xFF0277BD),
        iconBg: Color(0xFFE3F2FD),
        leftBarColor: Color(0xFF0288D1),
      );
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 3),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cfg.accentColor.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 5,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cfg.leftBarColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cfg.iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(cfg.icon, color: cfg.accentColor, size: 22),
                ),

                const SizedBox(width: 12),

                // Teks
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cfg.title,
                          style: TextStyle(
                            color: cfg.accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFF424242),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      );
  }
}

class _SnackConfig {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Color iconBg;
  final Color leftBarColor;

  const _SnackConfig({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.iconBg,
    required this.leftBarColor,
  });
}
