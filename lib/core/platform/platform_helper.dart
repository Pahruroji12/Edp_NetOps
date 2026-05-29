import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import — dart:io hanya di-load di non-Web
import 'platform_info_stub.dart'
    if (dart.library.io) 'platform_info_io.dart'
    if (dart.library.html) 'platform_info_web.dart';

/// PlatformHelper — abstraksi deteksi platform yang aman untuk semua target.
///
/// Lokasi: core/platform/platform_helper.dart
///
/// PENTING: File ini TIDAK boleh import dart:io langsung.
/// Gunakan conditional import via platform_info_*.dart.
///
/// Cara pakai:
///   if (PlatformHelper.isDesktop) { ... }
///   if (PlatformHelper.isWeb) { ... }
///   if (PlatformHelper.isMobile) { ... }
///
class PlatformHelper {
  PlatformHelper._();

  // ── Web Detection (aman, tanpa dart:io) ───────────────────────
  static bool get isWeb => kIsWeb;

  // ── Desktop Detection ─────────────────────────────────────────
  static bool get isWindows => !kIsWeb && nativeIsWindows;
  static bool get isMacOS => !kIsWeb && nativeIsMacOS;
  static bool get isLinux => !kIsWeb && nativeIsLinux;
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  // ── Mobile Detection ──────────────────────────────────────────
  static bool get isAndroid => !kIsWeb && nativeIsAndroid;
  static bool get isIOS => !kIsWeb && nativeIsIOS;
  static bool get isMobile => isAndroid || isIOS;

  // ── Human-readable label ──────────────────────────────────────
  static String get platformName {
    if (kIsWeb) return 'Web';
    return nativePlatformName;
  }

  // ── Path helpers (aman di Web — return defaults) ──────────────
  static String get pathSeparator => nativePathSeparator;
  static String get resolvedExecutable => nativeResolvedExecutable;
  static String get currentDirectoryPath => nativeCurrentDirectoryPath;
}
