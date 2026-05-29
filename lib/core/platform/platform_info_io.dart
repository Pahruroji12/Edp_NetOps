/// Platform info — implementasi native (Desktop / Mobile).
/// Menggunakan dart:io yang hanya tersedia di non-Web.

import 'dart:io' show Platform, Directory;

bool get nativeIsWindows => Platform.isWindows;
bool get nativeIsAndroid => Platform.isAndroid;
bool get nativeIsIOS => Platform.isIOS;
bool get nativeIsMacOS => Platform.isMacOS;
bool get nativeIsLinux => Platform.isLinux;
String get nativePathSeparator => Platform.pathSeparator;
String get nativeResolvedExecutable => Platform.resolvedExecutable;
String get nativeCurrentDirectoryPath => Directory.current.path;

String get nativePlatformName {
  if (Platform.isWindows) return 'Windows';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  return 'Unknown';
}
