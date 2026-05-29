import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/globals.dart';
import 'app_router.dart';

/// MyApp — root widget aplikasi.
///
/// Lokasi: app/app.dart
///
/// main.dart hanya memanggil runApp(const MyApp()) — tidak ada logic di sana.
///
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        const _inputTheme = InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(),
        );

        final lightTheme = AppThemes.lightTheme.copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: _inputTheme,
        );

        final darkTheme = AppThemes.darkTheme.copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: _inputTheme,
        );

        return MaterialApp.router(
          title: 'EDP NetOps',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: globalMessengerKey,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
