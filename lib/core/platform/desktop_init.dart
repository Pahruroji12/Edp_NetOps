/// Desktop initializer — conditional export.
///
/// Pada Web: export stub (tidak melakukan apa-apa)
/// Pada Desktop/Mobile: export implementasi asli (window_manager, ping)
///
export 'desktop_init_stub.dart'
    if (dart.library.io) 'desktop_init_io.dart';
