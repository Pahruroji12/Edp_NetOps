/// Represents an error state returned by a repository.
/// 
/// Tidak seperti exception yang dilempar dan merusak control flow, 
/// Failure di-return sebagai tipe data oleh Result pattern.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => code != null ? 'Failure($code): $message' : 'Failure: $message';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

class PlatformFailure extends Failure {
  const PlatformFailure(super.message, {super.code});
}
