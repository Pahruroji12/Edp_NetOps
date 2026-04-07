import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart'; // Pastikan package crypto ada di pubspec.yaml

class MikrotikApiService {
  Socket? _socket;

  // BUFFER: Penampungan data yang masuk
  final List<int> _buffer = [];
  Completer<void>? _dataArrivedNotifier;

  // ==========================================
  // 1. KONEK & LOGIN
  // ==========================================
  Future<void> connect(
    String ip,
    int port,
    String user,
    String password,
  ) async {
    try {
      disconnect(); // Bersihkan koneksi lama jika ada

      _socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );

      // LISTEN STREAM
      _socket!.listen(
        (data) {
          _buffer.addAll(data);
          // Beritahu pembaca bahwa ada data baru masuk
          if (_dataArrivedNotifier != null &&
              !_dataArrivedNotifier!.isCompleted) {
            _dataArrivedNotifier!.complete();
          }
        },
        onError: (e) => print("Socket Error: $e"),
        onDone: () => print("Socket Closed"),
      );

      // JALANKAN LOGIN
      await _login(user, password);
      print("Connected to MikroTik API: $ip");
    } catch (e) {
      disconnect();
      throw Exception("Gagal konek API: $e");
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _buffer.clear();
  }

  // ==========================================
  // 2. FITUR-FITUR UTAMA (COMMANDS)
  // ==========================================

  // --- AMBIL REGISTRATION TABLE (PERANGKAT ONLINE) ---
  Future<List<Map<String, String>>> getRegistrationTable() async {
    final response = await _sendCommand([
      '/interface/wireless/registration-table/print',
    ]);
    List<Map<String, String>> devices = [];
    for (var item in response) {
      if (item.containsKey('mac-address')) {
        devices.add({
          'mac': item['mac-address'] ?? '-',
          'uptime': item['uptime'] ?? '-',
          'comment': item['comment'] ?? 'No Comment',
          '.id': item['.id'] ?? '', // Penting jika nanti mau kick user
        });
      }
    }
    return devices;
  }

  // --- [BARU] AMBIL ACCESS LIST (WHITELIST) ---
  Future<List<Map<String, String>>> getAccessList() async {
    final response = await _sendCommand([
      '/interface/wireless/access-list/print',
    ]);
    List<Map<String, String>> list = [];
    for (var item in response) {
      // Kita butuh .id untuk menghapus data nanti
      if (item.containsKey('.id')) {
        list.add({
          '.id': item['.id']!,
          'mac-address': item['mac-address'] ?? '-',
          'comment': item['comment'] ?? '-',
        });
      }
    }
    return list;
  }

  // --- [BARU] AMBIL SYSTEM RESOURCE (CPU, Memory, Version) ---
  Future<Map<String, String>> getSystemResource() async {
    final response = await _sendCommand(['/system/resource/print']);
    if (response.isNotEmpty) {
      return response.first;
    }
    return {};
  }

  // --- [BARU] HAPUS DARI ACCESS LIST ---
  Future<void> removeAccessList(String id) async {
    await _sendCommand([
      '/interface/wireless/access-list/remove',
      '=.id=$id', // Parameter ID Mikrotik
    ]);
  }

  // --- CEK STATUS DEFAULT AUTHENTICATE ---
  Future<bool> getDefaultAuthStatus() async {
    final response = await _sendCommand(['/interface/wireless/print']);
    for (var item in response) {
      if (item.containsKey('default-authentication')) {
        return item['default-authentication'] == 'true';
      }
    }
    return false;
  }

