/// Conditional export untuk FtpPage.
/// Web → stub (tanpa dart:io/ftpconnect), Desktop/Mobile → real page.
export 'ftp_page_stub.dart'
    if (dart.library.io) 'ftp_page.dart';
