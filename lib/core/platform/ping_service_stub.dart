/// Ping service — stub untuk Web.
/// dart_ping tidak tersedia di Web (butuh raw socket).

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

/// Stub — selalu return unsupported.
Future<PingServiceResult> performSinglePing(String ip) async {
  return const PingServiceResult(
    success: false,
    statusText: 'Ping tidak tersedia di Web',
  );
}
