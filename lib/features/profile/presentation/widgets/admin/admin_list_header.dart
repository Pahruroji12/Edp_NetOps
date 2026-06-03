import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

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
