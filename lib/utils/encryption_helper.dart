import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  // Fungsi untuk mengubah teks biasa menjadi Hash SHA-256
  static String hashPassword(String password) {
    // 1. Ubah string jadi bytes
    var bytes = utf8.encode(password);
    // 2. Acak menggunakan SHA-256
    var digest = sha256.convert(bytes);
    // 3. Kembalikan sebagai string hex (kombinasi angka & huruf)
    return digest.toString();
  }
}
