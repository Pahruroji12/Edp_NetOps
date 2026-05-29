/// native_io_web.dart — Stub classes pengganti dart:io untuk Web.
///
/// Class-class ini TIDAK akan pernah benar-benar dipakai di Web
/// karena semua fitur yang butuh dart:io sudah di-guard oleh
/// FeatureAvailability / FeatureAccess.
///
/// Tujuan: agar kode yang import dart:io tetap COMPILE di Web
/// tanpa error, meskipun tidak pernah dieksekusi.

// ignore_for_file: camel_case_types

class File {
  final String path;
  File(this.path);

  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<List<int>> readAsBytes() async => [];
  Future<File> writeAsBytes(List<int> bytes) async => this;
  Future<File> writeAsString(String contents) async => this;
  Directory get parent => Directory(path);
}

class Directory {
  final String path;
  Directory(this.path);

  static Directory get current => Directory('.');
  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

class Platform {
  static bool get isWindows => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static String get pathSeparator => '/';
  static String get resolvedExecutable => '';
  static Map<String, String> get environment => {};
}

class Process {
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
    String? workingDirectory,
  }) async {
    throw UnsupportedError('Process.run is not available on Web');
  }

  static Future<Process> start(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode = ProcessStartMode.normal,
    bool runInShell = false,
    String? workingDirectory,
  }) {
    throw UnsupportedError('Process.start is not available on Web');
  }
}

enum ProcessStartMode { normal, detached, inheritStdio, detachedWithStdio }

class ProcessResult {
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
  final int pid;
  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

class FileSystemException implements Exception {
  final String message;
  final String? path;
  const FileSystemException([this.message = '', this.path]);
  @override
  String toString() => 'FileSystemException: $message';
}

class Socket {
  static Future<Socket> connect(dynamic host, int port, {Duration? timeout}) {
    throw UnsupportedError('Socket is not available on Web');
  }

  void destroy() {}
  void close() {}
  void write(String data) {}
  void add(List<int> data) {}
}

class RawSocket {
  static Future<RawSocket> connect(dynamic host, int port, {Duration? timeout}) {
    throw UnsupportedError('RawSocket is not available on Web');
  }
}

class InternetAddress {
  final String address;
  InternetAddress(this.address);

  static Future<List<InternetAddress>> lookup(String host) async {
    throw UnsupportedError('InternetAddress.lookup is not available on Web');
  }
}

class IOException implements Exception {
  final String message;
  const IOException([this.message = '']);
}

class SocketException implements IOException {
  @override
  final String message;
  const SocketException(this.message);
}
