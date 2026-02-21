import 'package:flutter/material.dart';

// Variabel Global untuk mengontrol Tema (Default: Gelap)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class AppThemes {
  // ==========================================
  // TEMA GELAP (DARK MODE)
  // ==========================================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1F38), // surfaceColor
    primaryColor: const Color(0xFF0A1628),
    cardColor: const Color(0xFF162340),
    dividerColor: const Color(0xFF1E3A5F), // borderColor
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0A1628),
      secondary: Color(0xFF00D4FF), // accentColor
      tertiary: Color(0xFF6C63FF), // <-- INI DIA secondaryAccent (Ungu Neon)
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE8F4FF)), // textPrimary
      bodyMedium: TextStyle(color: Color(0xFF7A9CC4)), // textSecondary
    ),
  );

  // ==========================================
  // TEMA TERANG (LIGHT MODE)
  // ==========================================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Abu-abu muda
    primaryColor: const Color(0xFFFFFFFF),
    cardColor: const Color(0xFFFFFFFF),
    dividerColor: const Color(0xFFE5E7EB),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF007BFF), // Biru Terang
      tertiary: Color(
        0xFF5A52D5,
      ), // <-- secondaryAccent untuk tema terang (Ungu agak gelap)
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF111827)), // Hitam
      bodyMedium: TextStyle(color: Color(0xFF6B7280)), // Abu-abu
    ),
  );
}

// ==========================================
// EXTENSION BUILDCONTEXT
// ==========================================
extension ThemeColors on BuildContext {
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get accentColor => Theme.of(this).colorScheme.secondary;
  Color get secondaryAccent =>
      Theme.of(this).colorScheme.tertiary; // <-- SUDAH DITAMBAHKAN
  Color get surfaceColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get borderColor => Theme.of(this).dividerColor;
  Color get textPrimary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get textSecondary => Theme.of(this).textTheme.bodyMedium!.color!;

  Color get successColor => const Color(0xFF00E676);
  Color get dangerColor => const Color(0xFFFF6B6B);
  Color get warningColor => const Color(0xFFFFA726);
}

// import 'package:flutter/material.dart';

// class AppColors {
//   // --- WARNA TEMA UTAMA ---
//   static const primaryColor = Color(0xFF0A1628);
//   static const accentColor = Color(0xFF00D4FF);
//   static const secondaryAccent = Color(0xFF6C63FF);

//   // --- WARNA BACKGROUND & CARD ---
//   static const surfaceColor = Color(0xFF0F1F38);
//   static const cardColor = Color(0xFF162340);
//   static const borderColor = Color(0xFF1E3A5F);

//   // --- WARNA TEKS ---
//   static const textPrimary = Color(0xFFE8F4FF);
//   static const textSecondary = Color(0xFF7A9CC4);

//   // --- WARNA STATUS (Biasa dipakai di WDCP & Store Detail) ---
//   static const successColor = Color(0xFF00E676); // Hijau untuk Connected/Online
//   static const dangerColor = Color(
//     0xFFFF6B6B,
//   ); // Merah untuk Disconnected/Logout
//   static const warningColor = Color(0xFFFFA726); // Oranye untuk Loading/Pending
// }
