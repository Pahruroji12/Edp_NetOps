import 'package:flutter/material.dart';

class VersionInfoCard extends StatelessWidget {
  final String label;
  final String version;
  final Color color;
  final IconData icon;
  final bool isNew;

  const VersionInfoCard({
    super.key,
    required this.label,
    required this.version,
    required this.color,
    required this.icon,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isNew ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(isNew ? 0.25 : 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.7)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            version,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
