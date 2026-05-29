import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// FTP client minimal untuk STB Android.
/// Tidak mengirim FEAT / OPTS UTF8 yang menyebabkan STB return 500.
/// Menggunakan satu listener permanen + antrian response agar tidak
/// ada race condition saat membaca reply dari socket kontrol.
class FtpClient {
  final String host;
  final int port;
  final String user;
  final String pass;
  final int timeout;

  Socket? _ctrl;
  StreamSubscription? _ctrlSub;
  String _lineBuffer = '';

  // Antrian completer — satu per perintah yang menunggu balasan
  final _responseQueue = <Completer<String>>[];

  FtpClient({
    required this.host,
    this.port = 21,
    required this.user,
    required this.pass,
    this.timeout = 15,
  });

  // ── Koneksi ───────────────────────────────────────────────────────────────

  Future<void> connect() async {
    _ctrl = await Socket.connect(
      host,
      port,
    ).timeout(Duration(seconds: timeout));

    // Satu listener permanen — parse setiap baris yang masuk
    _ctrlSub = _ctrl!.listen(
      (data) {
        _lineBuffer += latin1.decode(data);
        _processBuffer();
      },
      onError: (e) {
        for (final c in _responseQueue) {
          if (!c.isCompleted) c.completeError(FtpException('Socket error: $e'));
        }
        _responseQueue.clear();
      },
      onDone: () {
        for (final c in _responseQueue) {
          if (!c.isCompleted)
            c.completeError(FtpException('Connection closed'));
        }
        _responseQueue.clear();
      },
    );

    // Baca welcome 220
    await _waitResponse(expected: 220);

    // Login — tidak kirim FEAT atau OPTS
    await _cmd('USER $user', expected: 331);
    await _cmd('PASS $pass', expected: 230);

    // Binary mode
    await _cmd('TYPE I', expected: 200);
  }

  void _processBuffer() {
    while (true) {
      final idx = _lineBuffer.indexOf('\n');
      if (idx == -1) break;

      final line = _lineBuffer.substring(0, idx).trimRight(); // hapus \r
      _lineBuffer = _lineBuffer.substring(idx + 1);

      if (line.length < 3) continue;

      final code = line.substring(0, 3);
      if (int.tryParse(code) == null) continue;

      // Skip baris multi-line (format: "CODE-text")
      final isFinal = line.length == 3 || line[3] == ' ';
      if (!isFinal) continue;

      debugPrint('FTP ← $line');

      if (_responseQueue.isNotEmpty) {
        final c = _responseQueue.removeAt(0);
        if (!c.isCompleted) c.complete(line);
      }
    }
  }

  Future<String> _waitResponse({int? expected}) async {
    final c = Completer<String>();
    _responseQueue.add(c);
    final response = await c.future.timeout(
      Duration(seconds: timeout),
      onTimeout: () => throw FtpException('Timeout menunggu response dari STB'),
    );
    if (expected != null) {
      final code = int.tryParse(response.substring(0, 3)) ?? 0;
      if (code != expected) {
        throw FtpException('Expected $expected, got: $response');
      }
    }
    return response;
  }

  Future<String> _cmd(String command, {int? expected}) async {
    debugPrint('FTP → $command');
    _ctrl!.write('$command\r\n');
    return _waitResponse(expected: expected);
  }

