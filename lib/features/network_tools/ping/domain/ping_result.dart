/// PingResult — typed model untuk hasil ping satu IP.
///
/// Lokasi: features/network_tools/ping/domain/ping_result.dart
///
/// Tidak boleh import Flutter — pure Dart class.
/// Mengganti return type `List<dynamic>` → typed object.
///
class PingResult {
  final String storeName;
  final String deviceType;
  final String ip;
  final bool isAlive;
  final DateTime timestamp;

  const PingResult({
    required this.storeName,
    required this.deviceType,
    required this.ip,
    required this.isAlive,
    required this.timestamp,
  });

  /// Status string untuk CSV dan UI.
  String get statusLabel => isAlive ? 'OK' : 'NOK';

  /// Konversi ke row CSV (sama format dengan ping_service.dart lama).
  List<dynamic> toCsvRow() {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    final ss = timestamp.second.toString().padLeft(2, '0');
    return [storeName, deviceType, ip, statusLabel, '$hh:$mm:$ss'];
  }
}

/// PingTarget — model untuk 1 target yang akan di-ping.
///
/// Digunakan internal oleh PingExecutor.
///
class PingTarget {
  final String storeName;
  final String deviceType;
  final String ip;

  const PingTarget({
    required this.storeName,
    required this.deviceType,
    required this.ip,
  });
}
