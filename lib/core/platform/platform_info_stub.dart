/// Stub — default fallback. Tidak pernah dipakai langsung.
/// Dioverride oleh platform_info_io.dart atau platform_info_web.dart.

bool get nativeIsWindows => false;
bool get nativeIsAndroid => false;
bool get nativeIsIOS => false;
bool get nativeIsMacOS => false;
bool get nativeIsLinux => false;
String get nativePlatformName => 'Unknown';
String get nativePathSeparator => '/';
String get nativeResolvedExecutable => '';
String get nativeCurrentDirectoryPath => '.';
