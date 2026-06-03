import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

class MobileNavigationDrawer extends StatelessWidget {
  final Widget child;

  const MobileNavigationDrawer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.surfaceColor,
      child: child,
    );
  }
}
