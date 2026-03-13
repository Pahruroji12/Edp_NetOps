import 'dart:io';
import 'package:flutter/material.dart';
import 'ftp_client.dart';
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

    final ftp = FtpClient(host: ipStb, user: 'posterm', pass: 'dAZAD9yq');
    try {
      await ftp.connect();
      await ftp.changeDirectory(remotePath);

      final fileName = file.path.split('\\').last;
      statusMessage = 'Mengirim: $fileName...';
      notifyListeners();

      await ftp.uploadFile(
        file,
        fileName,
        onProgress: (p) {
          uploadProgress = p;
          statusMessage = 'Mengirim: ${(p * 100).toStringAsFixed(1)}%...';
          notifyListeners();
        },
      );
      uploadProgress = 1.0;
      statusMessage = 'Upload berhasil!';
      _showNotif('File berhasil dikirim ke STB.', AppStatusColors.success);
    } catch (e) {
      statusMessage = 'Gagal: ${e.toString()}';
      _showNotif('Gagal upload ke STB: $e', AppStatusColors.danger);
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

    final ftp = FtpClient(host: ipStb, user: 'posterm', pass: 'dAZAD9yq');
    try {
      await ftp.connect();
      await ftp.changeDirectory(remotePath);

      // Ambil ukuran file untuk progress bar
      final totalBytes = await ftp.getFileSize(fileName);

      final savePath = localDir.endsWith('\\')
          ? '$localDir$fileName'
          : '$localDir\\$fileName';
      await ftp.downloadFile(
        fileName,
        File(savePath),
        totalBytes: totalBytes,
        onProgress: (p) {
          uploadProgress = p;
          statusMessage = 'Mengunduh: ${(p * 100).toStringAsFixed(1)}%...';
          notifyListeners();
        },
      );

      uploadProgress = 1.0;
      statusMessage = 'Download berhasil!';
      _showNotif('File berhasil diunduh ke $localDir', AppStatusColors.success);
    } catch (e) {
      statusMessage = 'Gagal: ${e.toString()}';
      _showNotif('Gagal download dari STB: $e', AppStatusColors.danger);
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
    final ftp = FtpClient(host: ipStb, user: 'posterm', pass: 'dAZAD9yq');
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
