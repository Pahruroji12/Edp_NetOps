/// Conditional export untuk PingPage.
/// Web → stub (tanpa dart:io), Desktop → real page.
export 'ping_page_stub.dart'
    if (dart.library.io) 'ping_page.dart';
