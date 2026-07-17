import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/guards/auth_guard.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/login_page.dart';
import '../layout/main_layout.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/store/presentation/pages/store_list_page.dart';
import '../features/ticket/presentation/ticket_history_page.dart';
import '../features/network_tools/ping/presentation/ping_page_loader.dart';
import '../features/reporting/stb24jam/presentation/stb24jam_page_loader.dart';
import '../features/reporting/sla_scraper/presentation/sla_scraper_page_loader.dart';
import '../features/network_tools/wdcp/presentation/scan_wdcp_page_loader.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/admin_panel_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/about_page.dart';
import '../core/widgets/unsupported_feature_page.dart';

/// AppRouter — semua konfigurasi GoRouter di satu tempat.
///
/// Lokasi: app/app_router.dart
///
/// Auth Guard Logic (via AuthGuard):
///   1. Belum login + bukan /login  → redirect ke /login
///   2. Sudah login + di /login     → redirect ke /dashboard
///   3. Bukan admin + route admin   → redirect ke /dashboard
///   4. Platform tidak support      → redirect ke /dashboard
///
/// Route protection menggunakan [AuthGuard.checkRoute] yang menggabungkan:
///   - Login check
///   - Permission check (role-based)
///   - Platform check (fitur support di platform ini?)
///

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',

  // ─── Refreshable — rebuild redirect saat AuthState berubah ────
  refreshListenable: AuthState.instance,

  // ─── Auth Guard (redirect) ────────────────────────────────────
  redirect: (BuildContext context, GoRouterState state) {
    final currentPath = state.matchedLocation;

    // Gunakan AuthGuard terpusat untuk semua validasi
    return AuthGuard.checkRoute(currentPath);
  },

  routes: [
    // ─── Standalone (tanpa sidebar) ──────────────────────────
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    // ─── Dengan sidebar (ShellRoute) ─────────────────────────
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/store-list',
          builder: (context, state) => const StoreListPage(),
        ),
        GoRoute(
          path: '/ticket-history',
          builder: (context, state) => const TicketHistoryPage(),
        ),
        GoRoute(path: '/ping', builder: (context, state) => const PingPage()),
        GoRoute(
          path: '/rekap-stb',
          builder: (context, state) => const Stb24JamPage(),
        ),
        GoRoute(
          path: '/rekap-sla',
          builder: (context, state) => const SlaScraperPage(),
        ),
        GoRoute(
          path: '/scan-wdcp',
          builder: (context, state) => const ScanWdcpPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminPanelPage(),
        ),
        GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
        GoRoute(
          path: '/unsupported-feature',
          builder: (context, state) {
            final featureName = state.uri.queryParameters['feature'] ?? 'Fitur';
            return UnsupportedFeaturePage(featureName: featureName);
          },
        ),
      ],
    ),
  ],
);
