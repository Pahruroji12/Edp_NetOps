import '../../store/domain/store_model.dart';

/// TicketEmailData — template email per provider (Astinet, Icon, Fiberstar).
///
/// Lokasi: features/ticket/data/ticket_email_data.dart
///
/// Dipindahkan dari TicketDialog._buildEmailData() agar
/// business logic (data email) terpisah dari UI.
///
class TicketEmailData {
  final String to;
  final String cc;
  final String subject;
  final String bodyTemplate;
  final String label;

  const TicketEmailData({
    required this.to,
    required this.cc,
    required this.subject,
    required this.bodyTemplate,
    required this.label,
  });

  /// Buat body email final dengan mengganti placeholder.
  String buildFinalBody({required String pic, required String kendala}) =>
      bodyTemplate
          .replaceAll('{PIC}', pic)
          .replaceAll('{KENDALA}', kendala);

  /// Factory: buat email data sesuai provider key.
  /// [key]      : 'astinet' | 'icon' | 'fiberstar'
  /// [isBackup] : true jika koneksi yang bermasalah adalah backup
  factory TicketEmailData.fromProvider(
    StoreModel store,
    String key, {
    required bool isBackup,
  }) {
    final code = store.storeCode;
    final name = store.storeName;
    final sid = isBackup ? (store.sidBackup ?? '') : (store.sidUtama ?? '');

    switch (key) {
      case 'astinet':
        return TicketEmailData(
          label: 'Astinet',
          to: 'tenesa@telkom.co.id',
          cc: '404238@telkom.co.id'
              ';yudhieostlkm@gmail.com'
              ';403925@telkom.co.id'
              ';ditanurfiana.eos@gmail.com'
              ';404160@telkom.co.id'
              ';riyoeossdaidm@gmail.com'
              ';403945@telkom.co.id'
              ';chicatobing@gmail.com'
              ';403869@telkom.co.id'
              ';giriii8791@gmail.com'
              ';404079@telkom.co.id'
              ';danil.rizaldi@gmail.com'
              ';403811@telkom.co.id'
              ';rudivanbouston@gmail.com'
              ';eossdaarman@gmail.com'
              ';fakihjun@gmail.com'
              ';edp_net_1@lbk.indomaret.co.id',
          subject:
              'Mohon dibantu open tiket toko IDM Cab LEBAK - $code $name',
          bodyTemplate:
              'Yth,\nTim Telkom\n\n'
              'Mohon dibantu diopenkan tiket toko Indomaret Cab LEBAK '
              'dengan data berikut :\n\n'
              'Nama Toko : $code - $name\n'
              'Nomor Layanan/Service ID : $sid\n'
              'Nama & Nomor PIC : {PIC}\n'
              'Stand By PIC : SHIFT 1 (07:00-16:00)\n'
              'Waktu Kunjungan Teknisi : SECEPATNYA\n'
              'Status Firewall di Sisi Router CE : Tidak Aktif\n'
              'Status Router Terhubung ke ONT : Terhubung\n'
              'Kendala : {KENDALA}\n\n\n'
              'Demikian informasi yang dapat disampaikan.\n'
              'Atas perhatian dan kerjasamanya saya ucapkan terima kasih.\n\n\n'
              'Best Regards,\n'
              'EdpNET LEBAK || PT.Indomarco Prismatama',
        );

      case 'icon':
        return TicketEmailData(
          label: 'ICON',
          to: 'cs@iconpln.co.id',
          cc: 'eos.indomarco@iconpln.co.id'
              ';edp_mgr@lbk.indomaret.co.id'
              ';edp_net_1@lbk.indomaret.co.id',
          subject:
              'Pengecekan Link Icon IIX toko $code - $name Terpantau Down - PT Indomarco Prismatama',
          bodyTemplate:
              'Dengan hormat\n\n'
              'Untuk link dibawah, terpantau Down di sisi kami\n\n'
              'Link ICON IIX :\n\n'
              'Kode/Nama\t: $code - $name\n'
              'SID\t\t\t : $sid\n'
              'PIC\t\t\t : {PIC}\n'
              'Kendala\t\t : {KENDALA}\n\n\n'
              'Demikian informasi yang dapat disampaikan.\n'
              'Atas perhatian dan kerjasamanya saya ucapkan terima kasih.\n\n\n'
              'Best Regards,\n'
              'EdpNET LEBAK || PT.Indomarco Prismatama',
        );

      default:
        // Fiberstar
        return TicketEmailData(
          label: 'Fiberstar',
          to: 'noc@fiberstar.net.id',
          cc: 'edp_mgr@lbk.indomaret.co.id'
              ';edp_net_1@lbk.indomaret.co.id',
          subject:
              'Pengecekan Link Fiberstar toko $code - $name Terpantau Down - PT Indomarco Prismatama',
          bodyTemplate:
              'Dengan hormat\n\n'
              'Untuk link dibawah, terpantau Down di sisi kami\n\n'
              'Link Fiberstar :\n\n'
              'Kode/Nama\t: $code - $name\n'
              'SID\t\t\t  : $sid\n'
              'PIC\t\t\t  : {PIC}\n'
              'Kendala\t\t : {KENDALA}\n\n\n'
              'Demikian informasi yang dapat disampaikan.\n'
              'Atas perhatian dan kerjasamanya saya ucapkan terima kasih.\n\n\n'
              'Best Regards,\n'
              'EdpNET LEBAK || PT.Indomarco Prismatama',
        );
    }
  }

  /// Parse email string "a;b;c" ke List.
  static List<String> parseEmails(String raw) =>
      raw.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}