  // --- UBAH DEFAULT AUTHENTICATE ---
  Future<void> setDefaultAuth(bool enable) async {
    // Kita harus cari ID interface wireless dulu (biasanya wlan1 id-nya *0 tapi bisa beda)
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
      '=authentication=yes', // Pastikan di-set yes biar bisa connect
      '=forwarding=yes',
    ]);
  }

  // --- AMBIL SEMUA INTERFACE WIRELESS + STATUS DEFAULT-AUTH ---
  /// Return: List of Map {'name': String, 'defaultAuth': bool}
  Future<List<Map<String, dynamic>>> getWirelessInterfaces() async {
    final response = await _sendCommand(['/interface/wireless/print']);
    final results = <Map<String, dynamic>>[];
    for (final item in response) {
      final name = item['name'] ?? item['.id'] ?? 'wlan?';
      final defaultAuth = item['default-authentication'] == 'true';
      results.add({'name': name, 'defaultAuth': defaultAuth});
    }
    results.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return results;
  }

  // ==========================================
  // 3. LOGIC LOGIN (MODERN + LEGACY)
  // ==========================================

  Future<void> _login(String user, String password) async {
    // CARA 1: MODERN LOGIN (RouterOS v6.43+ & v7)
    try {
      await _sendCommand(['/login', '=name=$user', '=password=$password']);
      return; // Sukses
    } catch (e) {
      // Jika error bukan trap (misal socket putus), throw
      if (!e.toString().contains('!trap')) rethrow;
      print("Login Modern gagal, mencoba Legacy Login...");
    }

    // CARA 2: LEGACY LOGIN (Challenge-Response MD5)
    _sendWord('/login');
    _sendWord(''); // Kirim kosong untuk minta challenge

    var sentence = await _readSentence();

    if (sentence['!status'] == '!done' && sentence.containsKey('ret')) {
      var challenge = sentence['ret']!;

      // MD5 Challenge Response
      var bytes = <int>[0];
      bytes.addAll(utf8.encode(password));
      bytes.addAll(_hexToBytes(challenge));

      var digest = md5.convert(bytes);
      var resString = "00$digest";

      _sendWord('/login');
      _sendWord('=name=$user');
      _sendWord('=response=$resString');
      _sendWord('');

      var finalRes = await _readSentence();
      if (finalRes['!status'] != '!done') {
        throw Exception("Login Legacy Failed: ${finalRes['message']}");
      }
    } else if (sentence['!status'] == '!trap') {
      throw Exception("Login Error: ${sentence['message']}");
    }
  }

  // ==========================================
  // 4. CORE PROTOCOL API (LOW LEVEL)
  // ==========================================

  Future<List<Map<String, String>>> _sendCommand(List<String> words) async {
    if (_socket == null) throw Exception("Socket not connected");

    // Kirim Command
    for (var word in words) {
      _sendWord(word);
    }
    _sendWord(''); // Akhiri command dengan byte kosong

    // Baca Response Loop
    List<Map<String, String>> results = [];
    while (true) {
      var sentence = await _readSentence();
      if (sentence.isEmpty) {
        break; // Harusnya tidak kejadian jika protokol benar
      }

      var status = sentence['!status'];
      if (status == '!done') {
        break; // Selesai
      } else if (status == '!trap') {
        // Error dari Mikrotik (misal: command not found / permission denied)
        throw Exception("API Error: ${sentence['message']}");
      } else if (status == '!re') {
        // Data response (baris data)
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
      // Handle length > 16384 bytes (jarang untuk command, tapi jaga-jaga)
      len |= 0xC00000;
      _socket!.add([(len >> 16) & 0xFF, (len >> 8) & 0xFF, len & 0xFF]);
    }
    _socket!.add(bytes);
  }

  // Baca Satu Kalimat (Sentence) = Kumpulan Words sampai word kosong
  Future<Map<String, String>> _readSentence() async {
    Map<String, String> sentence = {};
    while (true) {
      var len = await _readLen();
      if (len == 0) break; // Word kosong = akhir kalimat

      List<int> bytes = await _readBytes(len);
      var line = utf8.decode(bytes);

      if (line.startsWith('!')) {
        sentence['!status'] = line;
      } else if (line.startsWith('=')) {
        // Parsing attribute =key=value
        var parts = line.substring(1).split('=');
        if (parts.length >= 2) {
          var key = parts[0];
          var value = parts
              .sublist(1)
              .join('='); // Gabung lagi kalau value ada '='
          sentence[key] = value;
        }
      }
    }
    return sentence;
  }

  // Baca Panjang Kata (Length Encoding)
  Future<int> _readLen() async {
    var b = await _readByte();
    if ((b & 0x80) == 0) return b;
    if ((b & 0xC0) == 0x80) {
      var b2 = await _readByte();
      return ((b & 0x3F) << 8) | b2;
    }
    if ((b & 0xE0) == 0xC0) {
      var b2 = await _readByte();
      var b3 = await _readByte();
      return ((b & 0x1F) << 16) | (b2 << 8) | b3;
    }
    // Jika length > 3 bytes, logic ini perlu ditambah.
    // Tapi untuk access list standard, ini sudah cukup.
    return await _readByte();
  }

  // Baca 1 Byte dari Buffer (Tunggu kalau kosong)
  Future<int> _readByte() async {
    while (_buffer.isEmpty) {
      _dataArrivedNotifier = Completer<void>();
      await _dataArrivedNotifier!.future;
    }
    return _buffer.removeAt(0);
  }

  // Baca N Bytes
  Future<List<int>> _readBytes(int length) async {
    List<int> result = [];
    for (int i = 0; i < length; i++) {
      result.add(await _readByte());
    }
    return result;
  }

  // Helper Hex to Bytes untuk MD5 Challenge
  List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
