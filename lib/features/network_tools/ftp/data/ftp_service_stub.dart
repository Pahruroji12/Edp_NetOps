/// Stub FtpService untuk Web — menyediakan API surface yang sama
/// tetapi tidak melakukan operasi FTP apapun.
///
/// Class-class ini TIDAK akan pernah benar-benar dipakai di Web
/// karena semua fitur FTP sudah di-guard oleh FeatureAvailability.
///
/// Tujuan: agar kode yang import FtpService tetap COMPILE di Web.

import 'package:flutter/foundation.dart';
import 'package:edp_netops/core/utils/notification_mixin.dart';
export 'package:edp_netops/core/utils/notification_mixin.dart' show NotifLevel;

// ── Transfer Types ────────────────────────────────────────────────

enum TransferType { upload, download }

// ── Transfer History ──────────────────────────────────────────────

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

// ── Transfer Job ──────────────────────────────────────────────────

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

  TransferJob({
    required this.id,
    required this.fileName,
    required this.type,
    required this.storeCode,
    required this.targetIp,
  });

  bool get isActive => status == TransferJobStatus.running;
  bool get cancelRequested => false;

  void requestCancel() {}
  void updateProgress(double p, String text) {}
  void markDone() {}
  void markFailed(String error) {}
  void markCancelled() {}
}

// ── FtpService ────────────────────────────────────────────────────

class FtpService extends ChangeNotifier {
  static FtpService? _instance;
  factory FtpService() {
    _instance ??= FtpService._internal();
    return _instance!;
  }
  FtpService._internal();

  void setCredentials({required String user, required String pass}) {}
  bool get hasCredentials => false;

  final List<TransferJob> activeJobs = [];
  final List<TransferHistoryItem> history = [];

  bool get isUploading => false;
  bool get isDownloading => false;
  String get statusMessage => '';
  double get uploadProgress => 0.0;
  String get activeStoreCode => '';

  String? pendingNotifMessage;
  NotifLevel? pendingNotifLevel;

  void clearNotification() {
    pendingNotifMessage = null;
    pendingNotifLevel = null;
  }

  void cancelJob(String jobId) {}
}
