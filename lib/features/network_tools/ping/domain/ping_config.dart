/// PingConfig — immutable model untuk state checkbox target IP.
///
/// Lokasi: features/network_tools/ping/domain/ping_config.dart
///
/// Tidak boleh import Flutter — pure Dart class.
/// Digunakan oleh PingController untuk mengelola state pilihan target.
///
class PingConfig {
  final bool gateway;
  final bool station1;
  final bool stb;
  final bool rbWdcp;
  final bool cctv1;
  final bool cctv2;
  final String manualIps;

  const PingConfig({
    this.gateway = true,
    this.station1 = false,
    this.stb = false,
    this.rbWdcp = false,
    this.cctv1 = false,
    this.cctv2 = false,
    this.manualIps = '',
  });

  /// Cek apakah ada minimal 1 target yang dipilih.
  bool get hasSelection =>
      gateway || station1 || stb || rbWdcp || cctv1 || cctv2 ||
      manualIps.trim().isNotEmpty;

  /// Buat copy baru dengan perubahan tertentu (immutable update).
  PingConfig copyWith({
    bool? gateway,
    bool? station1,
    bool? stb,
    bool? rbWdcp,
    bool? cctv1,
    bool? cctv2,
    String? manualIps,
  }) {
    return PingConfig(
      gateway: gateway ?? this.gateway,
      station1: station1 ?? this.station1,
      stb: stb ?? this.stb,
      rbWdcp: rbWdcp ?? this.rbWdcp,
      cctv1: cctv1 ?? this.cctv1,
      cctv2: cctv2 ?? this.cctv2,
      manualIps: manualIps ?? this.manualIps,
    );
  }

  /// Config khusus auto-ping: hanya STB yang aktif.
  static const PingConfig autoPingSTB = PingConfig(
    gateway: false,
    station1: false,
    stb: true,
    rbWdcp: false,
    cctv1: false,
    cctv2: false,
  );
}
