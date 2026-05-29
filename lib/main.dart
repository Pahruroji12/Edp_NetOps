import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/env/env_loader.dart';
import 'core/platform/desktop_init.dart';

/// main.dart — entry point saja.
///
/// Tidak boleh ada widget, router, atau business logic di sini.
/// Hanya inisialisasi dan runApp.
///
/// Multi-platform safe:
///   - window_manager hanya di Desktop (via desktop_init conditional import)
///   - PingController.init() hanya di Windows (via desktop_init)
///   - EnvLoader multi-platform aware
///
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Window Manager (Desktop only — no-op di Web/Mobile) ────
  await initDesktopWindow();

  // ─── Environment & Supabase ─────────────────────────────────
  await EnvLoader.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // ─── Ping Controller (Windows only — no-op di Web/Mobile) ───
  await initPingController();

  runApp(const MyApp());
}
