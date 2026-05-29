/// Ping service — implementasi native menggunakan dart_ping.
import 'package:dart_ping/dart_ping.dart';

/// Hasil dari single ping.
class PingServiceResult {
  final bool success;
  final int? latencyMs;
  final String statusText;

  const PingServiceResult({
    required this.success,
    this.latencyMs,
    required this.statusText,
  });
}

/// Lakukan single ping ke [ip] menggunakan dart_ping.
Future<PingServiceResult> performSinglePing(String ip) async {
  try {
    final ping = Ping(ip, count: 1, timeout: 2);
    final response = await ping.stream.first;

    if (response.response != null && response.error == null) {
      final ms = response.response!.time?.inMilliseconds ?? 0;
      return PingServiceResult(
        success: true,
        latencyMs: ms,
        statusText: 'ONLINE',
      );
    } else {
      return const PingServiceResult(
        success: false,
        statusText: 'OFFLINE',
      );
    }
  } catch (_) {
    return const PingServiceResult(
      success: false,
      statusText: 'GAGAL',
    );
  }
}
