/// UserModel — representasi data profil pengguna dari tabel profiles.
///
/// Lokasi: features/profile/domain/user_model.dart
///
class UserModel {
  final String id;
  final String nama;
  final String nik;
  final String role;
  final bool isOnline;
  final DateTime? lastActive;

  const UserModel({
    required this.id,
    required this.nama,
    required this.nik,
    required this.role,
    required this.isOnline,
    this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      nik: json['nik'] ?? '',
      role: json['role'] ?? 'user',
      isOnline: json['is_online'] ?? false,
      lastActive: json['last_active'] != null
          ? DateTime.tryParse(json['last_active'])?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nik': nik,
    'role': role,
    'is_online': isOnline,
    'last_active': lastActive?.toUtc().toIso8601String(),
  };
}
