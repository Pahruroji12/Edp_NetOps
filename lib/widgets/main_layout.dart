import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_sidebar.dart'; // Sesuaikan path-nya
import '../utils/app_colors.dart'; // Sesuaikan path-nya

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  // ── GlobalKey statis — diakses halaman anak untuk buka drawer di mobile ──
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
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
