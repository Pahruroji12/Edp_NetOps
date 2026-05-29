/// Platform info — implementasi Web.
/// Tidak menggunakan dart:io karena tidak tersedia di Web.

bool get nativeIsWindows => false;
bool get nativeIsAndroid => false;
bool get nativeIsIOS => false;
bool get nativeIsMacOS => false;
bool get nativeIsLinux => false;
String get nativePlatformName => 'Web';
String get nativePathSeparator => '/';
String get nativeResolvedExecutable => '';
String get nativeCurrentDirectoryPath => '.';
