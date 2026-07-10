/// PingResult — typed model untuk hasil ping satu IP.
///
/// Lokasi: features/network_tools/ping/domain/ping_result.dart
///
/// Tidak boleh import Flutter — pure Dart class.
/// Mengganti return type `List<dynamic>` → typed object.
///
class PingResult {
  final String storeCode;
  final String storeName;
  final String deviceType;
  final String ip;
  final bool isAlive;
  final DateTime timestamp;

  const PingResult({
    required this.storeCode,
    required this.storeName,
    required this.deviceType,
    required this.ip,
    required this.isAlive,
    required this.timestamp,
  });

  /// Status string untuk CSV dan UI.
  String get statusLabel => isAlive ? 'OK' : 'NOK';
}

/// PingTarget — model untuk 1 target yang akan di-ping.
///
/// Digunakan internal oleh PingExecutor.
///
class PingTarget {
  final String storeCode;
  final String storeName;
  final String deviceType;
  final String ip;

  const PingTarget({
    required this.storeCode,
    required this.storeName,
    required this.deviceType,
    required this.ip,
  });
}
