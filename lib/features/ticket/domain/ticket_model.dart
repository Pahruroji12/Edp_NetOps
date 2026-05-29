/// TicketModel — representasi data tiket dari tabel ticket_logs.
///
/// Lokasi: features/ticket/domain/ticket_model.dart
///
class TicketModel {
  final String id;
  final String storeCode;
  final String storeName;
  final String provider;
  final String? nomorTiket;
  final String status;
  final DateTime? createdAt;
  final String? createdBy;

  const TicketModel({
    required this.id,
    required this.storeCode,
    required this.storeName,
    required this.provider,
    this.nomorTiket,
    required this.status,
    this.createdAt,
    this.createdBy,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id']?.toString() ?? '',
      storeCode: json['store_code'] ?? '',
      storeName: json['store_name'] ?? '',
      provider: json['provider'] ?? '',
      nomorTiket: json['nomor_tiket'],
      status: json['status'] ?? 'Open',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])?.toLocal()
          : null,
      createdBy: json['created_by'],
    );
  }

  /// Untuk kompatibilitas dengan ExportHelper yang masih pakai Map
  Map<String, dynamic> toJson() => {
    'id': id,
    'store_code': storeCode,
    'store_name': storeName,
    'provider': provider,
    'nomor_tiket': nomorTiket,
    'status': status,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'created_by': createdBy,
  };
}
