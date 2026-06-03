import 'dart:async';
import 'dart:convert';
import 'package:edp_netops/core/platform/native_io.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import 'ticket_repository.dart';

class TicketImapService {
  TicketImapService._();
  static final instance = TicketImapService._();

  final _supabase = Supabase.instance.client;
  final _repo = TicketRepository();

  /// Mengambil konfigurasi IMAP dari tabel app_settings.
  Future<Result<Map<String, String>>> _fetchImapConfig() async {
    try {
      final rows = await _supabase
          .from('app_settings')
          .select('key, value');
      return SuccessResult({for (final r in rows) r['key'] as String: r['value'] as String});
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// Melakukan sinkronisasi tiket dari email IMAP ke database Supabase.
  Future<Result<int>> syncTickets() async {
    SecureSocket? socket;
    try {
      // 1. Ambil konfigurasi
      final configRes = await _fetchImapConfig();
      if (configRes.isError) {
        return ErrorResult(configRes.errorOrNull!);
      }

      final cfg = configRes.dataOrNull!;
      final host = cfg['imap_host'] ?? 'imap.gmail.com';
      final port = int.tryParse(cfg['imap_port'] ?? '993') ?? 993;
      final user = cfg['imap_user'] ?? '';
      final pass = cfg['imap_pass'] ?? '';

      if (user.isEmpty || pass.isEmpty) {
        return const ErrorResult(ValidationFailure(
          'Konfigurasi IMAP belum lengkap di app_settings.\n'
          'Atur imap_host, imap_port, imap_user, dan imap_pass.'
        ));
      }

      // 2. Ambil daftar tiket aktif yang nomor tiketnya masih kosong (null / empty)
      final ticketsRes = await _repo.fetchAll();
      if (ticketsRes.isError) {
        return ErrorResult(ticketsRes.errorOrNull!);
      }

      final activeTickets = ticketsRes.dataOrNull!
          .where((t) => t.nomorTiket == null || t.nomorTiket!.trim().isEmpty)
          .toList();

      if (activeTickets.isEmpty) {
        // Tidak ada tiket aktif yang perlu diupdate
        return const SuccessResult(0);
      }

      // 3. Hubungkan ke Server IMAP
      socket = await SecureSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 15),
        onBadCertificate: (_) => true, // Izinkan self-signed cert jika di jaringan internal
      );

      final client = _ImapSocketClient(socket);
      await client.readGreeting();

      // 4. LOGIN
      await client.execute('LOGIN "$user" "$pass"');

      // 5. SELECT INBOX
      await client.execute('SELECT INBOX');

      // 6. SEARCH UNSEEN (Cari email yang belum terbaca)
      final searchOutput = await client.execute('SEARCH UNSEEN');
      final unseenIds = _parseSearchIds(searchOutput);

      if (unseenIds.isEmpty) {
        await client.execute('LOGOUT');
        return const SuccessResult(0);
      }

      int updateCount = 0;

      // 7. Loop setiap email unseen untuk dicocokkan dengan tiket aktif
      for (final msgId in unseenIds) {
        // Ambil isi email mentah (headers + body) secara in-memory
        final fetchOutput = await client.execute('FETCH $msgId BODY.PEEK[]');
        final rawEmail = fetchOutput.join('\n');

        // Cari kode toko dari email (Format: Huruf diikuti 3 angka, misal T567 atau F123)
        final storeCodeMatch = RegExp(r'\b([A-Z]\d{3})\b', caseSensitive: false).firstMatch(rawEmail);
        if (storeCodeMatch == null) continue;

        final storeCode = storeCodeMatch.group(1)!.toUpperCase();

        // Cari apakah ada tiket aktif untuk toko tersebut
        final matchingTickets = activeTickets.where((t) => t.storeCode == storeCode).toList();
        if (matchingTickets.isEmpty) continue;

        for (final ticket in matchingTickets) {
          // Cari nomor tiket berdasarkan provider
          String? ticketNumber;
          final provider = ticket.provider.toLowerCase();

          if (provider == 'astinet') {
            // Astinet/Telkom: TKT-123456 atau INC123456 atau IN123456
            final match = RegExp(r'\b(TKT-\d+|INC\d+|IN\d+)\b', caseSensitive: false).firstMatch(rawEmail);
            if (match != null) ticketNumber = match.group(1);
          } else if (provider == 'icon') {
            // ICON: CS-123456789 atau ID-123456 atau 9 digit angka langsung
            final match = RegExp(r'\b(CS-\d+|ID-\d+|\d{9})\b', caseSensitive: false).firstMatch(rawEmail);
            if (match != null) ticketNumber = match.group(1);
          } else {
            // Fiberstar: FIB-123456
            final match = RegExp(r'\b(FIB-\d+)\b', caseSensitive: false).firstMatch(rawEmail);
            if (match != null) ticketNumber = match.group(1);
          }

          if (ticketNumber != null) {
            // Update tiket di Supabase
            final updateRes = await _repo.update(
              id: ticket.id,
              nomorTiket: ticketNumber,
              status: 'In Progress', // Otomatis berubah menjadi In Progress ketika nomor tiket terisi
              keterangan: ticket.keterangan ?? '',
            );

            if (updateRes.isSuccess) {
              updateCount++;
              // Tandai email sebagai terbaca (SEEN) di mail server
              await client.execute('STORE $msgId +FLAGS (\\Seen)');
              break; // Lanjut ke email berikutnya
            }
          }
        }
      }

      // 8. LOGOUT
      await client.execute('LOGOUT');
      return SuccessResult(updateCount);

    } catch (e) {
      debugPrint('IMAP Sync Error: $e');
      return ErrorResult(NetworkFailure('Gagal melakukan sinkronisasi email: $e'));
    } finally {
      socket?.destroy();
    }
  }

