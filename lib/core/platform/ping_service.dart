/// Ping service — conditional export.
/// Web → stub (dart_ping tidak tersedia), Desktop/Mobile → real ping.
export 'ping_service_stub.dart'
    if (dart.library.io) 'ping_service_io.dart';
