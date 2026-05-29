/// Conditional export untuk TicketEmailService.
/// Web → stub (SMTP tidak tersedia), Desktop/Mobile → real service.
export 'ticket_email_service_stub.dart'
    if (dart.library.io) 'ticket_email_service.dart';