  /// Parsing ID email hasil perintah SEARCH.
  List<int> _parseSearchIds(List<String> lines) {
    final ids = <int>[];
    for (final line in lines) {
      if (line.startsWith('* SEARCH')) {
        final parts = line.split(' ');
        for (final p in parts) {
          final id = int.tryParse(p);
          if (id != null) ids.add(id);
        }
      }
    }
    return ids;
  }
}

/// Helper internal untuk komunikasi socket IMAP.
class _ImapSocketClient {
  final SecureSocket socket;
  int _cmdCounter = 1;
  final List<String> _readBuffer = [];
  Completer<List<String>>? _completer;
  String? _expectedTag;

  _ImapSocketClient(this.socket) {
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      _handleIncomingLine,
      onError: (err) {
        debugPrint('Socket error: $err');
        _completer?.completeError(err);
      },
      onDone: () {
        if (_completer != null && !_completer!.isCompleted) {
          _completer!.complete(_readBuffer);
        }
      },
    );
  }

  void _handleIncomingLine(String line) {
    _readBuffer.add(line);
    final tag = _expectedTag;
    if (tag != null && (line.startsWith('$tag OK') || line.startsWith('$tag NO') || line.startsWith('$tag BAD'))) {
      _expectedTag = null;
      final result = List<String>.from(_readBuffer);
      _readBuffer.clear();
      _completer?.complete(result);
    }
  }

  /// Membaca salam greeting dari server mail (dimulai dengan * OK)
  Future<void> readGreeting() async {
    final comp = Completer<List<String>>();
    _completer = comp;
    
    // Greeting biasanya datang langsung tanpa tag command
    Timer(const Duration(seconds: 5), () {
      if (!comp.isCompleted) {
        comp.complete(_readBuffer);
      }
    });

    await comp.future;
    _readBuffer.clear();
    _completer = null;
  }

  /// Eksekusi perintah IMAP dengan tag dinamis dan tunggu respons lengkapnya.
  Future<List<String>> execute(String command) async {
    final tag = 'a$_cmdCounter';
    _cmdCounter++;
    _expectedTag = tag;
    
    final comp = Completer<List<String>>();
    _completer = comp;

    socket.write('$tag $command\r\n');
    await socket.flush();

    final response = await comp.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _expectedTag = null;
        _completer = null;
        throw TimeoutException('IMAP command timed out: $command');
      },
    );

    // Cek apakah perintah sukses
    final lastLine = response.last;
    if (lastLine.contains(' NO ') || lastLine.contains(' BAD ')) {
      throw Exception('IMAP Command Failed ($command): $lastLine');
    }

    _completer = null;
    return response;
  }
}
