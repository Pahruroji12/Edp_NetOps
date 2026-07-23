import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/utils/responsive_helper.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool isActive;
  final bool isSubMenu;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.isActive = false,
    this.isSubMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isSubMenu ? 28 : 12,
        right: 12,
        bottom: 2,
        top: 2,
      ),
      decoration: isActive
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            )
          : BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: isActive ? context.accentColor.withOpacity(0.08) : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12 * context.scaleFactor,
            vertical: 0,
          ),
          dense: context.isCompact,
          visualDensity: context.isCompact ? VisualDensity.compact : VisualDensity.standard,
          leading: Icon(
            icon,
            color: isActive
                ? context.accentColor
                : (iconColor ?? context.textSecondary),
            size: isSubMenu ? 18 : 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? context.accentColor
                  : (labelColor ?? context.textPrimary),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class SidebarDropdown extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final List<Widget> children;

  const SidebarDropdown({
    super.key,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        iconColor: context.accentColor,
        collapsedIconColor: context.textSecondary,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            icon,
            size: 20,
            color: isExpanded ? context.accentColor : context.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
            color: isExpanded ? context.accentColor : context.textPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }
}
