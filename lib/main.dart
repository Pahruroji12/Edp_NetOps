import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_page.dart';
import 'utils/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/globals.dart';

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

        // 3.  gabungkan Tema Gelap dengan settingan Compact
        final darkThemeWithCompact = AppThemes.darkTheme.copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(),
          ),
        );

        return MaterialApp(
          title: 'EDP NetOps',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: globalMessengerKey,
          // 4. Daftarkan tema yang sudah digabung
          theme: lightThemeWithCompact, // Mode Terang
          darkTheme: darkThemeWithCompact, // Mode Gelap
          themeMode: currentMode, // Trigger otomatis ketika switch ditekan

          home: const LoginPage(),
        );
      },
    );
  }
}
