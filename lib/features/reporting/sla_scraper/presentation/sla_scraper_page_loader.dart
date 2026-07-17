/// Conditional export untuk SlaScraperPage.
/// Web → stub (tanpa dart:io), Desktop → real page.
export 'sla_scraper_page_stub.dart'
    if (dart.library.io) 'sla_scraper_page.dart';
