/// Stub TicketEmailService untuk Web.
///
/// SMTP email tidak tersedia di Web karena browser tidak bisa
/// membuka TCP socket langsung. Stub ini selalu return error.
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

class TicketEmailService {
  TicketEmailService._();
  static final instance = TicketEmailService._();

  Future<Result<void>> sendEmail({
    required List<String> toAddresses,
    required List<String> ccAddresses,
    required String subject,
    required String bodyText,
    List<String> attachments = const [],
  }) async {
    return const ErrorResult(
      PlatformFailure(
        'Pengiriman email tidak tersedia di versi Web.\n'
        'Gunakan aplikasi Desktop untuk mengirim tiket via email.',
      ),
    );
  }
}
