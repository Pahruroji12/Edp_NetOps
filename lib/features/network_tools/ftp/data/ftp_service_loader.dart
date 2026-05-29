/// Conditional export untuk FtpService + TransferJob.
/// Web → stub (aman, tidak crash), Desktop/Mobile → real service.
export 'ftp_service_stub.dart'
    if (dart.library.io) 'ftp_service.dart';
