import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../utils/app_colors.dart';
import '../utils/globals.dart';
import '../utils/custom_snackbar.dart';

class FtpService extends ChangeNotifier {
  static FtpService? _instance;
  factory FtpService() {
    _instance ??= FtpService._internal();
    return _instance!;
  }
  FtpService._internal();

  bool isUploading = false;
  bool isDownloading = false;
  double uploadProgress = 0.0;
  String statusMessage = '';
  String targetIp = '';

  void _showNotif(String message, Color color) {
    CustomSnackBar.showFromKey(globalMessengerKey, message, color);
  }

  Future<void> sendPromoFile(String ipStb, String remotePath, File file) async {
    if (isUploading || isDownloading) return;

    isUploading = true;
    targetIp = ipStb;
    uploadProgress = 0.0;
    statusMessage = 'Menghubungkan ke $ipStb...';
    notifyListeners();

    final ftp = FTPConnect(ipStb, user: 'posterm', pass: 'dAZAD9yq', port: 21);
    try {
      await ftp.connect();
      await ftp.changeDirectory(remotePath);

      statusMessage = 'Mengirim: ${file.path.split('\\').last}...';
      notifyListeners();

      final result = await ftp.uploadFile(file);
      uploadProgress = 1.0;
      statusMessage = result ? 'Upload berhasil!' : 'Gagal mengirim file.';
      _showNotif(
        result
            ? 'File berhasil dikirim ke STB.'
            : 'Gagal mengirim file ke STB.',
        result ? AppStatusColors.success : AppStatusColors.danger,
      );
    } catch (e) {
      statusMessage = 'Error: Koneksi terputus / IP tidak aktif';
      _showNotif(
        'Gagal upload: koneksi ke STB terputus.',
        AppStatusColors.danger,
      );
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
      isUploading = false;
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        uploadProgress = 0.0;
        statusMessage = '';
        notifyListeners();
      });
    }
  }

  Future<void> downloadFile(
    String ipStb,
    String remotePath,
    String fileName,
    String localDir,
  ) async {
    if (isUploading || isDownloading) return;

    isDownloading = true;
    uploadProgress = 0.0;
    statusMessage = 'Mengunduh: $fileName...';
    notifyListeners();

    final ftp = FTPConnect(ipStb, user: 'posterm', pass: 'dAZAD9yq', port: 21);
    try {
      await ftp.connect();
      await ftp.changeDirectory(remotePath);

      final savePath = localDir.endsWith('\\')
          ? '$localDir$fileName'
          : '$localDir\\$fileName';
      final localFile = File(savePath);
      final result = await ftp.downloadFile(fileName, localFile);

      uploadProgress = 1.0;
      statusMessage = result ? 'Download berhasil!' : 'Gagal mengunduh file.';
      _showNotif(
        result
            ? 'File berhasil diunduh ke $localDir'
            : 'Gagal mengunduh file dari STB.',
        result ? AppStatusColors.success : AppStatusColors.danger,
      );
    } catch (e) {
      statusMessage = 'Error: Koneksi terputus / file tidak ditemukan';
      _showNotif(
        'Gagal download: koneksi ke STB terputus.',
        AppStatusColors.danger,
      );
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
      isDownloading = false;
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        uploadProgress = 0.0;
        statusMessage = '';
        targetIp = '';
        notifyListeners();
      });
    }
  }

  Future<bool> deleteRemoteFile(
    String ipStb,
    String remotePath,
    String fileName,
  ) async {
    final ftp = FTPConnect(ipStb, user: 'posterm', pass: 'dAZAD9yq', port: 21);
    try {
      await ftp.connect();
      await ftp.changeDirectory(remotePath);
      await ftp.deleteFile(fileName);
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
    }
  }
}
