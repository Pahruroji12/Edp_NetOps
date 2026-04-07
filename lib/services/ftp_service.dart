import 'dart:io';
import 'package:flutter/material.dart';
import 'ftp_client.dart';
import '../utils/app_colors.dart';
import '../utils/globals.dart';
import '../utils/custom_snackbar.dart';

// ── Transfer History ──────────────────────────────────────────────────────────

enum TransferType { upload, download }

class TransferHistoryItem {
  final String fileName;
  final TransferType type;
  final bool success;
  final DateTime time;
  final String detail;
  final String storeCode;

  TransferHistoryItem({
    required this.fileName,
    required this.type,
    required this.success,
    required this.time,
    this.detail = '',
    this.storeCode = '',
  });
}

// ── Active Transfer Job ───────────────────────────────────────────────────────

enum TransferJobStatus { running, cancelled, done, failed }

class TransferJob extends ChangeNotifier {
  final String id;
  final String fileName;
  final TransferType type;
  final String storeCode;
  final String targetIp;

  TransferJobStatus status = TransferJobStatus.running;
  double progress = 0.0;
  String statusText = '';
  bool _cancelRequested = false;

  TransferJob({
    required this.id,
    required this.fileName,
    required this.type,
    required this.storeCode,
    required this.targetIp,
  });

  bool get isActive => status == TransferJobStatus.running;
  bool get cancelRequested => _cancelRequested;

  void requestCancel() {
    _cancelRequested = true;
    statusText = 'Membatalkan...';
    notifyListeners();
  }

  void updateProgress(double p, String text) {
    progress = p;
    statusText = text;
    notifyListeners();
  }

  void markDone() {
    status = TransferJobStatus.done;
    progress = 1.0;
    notifyListeners();
  }

  void markFailed(String error) {
    status = TransferJobStatus.failed;
    statusText = error;
    notifyListeners();
  }

  void markCancelled() {
    status = TransferJobStatus.cancelled;
    statusText = 'Dibatalkan';
    notifyListeners();
  }
}

// ── FtpService ────────────────────────────────────────────────────────────────

class FtpService extends ChangeNotifier {
  static FtpService? _instance;
  factory FtpService() {
    _instance ??= FtpService._internal();
    return _instance!;
  }
  FtpService._internal();

  // Active jobs — bisa lebih dari satu (multi-store concurrent)
  final List<TransferJob> activeJobs = [];
  final List<TransferHistoryItem> history = [];

  bool get isUploading =>
      activeJobs.any((j) => j.type == TransferType.upload && j.isActive);
  bool get isDownloading =>
      activeJobs.any((j) => j.type == TransferType.download && j.isActive);

  // Backward-compat untuk panel lama
  String get statusMessage =>
      activeJobs.isEmpty ? '' : activeJobs.first.statusText;
  double get uploadProgress =>
      activeJobs.isEmpty ? 0.0 : activeJobs.first.progress;
  String get activeStoreCode =>
      activeJobs.isEmpty ? '' : activeJobs.first.storeCode;

  void _showNotif(String message, Color color) {
    CustomSnackBar.showFromKey(globalMessengerKey, message, color);
  }

  void _removeJobAfterDelay(TransferJob job) {
    Future.delayed(const Duration(seconds: 4), () {
      activeJobs.remove(job);
      notifyListeners();
    });
  }

  // ── CANCEL ───────────────────────────────────────────────────────────────

  void cancelJob(String jobId) {
    final job = activeJobs.firstWhere(
      (j) => j.id == jobId,
      orElse: () => throw Exception('Job not found'),
    );
    job.requestCancel();
    notifyListeners();
  }

  // ── UPLOAD ───────────────────────────────────────────────────────────────

