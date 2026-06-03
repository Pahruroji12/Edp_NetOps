/// native_io_web.dart — Stub classes pengganti dart:io untuk Web.
///
/// Class-class ini TIDAK akan pernah benar-benar dipakai di Web
/// karena semua fitur yang butuh dart:io sudah di-guard oleh
/// FeatureAvailability / FeatureAccess.
///
/// Tujuan: agar kode yang import dart:io tetap COMPILE di Web
/// tanpa error, meskipun tidak pernah dieksekusi.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// ignore_for_file: camel_case_types

abstract class FileSystemEntity {
  String get path;
  FileStat statSync() => FileStat();
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
}

class FileStat {
  DateTime get modified => DateTime.now();
  int get size => 0;
}

class File extends FileSystemEntity {
  @override
  final String path;
  File(this.path);

  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<List<int>> readAsBytes() async => [];
  Future<File> writeAsBytes(List<int> bytes) async => this;
  Future<File> writeAsString(String contents) async => this;
  int lengthSync() => 0;
  Future<int> length() async => 0;
  DateTime lastModifiedSync() => DateTime.now();
  Directory get parent => Directory(path);

  Stream<Uint8List> openRead([int? start, int? end]) => const Stream.empty();
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) => _MockIOSink();
}

class Directory extends FileSystemEntity {
  @override
  final String path;
  Directory(this.path);

  static Directory get current => Directory('.');
  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Directory createSync({bool recursive = false}) => this;
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) => [];
  Directory get parent => Directory(path);
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

enum FileMode { read, write, append, writeOnly, writeOnlyAppend }

abstract class IOSink {
  void add(List<int> data);
  void addError(Object error, [StackTrace? stackTrace]);
  Future<void> addStream(Stream<List<int>> stream);
  Future<void> close();
  Future<void> get done;
  Future<void> flush();
  void write(Object? obj);
  void writeAll(Iterable objects, [String separator = ""]);
  void writeCharCode(int charCode);
  void writeln([Object? obj = ""]);
  Encoding get encoding;
  set encoding(Encoding encoding);
}

class _MockIOSink implements IOSink {
  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => Completer<void>().future;

  @override
  Future<void> flush() async {}

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = ""]) {}

  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding encoding) {}
}

class Socket extends Stream<Uint8List> implements IOSink {
  static Future<Socket> connect(dynamic host, int port, {Duration? timeout}) {
    throw UnsupportedError('Socket is not available on Web');
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw UnsupportedError('Socket is not available on Web');
  }

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> close() async {}

  void destroy() {}

  @override
  Future<void> get done => Completer<void>().future;

  @override
  Future<void> flush() async {}

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = ""]) {}

  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding encoding) {}
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

class SecureSocket extends Socket {
  static Future<SecureSocket> connect(
    dynamic host,
    int port, {
    Duration? timeout,
    bool Function(X509Certificate)? onBadCertificate,
  }) {
    throw UnsupportedError('SecureSocket is not available on Web');
  }
}

class X509Certificate {
  String get subject => '';
  String get issuer => '';
}

class TimeoutException implements Exception {
  final String? message;
  final Duration? duration;
  const TimeoutException(this.message, [this.duration]);
  @override
  String toString() => 'TimeoutException: $message';
}

class LineSplitter extends StreamTransformerBase<String, String> {
  const LineSplitter();

  static List<String> split(String data) => data.split('\n');

  @override
  Stream<String> bind(Stream<String> stream) {
    return stream.expand((chunk) => chunk.split('\n'));
  }
}

class HttpClient {
  Duration connectionTimeout = const Duration(seconds: 30);
  String userAgent = '';
  HttpClient();

  Future<HttpClientRequest> getUrl(Uri url) {
    throw UnsupportedError('HttpClient is not available on Web');
  }

  void close({bool force = false}) {}
}

class HttpHeaders {
  void add(String name, Object value) {}
  void set(String name, Object value) {}
  void remove(String name, Object value) {}
  void clear() {}
}

class HttpClientRequest {
  final HttpHeaders headers = HttpHeaders();

  Future<HttpClientResponse> close() {
    throw UnsupportedError('HttpClientRequest is not available on Web');
  }
}

class HttpClientResponse extends Stream<List<int>> {
  int get contentLength => 0;
  int get statusCode => 0;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw UnsupportedError('HttpClientResponse is not available on Web');
  }
}

void exit(int code) {
  throw UnsupportedError('exit() is not available on Web');
}
