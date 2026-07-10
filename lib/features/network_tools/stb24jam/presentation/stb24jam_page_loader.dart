/// Conditional export untuk Stb24JamPage.
/// Web → stub (tanpa dart:io), Desktop → real page.
export 'stb24jam_page_stub.dart'
    if (dart.library.io) 'stb24jam_page.dart';
