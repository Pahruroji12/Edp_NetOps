import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ftp_client.dart';
import 'package:edp_netops/core/utils/notification_mixin.dart';
export 'package:edp_netops/core/utils/notification_mixin.dart' show NotifLevel;

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

// ── Notification level — centralized di core/utils/notification_mixin.dart ───

// ── FtpService ────────────────────────────────────────────────────────────────

class FtpService extends ChangeNotifier {
  static FtpService? _instance;
  factory FtpService() {
    _instance ??= FtpService._internal();
    return _instance!;
  }
  FtpService._internal();

  // ── FTP Credentials (diisi oleh controller dari SettingsRepository) ────
  String _ftpUser = '';
  String _ftpPass = '';

  /// Set credentials dari app_settings.
  /// Harus dipanggil sebelum operasi FTP pertama.
  void setCredentials({required String user, required String pass}) {
    _ftpUser = user;
    _ftpPass = pass;
  }

  bool get hasCredentials => _ftpUser.isNotEmpty;

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

  // ── Notification state (dikonsumsi oleh Page) ──────────────────────────
  String? pendingNotifMessage;
  NotifLevel? pendingNotifLevel;

  void _emitNotif(String message, NotifLevel level) {
    pendingNotifMessage = message;
    pendingNotifLevel = level;
    notifyListeners();
  }

  void clearNotification() {
    pendingNotifMessage = null;
    pendingNotifLevel = null;
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

    final ftp = FtpClient(host: ipStb, user: _ftpUser, pass: _ftpPass);
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
      _emitNotif(
        '[$storeCode] File berhasil dikirim ke STB.',
        NotifLevel.success,
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
      _emitNotif('[$storeCode] Upload dibatalkan.', NotifLevel.warning);
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
      _emitNotif('[$storeCode] Gagal upload: $e', NotifLevel.error);
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

    final ftp = FtpClient(host: ipStb, user: _ftpUser, pass: _ftpPass);
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
      _emitNotif(
        '[$storeCode] File berhasil diunduh ke $localDir',
        NotifLevel.success,
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
      _emitNotif('[$storeCode] Download dibatalkan.', NotifLevel.warning);
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
      _emitNotif('[$storeCode] Gagal download: $e', NotifLevel.error);
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
    final ftp = FtpClient(host: ipStb, user: _ftpUser, pass: _ftpPass);
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
