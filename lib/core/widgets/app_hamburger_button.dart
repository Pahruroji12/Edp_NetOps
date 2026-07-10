import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/layout/main_layout.dart';

/// AppHamburgerButton — Tombol menu hamburger global yang seragam.
/// Berbentuk kotak bordered dengan ukuran tetap 36x36 dan ikon menu_rounded.
class AppHamburgerButton extends StatelessWidget {
  const AppHamburgerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MainLayout.scaffoldKey.currentState?.openDrawer(),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderColor),
          ),
          child: Icon(
            Icons.menu_rounded,
            color: context.textPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
