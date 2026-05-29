import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_sidebar.dart';
import '../core/theme/app_colors.dart'; // TODO: pindah ke core/theme/ nanti
import '../core/utils/responsive_helper.dart';

/// MainLayout — shell utama yang membungkus semua halaman dengan sidebar.
///
/// Lokasi: layout/main_layout.dart
///
class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  // GlobalKey statis — diakses halaman anak untuk buka drawer di mobile
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final String currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: context.surfaceColor,
      // Mobile: sidebar jadi drawer laci
      drawer: isDesktop ? null : AppSidebar(currentRoute: currentRoute),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Desktop: sidebar permanen di kiri
          if (isDesktop) AppSidebar(currentRoute: currentRoute),

          // Konten utama
          Expanded(child: child),
        ],
      ),
    );
  }
}
