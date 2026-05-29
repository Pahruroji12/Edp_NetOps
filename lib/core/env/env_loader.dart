import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../platform/platform_helper.dart';
import '../platform/native_io.dart';

/// EnvLoader — memuat file .env secara multi-platform.
///
/// Lokasi: core/env/env_loader.dart
///
/// Strategi per platform:
///   - Desktop: File `.env` di samping executable atau di CWD (production-safe)
///   - Mobile: File `.env` dari bundled asset (pubspec.yaml)
///   - Web: File `.env` dari bundled asset (pubspec.yaml)
///
/// Contoh pemakaian (di main.dart):
///   await EnvLoader.load();
///   final url = dotenv.env['SUPABASE_URL']!;
///
class EnvLoader {
  EnvLoader._();

  /// Muat .env sesuai platform yang sedang berjalan.
  static Future<void> load() async {
    if (PlatformHelper.isDesktop) {
      // Desktop: coba external file dulu (SECURITY: credentials tidak di-bundle)
      await _loadFromExternalFile();
    } else {
      // Mobile & Web: load dari bundled asset
      await _loadFromAsset();
    }
  }

  /// Load .env dari bundled asset.
  /// Dipakai oleh Mobile dan Web.
  ///
  /// Pastikan .env ada di pubspec.yaml:
  ///   flutter:
  ///     assets:
  ///       - .env
  static Future<void> _loadFromAsset() async {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('EnvLoader: loaded from bundled asset');
    } catch (e) {
      throw Exception(
        '.env file tidak ditemukan di assets.\n'
        'Pastikan file .env ditambahkan ke pubspec.yaml:\n'
        '  flutter:\n'
        '    assets:\n'
        '      - .env\n'
        '\nError: $e',
      );
    }
  }

  /// Load .env dari external file system (Desktop only).
  ///
  /// Strategi pencarian (urut prioritas):
  ///   1. File `.env` di samping executable  (release build)
  ///   2. File `.env` di root project / CWD   (debug / development)
  ///   3. Fallback ke bundled asset
  ///
  /// SECURITY: Credentials TIDAK ikut ter-bundle ke binary release.
  static Future<void> _loadFromExternalFile() async {
    final envFile = _resolveEnvFile();
    if (envFile == null) {
      // Fallback ke asset jika external file tidak ada
      debugPrint('EnvLoader: external .env not found, trying bundled asset...');
      try {
        await _loadFromAsset();
        return;
      } catch (_) {
        final exeDir = File(PlatformHelper.resolvedExecutable).parent.path;
        final cwdDir = PlatformHelper.currentDirectoryPath;
        throw FileSystemException(
          '.env file tidak ditemukan.\n'
          'Pastikan file .env ada di salah satu lokasi berikut:\n'
          '  1. Di samping executable: $exeDir\n'
          '  2. Di working directory: $cwdDir\n'
          '  3. Di assets (pubspec.yaml)\n',
        );
      }
    }

    final content = await envFile.readAsString();
    dotenv.loadFromString(envString: content);
    debugPrint('EnvLoader: loaded from ${envFile.path}');
  }

  /// Cari file .env di lokasi-lokasi yang valid.
  static File? _resolveEnvFile() {
    final sep = PlatformHelper.pathSeparator;

    // 1. Di samping executable (production / release)
    final exeDir = File(PlatformHelper.resolvedExecutable).parent.path;
    final exeEnv = File('$exeDir$sep.env');
    if (exeEnv.existsSync()) return exeEnv;

    // 2. Di current working directory (development / debug)
    final cwdDir = PlatformHelper.currentDirectoryPath;
    final cwdEnv = File('$cwdDir$sep.env');
    if (cwdEnv.existsSync()) return cwdEnv;

    return null;
  }
}
