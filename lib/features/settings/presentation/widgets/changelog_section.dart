import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

class ChangelogSection extends StatelessWidget {
  final String changelog;

  const ChangelogSection({
    super.key,
    required this.changelog,
  });

  List<String> get _changelogLines {
    return changelog
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _changelogLines;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: context.accentColor),
              const SizedBox(width: 6),
              Text(
                'Catatan Perubahan',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor.withOpacity(0.5)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: lines.isEmpty
                  ? Text(
                      changelog,
                      style: TextStyle(color: context.textPrimary, fontSize: 12, height: 1.6),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.map((line) {
                        final isBullet =
                            line.startsWith('-') || line.startsWith('•') || line.startsWith('*');
                        final cleanLine = isBullet ? line.substring(1).trim() : line;

                        if (isBullet) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: context.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cleanLine,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 11.5,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            line,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 11.5,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
