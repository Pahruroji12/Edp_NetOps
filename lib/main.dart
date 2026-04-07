import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart'; // <-- 1. Import go_router

// --- Utils ---
import 'utils/app_colors.dart';
import 'utils/globals.dart';

// --- Screens & Layout ---
import 'screens/auth/login_page.dart';
import 'widgets/main_layout.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/store_management/store_list_page.dart';
import 'screens/store_management/ping_page.dart';
import 'screens/store_management/scan_wdcp_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/settings/settings_page.dart';
import 'screens/profile/admin_panel_page.dart';

// ==============================================================
// 2. KONFIGURASI GLOBAL ROUTER (go_router)
// ==============================================================
final GoRouter appRouter = GoRouter(
  initialLocation: '/login', // Halaman pertama yang dibuka
  routes: [
    // --- Rute STANDALONE (Tanpa Sidebar, misal: Login) ---
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    // --- Rute DENGAN SIDEBAR (Dibungkus ShellRoute) ---
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/store-list',
          builder: (context, state) => const StoreListPage(),
        ),
        GoRoute(path: '/ping', builder: (context, state) => const PingPage()),
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
      ],
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // SUPABASE CONFIGURATION
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Bungkus MaterialApp dengan ValueListenableBuilder untuk memantau perubahan tema
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        // 2. gabungkan Tema Terang dengan settingan Compact
        final lightThemeWithCompact = AppThemes.lightTheme.copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(),
          ),
        );

        // 3. gabungkan Tema Gelap dengan settingan Compact
        final darkThemeWithCompact = AppThemes.darkTheme.copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(),
          ),
        );

        // 4. Ubah MaterialApp menjadi MaterialApp.router
        return MaterialApp.router(
          title: 'EDP NetOps',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: globalMessengerKey,

          // --- Tema ---
          theme: lightThemeWithCompact, // Mode Terang
          darkTheme: darkThemeWithCompact, // Mode Gelap
          themeMode: currentMode, // Trigger otomatis ketika switch ditekan
          // --- Konfigurasi go_router ---
          routerConfig:
              appRouter, // <-- 5. Sambungkan ke GoRouter yang dibuat di atas
          // CATATAN: 'home: const LoginPage(),' dihapus karena sudah diurus oleh go_router
        );
      },
    );
  }
}
