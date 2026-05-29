/// Basis untuk exception yang dilempar dalam aplikasi kita.
/// Mengenkapsulasi pesan yang human-readable.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) return 'AppException($code): $message';
    return 'AppException: $message';
  }
}

/// Digunakan untuk error terkait koneksi ke server/Supabase.
class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});
}

/// Digunakan untuk error autentikasi.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

/// Digunakan untuk error data tidak ditemukan.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.details});
}

/// Digunakan untuk error validasi atau input salah dari user.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}
