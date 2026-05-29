import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../../../core/error/failures.dart';

/// LoginController — semua logic login dipisah dari LoginPage.
///
/// Lokasi: features/auth/presentation/login_controller.dart
///
/// LoginPage hanya panggil controller, tidak tahu Supabase sama sekali.
///
class LoginController extends ChangeNotifier {
  final _repository = AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Jalankan proses login.
  ///
  /// Return: nama user jika sukses, null jika gagal.
  /// Error message tersedia via [errorMessage].
  Future<String?> signIn({
    required String nik,
    required String password,
  }) async {
    if (nik.isEmpty || password.isEmpty) {
      _errorMessage = 'NIK dan Password wajib diisi!';
      _safeNotify();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    final result = await _repository.signIn(nik: nik, password: password);

    return result.fold(
      (failure) {
        if (failure is AuthFailure &&
            failure.message.contains('Invalid login credentials')) {
          _errorMessage = 'Login Gagal: NIK atau Password salah!';
        } else {
          _errorMessage = 'Terjadi kesalahan: ${failure.message}';
        }
        _isLoading = false;
        _safeNotify();
        return null;
      },
      (userName) {
        _isLoading = false;
        _safeNotify();
        return userName;
      },
    );
  }
}
