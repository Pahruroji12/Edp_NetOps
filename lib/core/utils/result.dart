import '../error/failures.dart';

/// Sealed class untuk result pattern.
/// Mengenkapsulasi sukses (SuccessResult) dan error (ErrorResult).
sealed class Result<T> {
  const Result();

  /// Helper untuk mengeksekusi callback tergantung dari state result.
  R fold<R>(R Function(Failure failure) onError, R Function(T data) onSuccess) {
    return switch (this) {
      SuccessResult<T>(:final data) => onSuccess(data),
      ErrorResult<T>(:final failure) => onError(failure),
    };
  }

  /// Mengecek apakah ini SuccessResult.
  bool get isSuccess => this is SuccessResult<T>;

  /// Mengecek apakah ini ErrorResult.
  bool get isError => this is ErrorResult<T>;

  /// Mengambil data jika success, jika error maka return null.
  T? get dataOrNull => this is SuccessResult<T> ? (this as SuccessResult<T>).data : null;

  /// Mengambil failure jika error, jika success maka return null.
  Failure? get errorOrNull => this is ErrorResult<T> ? (this as ErrorResult<T>).failure : null;
}

class SuccessResult<T> extends Result<T> {
  final T data;
  const SuccessResult(this.data);
}

class ErrorResult<T> extends Result<T> {
  final Failure failure;
  const ErrorResult(this.failure);
}
