/// Conditional export untuk TicketAttachmentSection.
/// Web → stub (tanpa desktop_drop/pasteboard), Desktop/Mobile → real widget.
export 'ticket_attachment_stub.dart'
    if (dart.library.io) 'ticket_attachment_section.dart';
