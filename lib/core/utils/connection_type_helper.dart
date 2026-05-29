/// ConnectionTypeHelper — utility untuk deteksi tipe koneksi toko.
///
/// Lokasi: core/utils/connection_type_helper.dart
///
/// Single source of truth untuk seluruh detection logic koneksi.
///
/// Menghilangkan duplikasi pattern:
///   connectionType.toUpperCase().contains('VSAT')
///   connectionType.toUpperCase().contains('ASTINET')
///   dll.
///
/// Cara pakai:
///   if (ConnectionTypeHelper.isVsat(store.connectionType)) { ... }
///   if (ConnectionTypeHelper.isFoProvider(conn)) { ... }
///   final label = ConnectionTypeHelper.foLabel(conn);
///   final providers = ConnectionTypeHelper.foTicketProviders(main, backup);
///
class ConnectionTypeHelper {
  ConnectionTypeHelper._();

  // ── VSAT Detection ─────────────────────────────────────────────

  /// True jika string koneksi mengandung 'VSAT'.
  static bool isVsat(String? conn) =>
      (conn ?? '').toUpperCase().contains('VSAT');

  /// True jika koneksi utama VSAT tapi backup bukan VSAT (single VSAT).
  static bool isVsatOnly(String? main, String? backup) =>
      isVsat(main) && !isVsat(backup);

  /// True jika ada VSAT di backup, atau dual VSAT.
  static bool isVsatDual(String? main, String? backup) =>
      isVsat(backup) || (isVsat(main) && (backup ?? '').isNotEmpty);

  // ── FO Provider Detection ──────────────────────────────────────

  static bool isAstinet(String? conn) =>
      (conn ?? '').toUpperCase().contains('ASTINET');

  static bool isIcon(String? conn) =>
      (conn ?? '').toUpperCase().contains('ICON');

  static bool isFiberstar(String? conn) =>
      (conn ?? '').toUpperCase().contains('FIBERSTAR');

  /// True jika koneksi termasuk salah satu provider FO.
  static bool isFoProvider(String? conn) =>
      isAstinet(conn) || isIcon(conn) || isFiberstar(conn);

  /// Key provider untuk ticket system: 'astinet' | 'icon' | 'fiberstar' | ''.
  static String foKey(String? conn) {
    if (isAstinet(conn)) return 'astinet';
    if (isIcon(conn)) return 'icon';
    if (isFiberstar(conn)) return 'fiberstar';
    return '';
  }

  /// Label provider yang human-readable.
  static String foLabel(String? conn) {
    if (isAstinet(conn)) return 'Astinet';
    if (isIcon(conn)) return 'Icon';
    if (isFiberstar(conn)) return 'Fiberstar';
    return conn ?? '-';
  }

  // ── GSM / XL Detection ─────────────────────────────────────────

  static bool isGsm(String? conn) {
    final c = (conn ?? '').toUpperCase();
    return c.contains('GSM') || c.contains('ORBIT');
  }

  static bool isXl(String? conn) =>
      (conn ?? '').toUpperCase().contains('XL');

  // ── Connection Badge ───────────────────────────────────────────

  /// Label singkat untuk badge koneksi pada card toko.
  static String badgeLabel(String? conn) {
    final c = (conn ?? '-').toUpperCase();
    if (c.contains('ASTINET')) return 'ASTINET';
    if (c.contains('ICON')) return 'ICON';
    if (c.contains('FIBERSTAR')) return 'FIBERSTAR';
    if (c.contains('VSAT')) return 'VSAT';
    return c;
  }

  // ── FO Ticket Providers ────────────────────────────────────────

  /// Daftar provider FO aktif: [{key, label, isBackup}].
  ///
  /// Dipakai untuk menampilkan tombol Open Tiket di store detail.
  static List<Map<String, dynamic>> foTicketProviders(
    String? main,
    String? backup,
  ) {
    final list = <Map<String, dynamic>>[];
    if (isFoProvider(main)) {
      list.add({
        'key': foKey(main),
        'label': foLabel(main),
        'isBackup': false,
      });
    }
    if (isFoProvider(backup)) {
      list.add({
        'key': foKey(backup),
        'label': foLabel(backup),
        'isBackup': true,
      });
    }
    return list;
  }
}
