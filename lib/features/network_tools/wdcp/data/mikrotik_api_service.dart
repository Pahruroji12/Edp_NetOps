import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class MikrotikApiService {
  Socket? _socket;

  // BUFFER: Penampungan data yang masuk
  final List<int> _buffer = [];
  Completer<void>? _dataArrivedNotifier;

  // ── Timeout konfigurasi ────────────────────────────────────────────────────
  static const Duration _connectTimeout = Duration(seconds: 5);
  // Timeout baca per-byte: mencegah hang selamanya jika router tidak response
  static const Duration _readTimeout = Duration(seconds: 10);

  // ══════════════════════════════════════════════════════════════════════════
  // 1. KONEK & LOGIN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> connect(
    String ip,
    int port,
    String user,
    String password,
  ) async {
    try {
      disconnect(); // Bersihkan koneksi lama

      _socket = await Socket.connect(ip, port, timeout: _connectTimeout);

      // LISTEN STREAM
      _socket!.listen(
        (data) {
          _buffer.addAll(data);
          if (_dataArrivedNotifier != null &&
              !_dataArrivedNotifier!.isCompleted) {
            _dataArrivedNotifier!.complete();
          }
        },
        onError: (e) {
          debugPrint('Socket Error: $e');
          disconnect();
        },
        onDone: () => debugPrint('Socket Closed'),
        cancelOnError: false,
      );

      await _login(user, password);
      debugPrint('Connected to MikroTik API: $ip:$port');
    } catch (e) {
      disconnect();
      rethrow;
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _buffer.clear();
    // Selesaikan completer yang mungkin masih menunggu agar tidak hang
    if (_dataArrivedNotifier != null && !_dataArrivedNotifier!.isCompleted) {
      _dataArrivedNotifier!.completeError(
        TimeoutException('Socket disconnected', _readTimeout),
      );
    }
    _dataArrivedNotifier = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. FITUR-FITUR UTAMA (COMMANDS)
  // ══════════════════════════════════════════════════════════════════════════

  // --- AMBIL REGISTRATION TABLE ---
  Future<List<Map<String, String>>> getRegistrationTable() async {
    final response = await _sendCommand([
      '/interface/wireless/registration-table/print',
    ]);
    return response
        .where((item) => item.containsKey('mac-address'))
        .map(
          (item) => {
            'mac': item['mac-address'] ?? '-',
            'uptime': item['uptime'] ?? '-',
            'comment': item['comment'] ?? 'No Comment',
            '.id': item['.id'] ?? '',
          },
        )
        .toList();
  }

  // --- AMBIL ACCESS LIST ---
  Future<List<Map<String, String>>> getAccessList() async {
    final response = await _sendCommand([
      '/interface/wireless/access-list/print',
    ]);
    return response
        .where((item) => item.containsKey('.id'))
        .map(
          (item) => {
            '.id': item['.id']!,
            'mac-address': item['mac-address'] ?? '-',
            'comment': item['comment'] ?? '-',
          },
        )
        .toList();
  }

  // --- AMBIL SYSTEM RESOURCE ---
  Future<Map<String, String>> getSystemResource() async {
    final response = await _sendCommand(['/system/resource/print']);
    return response.isNotEmpty ? response.first : {};
  }

  // --- HAPUS DARI ACCESS LIST ---
  Future<void> removeAccessList(String id) async {
    await _sendCommand(['/interface/wireless/access-list/remove', '=.id=$id']);
  }

  // --- CEK STATUS DEFAULT AUTHENTICATE ---
  Future<bool> getDefaultAuthStatus() async {
    final response = await _sendCommand(['/interface/wireless/print']);
    for (var item in response) {
      if (item.containsKey('default-authentication')) {
        // FIX BUG 3: RouterOS mengembalikan 'yes'/'no', bukan 'true'/'false'
        final val = item['default-authentication']?.toLowerCase() ?? 'no';
        return val == 'yes' || val == 'true';
      }
    }
    return false;
  }

  // --- UBAH DEFAULT AUTHENTICATE ---
  Future<void> setDefaultAuth(bool enable) async {
    final interfaces = await _sendCommand(['/interface/wireless/print']);
    for (var iface in interfaces) {
      final id = iface['.id'];
      if (id != null) {
        await _sendCommand([
          '/interface/wireless/set',
          '=.id=$id',
          '=default-authentication=${enable ? "yes" : "no"}',
        ]);
      }
    }
  }

  // --- TAMBAH KE ACCESS LIST ---
  Future<void> addAccessList(String mac, String comment) async {
    await _sendCommand([
      '/interface/wireless/access-list/add',
      '=mac-address=$mac',
      '=comment=$comment',
      '=authentication=yes',
      '=forwarding=yes',
    ]);
  }

  // --- AMBIL SEMUA INTERFACE WIRELESS ---
  Future<List<Map<String, dynamic>>> getWirelessInterfaces() async {
    final response = await _sendCommand(['/interface/wireless/print']);
    final results = response.map((item) {
      // FIX BUG 3: RouterOS mengembalikan 'yes'/'no', bukan 'true'/'false'
      final authVal = (item['default-authentication'] ?? 'no').toLowerCase();
      return {
        'name': item['name'] ?? item['.id'] ?? 'wlan?',
        'defaultAuth': authVal == 'yes' || authVal == 'true',
      };
    }).toList();
    results.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return results;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. LOGIC LOGIN (MODERN + LEGACY)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _login(String user, String password) async {
    // CARA 1: MODERN LOGIN (RouterOS v6.43+ & v7)
    // Kirim langsung tanpa _sendCommand agar buffer tidak kotor jika gagal
    _sendWord('/login');
    _sendWord('=name=$user');
    _sendWord('=password=$password');
    _sendWord(''); // End of sentence

    final firstResponse = await _readSentence();

    // Modern login berhasil jika !done tanpa ret challenge
    if (firstResponse['!status'] == '!done' &&
        !firstResponse.containsKey('ret')) {
      debugPrint('Modern Login berhasil');
      return;
    }

    // Legacy login: server mengembalikan challenge di field 'ret'
    if (firstResponse['!status'] == '!done' &&
        firstResponse.containsKey('ret')) {
      debugPrint('Legacy Login — challenge diterima, kirim MD5 response...');
      final challenge = firstResponse['ret']!;

      final bytes = <int>[0];
      bytes.addAll(utf8.encode(password));
      bytes.addAll(_hexToBytes(challenge));

      final digest = md5.convert(bytes);
      final resString = "00$digest";

      _sendWord('/login');
      _sendWord('=name=$user');
      _sendWord('=response=$resString');
      _sendWord(''); // End of sentence

      final finalRes = await _readSentence();
      if (finalRes['!status'] != '!done') {
        throw Exception("Login Legacy Failed: ${finalRes['message']}");
      }
      return;
    }

    // Login gagal (misal: salah password)
    if (firstResponse['!status'] == '!trap') {
      throw Exception("Login Error: ${firstResponse['message']}");
    }

    throw Exception("Login gagal: response tidak dikenal — $firstResponse");
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. CORE PROTOCOL API (LOW LEVEL)
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, String>>> _sendCommand(List<String> words) async {
    if (_socket == null) throw Exception('Socket not connected');

    for (var word in words) {
      _sendWord(word);
    }
    _sendWord(''); // Akhiri command

    List<Map<String, String>> results = [];
    while (true) {
      var sentence = await _readSentence();
      if (sentence.isEmpty) break;

      final status = sentence['!status'];
      if (status == '!done') {
        break;
      } else if (status == '!trap') {
        throw Exception('API Error: ${sentence['message']}');
      } else if (status == '!re') {
        results.add(sentence);
      }
    }
    return results;
  }

  // Kirim Kata (Word) dengan Length Encoding
  void _sendWord(String word) {
    var bytes = utf8.encode(word);
    var len = bytes.length;

    if (len < 0x80) {
      _socket!.add([len]);
    } else if (len < 0x4000) {
      len |= 0x8000;
      _socket!.add([(len >> 8) & 0xFF, len & 0xFF]);
    } else {
      len |= 0xC00000;
      _socket!.add([(len >> 16) & 0xFF, (len >> 8) & 0xFF, len & 0xFF]);
    }
    _socket!.add(bytes);
  }

  // Baca Satu Kalimat sampai word kosong
  Future<Map<String, String>> _readSentence() async {
    final Map<String, String> sentence = {};
    while (true) {
      final len = await _readLen();
      if (len == 0) break;

      final bytes = await _readBytes(len);
      final line = utf8.decode(bytes);

      if (line.startsWith('!')) {
        sentence['!status'] = line;
      } else if (line.startsWith('=')) {
        final parts = line.substring(1).split('=');
        if (parts.length >= 2) {
          sentence[parts[0]] = parts.sublist(1).join('=');
        }
      }
    }
    return sentence;
  }

  // Baca Length Encoding
  Future<int> _readLen() async {
    final b = await _readByte();
    if ((b & 0x80) == 0) return b;
    if ((b & 0xC0) == 0x80) {
      final b2 = await _readByte();
      return ((b & 0x3F) << 8) | b2;
    }
    if ((b & 0xE0) == 0xC0) {
      final b2 = await _readByte();
      final b3 = await _readByte();
      return ((b & 0x1F) << 16) | (b2 << 8) | b3;
    }
    return await _readByte();
  }

  // ── Helper: tunggu sampai ada data baru di buffer ────────────────────────
  Future<void> _waitForData() async {
    _dataArrivedNotifier = Completer<void>();
    await _dataArrivedNotifier!.future.timeout(
      _readTimeout,
      onTimeout: () {
        disconnect();
        throw TimeoutException(
          'MikroTik tidak merespons dalam ${_readTimeout.inSeconds} detik.',
          _readTimeout,
        );
      },
    );
  }

  // ── Baca 1 Byte — dengan TIMEOUT agar tidak hang selamanya ────────────────
  Future<int> _readByte() async {
    while (_buffer.isEmpty) {
      await _waitForData();
    }
    return _buffer.removeAt(0);
  }

  // ── Baca N Bytes sekaligus — TIDAK loop per-byte agar UI tidak freeze ─────
  // Sebelumnya: N kali await _readByte() → N iterasi async tanpa yield → freeze di CPU lemot
  // Sekarang:   tunggu buffer punya cukup data, lalu sublist sekali ambil → O(1) yield
  Future<List<int>> _readBytes(int length) async {
    // Tunggu sampai buffer punya minimal `length` byte
    while (_buffer.length < length) {
      await _waitForData();
    }
    // Ambil sekaligus — satu operasi, bukan N kali await
    final result = _buffer.sublist(0, length);
    _buffer.removeRange(0, length);
    return result;
  }

  // Helper Hex to Bytes untuk MD5 Challenge
  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
