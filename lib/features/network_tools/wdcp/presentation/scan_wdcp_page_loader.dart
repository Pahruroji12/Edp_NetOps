/// Conditional export untuk ScanWdcpPage.
/// Web → stub (tanpa dart:io), Desktop → real page.
export 'scan_wdcp_page_stub.dart'
    if (dart.library.io) 'scan_wdcp_page.dart';