  Future<void> disconnect() async {
    try {
      _ctrl!.write('QUIT\r\n');
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
    await _ctrlSub?.cancel();
    await _ctrl?.close();
    _ctrl = null;
  }

  // ── Passive data connection ───────────────────────────────────────────────

  Future<Socket> _pasv() async {
    final resp = await _cmd('PASV');
    // 227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)
    final m = RegExp(
      r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)',
    ).firstMatch(resp);
    if (m == null) throw FtpException('PASV parse gagal: $resp');

    final ip = '${m.group(1)}.${m.group(2)}.${m.group(3)}.${m.group(4)}';
    final dataPort = int.parse(m.group(5)!) * 256 + int.parse(m.group(6)!);
    debugPrint('FTP DATA → $ip:$dataPort');

    return Socket.connect(ip, dataPort).timeout(Duration(seconds: timeout));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> changeDirectory(String path) async {
    await _cmd('CWD $path', expected: 250);
  }

  Future<List<FtpEntry>> listDirectory() async {
    final data = await _pasv();
    await _cmd('LIST', expected: 150);

    final bytes = <int>[];
    final done = Completer<void>();
    data.listen(
      bytes.addAll,
      onDone: done.complete,
      onError: (_) => done.complete(),
    );
    await done.future.timeout(Duration(seconds: timeout));
    await data.close();
    await _waitResponse(expected: 226);

    return latin1
        .decode(bytes)
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .map(FtpEntry.parse)
        .whereType<FtpEntry>()
        .toList();
  }

  Future<void> uploadFile(
    File localFile,
    String remoteFileName, {
    void Function(double progress)? onProgress,
  }) async {
    final totalBytes = await localFile.length();
    final data = await _pasv();
    await _cmd('STOR $remoteFileName', expected: 150);

    int sentBytes = 0;

    // 1. Kita bungkus aliran datanya (stream) untuk memantau progress secara real-time
    final stream = localFile.openRead().map((chunk) {
      sentBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(sentBytes / totalBytes);
      }
      return chunk;
    });

    // 2. Gunakan addStream! Ini adalah KUNCI agar kecepatan baca hardisk
    //    otomatis direm menyesuaikan kecepatan transfer jaringan.
    await data.addStream(stream);

    // 3. Pastikan semua sisa data benar-benar terkirim sebelum ditutup
    await data.flush();
    await data.close();

    // 4. Tunggu jawaban sukses dari STB
    await _waitResponse(expected: 226);
  }

  Future<void> downloadFile(
    String remoteFileName,
    File localFile, {
    int totalBytes = 0,
    void Function(double progress)? onProgress,
  }) async {
    final data = await _pasv();
    await _cmd('RETR $remoteFileName', expected: 150);

    int receivedBytes = 0;
    final sink = localFile.openWrite();

    // 1. Kita pantau aliran data (stream) dari jaringan STB
    final stream = data.map((chunk) {
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes);
      }
      return chunk;
    });

    try {
      // 2. Gunakan addStream agar penulisan ke hardisk tersinkronisasi dengan baik!
      await sink.addStream(stream);
    } finally {
      // 3. Pastikan jalur file dan koneksi ditutup dengan aman, apapun yang terjadi
      await sink.flush();
      await sink.close();
      await data.close();
    }

    // 4. Tunggu jawaban sukses dari STB
    await _waitResponse(expected: 226);
  }

  /// Ambil ukuran file di remote (bytes). Return 0 kalau server tidak support.
  Future<int> getFileSize(String fileName) async {
    try {
      final resp = await _cmd('SIZE $fileName', expected: 213);
      // 213 <size>
      return int.tryParse(resp.substring(4).trim()) ?? 0;
    } catch (_) {
      return 0; // STB tidak support SIZE — progress tidak tersedia
    }
  }

  Future<void> deleteFile(String fileName) async {
    await _cmd('DELE $fileName', expected: 250);
  }
}

// ── Types ─────────────────────────────────────────────────────────────────────

class FtpEntry {
  final String name;
  final bool isDirectory;
  final int size;
  final String date; // contoh: "09 Mar 2026"

  const FtpEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
    this.date = '',
  });

  /// Parse baris LIST Unix-style:
  /// drwxrwxrwx  2 ftp ftp    4096 Jan  1 1980 OUTPUT
  /// -rwxrwxrwx  1 ftp ftp 1234567 Mar  4 2026 file.mp4
  static FtpEntry? parse(String line) {
    try {
      if (line.length < 10) return null;
      final isDir = line[0] == 'd';
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 9) return null;
      final name = parts.sublist(8).join(' ');
      if (name == '.' || name == '..') return null;
      final size = int.tryParse(parts[4]) ?? 0;
      // parts[5]=bulan, parts[6]=tanggal, parts[7]=tahun/jam
      final date = parts.length >= 8
          ? '${parts[6].padLeft(2, '0')} ${parts[5]} ${parts[7]}'
          : '';
      return FtpEntry(name: name, isDirectory: isDir, size: size, date: date);
    } catch (_) {
      return null;
    }
  }
}

class FtpException implements Exception {
  final String message;
  const FtpException(this.message);
  @override
  String toString() => message;
}