  Future<void> sendPromoFile(
    String ipStb,
    String remotePath,
    File file, {
    String storeCode = '',
  }) async {
    final fileName = file.path.split('\\').last;
    final job = TransferJob(
      id: '${DateTime.now().millisecondsSinceEpoch}_up_$storeCode',
      fileName: fileName,
      type: TransferType.upload,
      storeCode: storeCode,
      targetIp: ipStb,
    );
    job.statusText = 'Menghubungkan ke $ipStb...';
    activeJobs.add(job);
    notifyListeners();

    // Listen job changes → notify service listeners juga
    job.addListener(notifyListeners);

    final ftp = FtpClient(host: ipStb, user: 'posterm', pass: 'dAZAD9yq');
    try {
      await ftp.connect();

      if (job.cancelRequested) throw _CancelException();

      await ftp.changeDirectory(remotePath);
      job.updateProgress(0.0, 'Mengirim: $fileName...');

      await ftp.uploadFile(
        file,
        fileName,
        onProgress: (p) {
          if (job.cancelRequested) throw _CancelException();
          // Max 99% sampai server konfirmasi
          job.updateProgress(
            (p * 0.99).clamp(0.0, 0.99),
            'Mengirim: ${(p * 99).toStringAsFixed(1)}%...',
          );
        },
      );

      job.updateProgress(0.99, 'Menunggu konfirmasi server...');
      job.markDone();

      final fileSize = await file.length();
      _showNotif(
        '[$storeCode] File berhasil dikirim ke STB.',
        AppStatusColors.success,
      );
      history.insert(
        0,
        TransferHistoryItem(
          fileName: fileName,
          type: TransferType.upload,
          success: true,
          time: DateTime.now(),
          detail: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
          storeCode: storeCode,
        ),
      );
    } on _CancelException {
      job.markCancelled();
      _showNotif('[$storeCode] Upload dibatalkan.', AppStatusColors.warning);
      history.insert(
        0,
        TransferHistoryItem(
          fileName: fileName,
          type: TransferType.upload,
          success: false,
          time: DateTime.now(),
          detail: 'Dibatalkan',
          storeCode: storeCode,
        ),
      );
    } catch (e) {
      job.markFailed(e.toString());
      _showNotif('[$storeCode] Gagal upload: $e', AppStatusColors.danger);
      history.insert(
        0,
        TransferHistoryItem(
          fileName: fileName,
          type: TransferType.upload,
          success: false,
          time: DateTime.now(),
          detail: e.toString(),
          storeCode: storeCode,
        ),
      );
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
      _removeJobAfterDelay(job);
      notifyListeners();
    }
  }

  // ── DOWNLOAD ─────────────────────────────────────────────────────────────

  Future<void> downloadFile(
    String ipStb,
    String remotePath,
    String fileName,
    String localDir, {
    String storeCode = '',
  }) async {
    final job = TransferJob(
      id: '${DateTime.now().millisecondsSinceEpoch}_dl_$storeCode',
      fileName: fileName,
      type: TransferType.download,
      storeCode: storeCode,
      targetIp: ipStb,
    );
    job.statusText = 'Menghubungkan ke $ipStb...';
    activeJobs.add(job);
    notifyListeners();

    job.addListener(notifyListeners);

    final ftp = FtpClient(host: ipStb, user: 'posterm', pass: 'dAZAD9yq');
    try {
      await ftp.connect();

      if (job.cancelRequested) throw _CancelException();

      await ftp.changeDirectory(remotePath);
      final totalBytes = await ftp.getFileSize(fileName);

      final savePath = localDir.endsWith('\\')
          ? '$localDir$fileName'
          : '$localDir\\$fileName';

      await ftp.downloadFile(
        fileName,
        File(savePath),
        totalBytes: totalBytes,
        onProgress: (p) {
          if (job.cancelRequested) throw _CancelException();
          job.updateProgress(
            (p * 0.99).clamp(0.0, 0.99),
            'Mengunduh: ${(p * 99).toStringAsFixed(1)}%...',
          );
        },
      );

      job.markDone();
      _showNotif(
        '[$storeCode] File berhasil diunduh ke $localDir',
        AppStatusColors.success,
      );
      history.insert(
        0,
        TransferHistoryItem(
          fileName: fileName,
          type: TransferType.download,
          success: true,
          time: DateTime.now(),
          detail: totalBytes > 0
              ? '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
              : '',
          storeCode: storeCode,
        ),
      );
    } on _CancelException {
      job.markCancelled();
      _showNotif('[$storeCode] Download dibatalkan.', AppStatusColors.warning);
      history.insert(
        0,
        TransferHistoryItem(
          fileName: fileName,
          type: TransferType.download,
          success: false,
          time: DateTime.now(),
          detail: 'Dibatalkan',
          storeCode: storeCode,
        ),
      );
    } catch (e) {
      job.markFailed(e.toString());
      _showNotif('[$storeCode] Gagal download: $e', AppStatusColors.danger);
      history.insert(
        0,
        TransferHistoryItem(
          fileName: fileName,
          type: TransferType.download,
          success: false,
          time: DateTime.now(),
          detail: e.toString(),
          storeCode: storeCode,
        ),
      );
    } finally {
      try {
        await ftp.disconnect();
      } catch (_) {}
      _removeJobAfterDelay(job);
      notifyListeners();
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

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

class _CancelException implements Exception {}
