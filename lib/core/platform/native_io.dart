/// native_io.dart — Conditional re-export of dart:io.
///
/// Pada Desktop/Mobile: re-export dart:io (File, Process, Directory, dll)
/// Pada Web: re-export stub classes yang aman (tidak crash)
///
/// CARA PAKAI:
///   // Ganti: import 'dart:io';
///   // Dengan:
///   import 'package:edp_netops/core/platform/native_io.dart';
///
export 'native_io_web.dart'
    if (dart.library.io) 'native_io_real.dart';
