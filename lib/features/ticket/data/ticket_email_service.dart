import 'package:edp_netops/core/platform/native_io.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';

class TicketEmailService {
  TicketEmailService._();
  static final instance = TicketEmailService._();

  Future<Result<Map<String, String>>> _fetchSmtpConfig() async {
    try {
      final rows = await Supabase.instance.client
          .from('app_settings')
          .select('key, value');
      return SuccessResult({for (final r in rows) r['key'] as String: r['value'] as String});
    } on PostgrestException catch (e) {
      return ErrorResult(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return ErrorResult(UnknownFailure(e.toString()));
    }
  }

  /// [attachments] : List path file foto (opsional)
  Future<Result<void>> sendEmail({
    required List<String> toAddresses,
    required List<String> ccAddresses,
    required String subject,
    required String bodyText,
    List<String> attachments = const [],
  }) async {
    try {
      final configResult = await _fetchSmtpConfig();
      if (configResult.isError) {
        return ErrorResult(configResult.errorOrNull!);
      }

      final cfg = configResult.dataOrNull!;
      final host = cfg['smtp_host'] ?? 'smtp.gmail.com';
      final port = int.tryParse(cfg['smtp_port'] ?? '587') ?? 587;
      final user = cfg['smtp_user'] ?? '';
      final pass = cfg['smtp_pass'] ?? '';
      final senderName = cfg['smtp_name'] ?? 'EDP NetOps';

      if (user.isEmpty || pass.isEmpty) {
        return const ErrorResult(ValidationFailure(
          'Konfigurasi SMTP belum diatur.\n'
          'Isi smtp_host, smtp_port, smtp_user, smtp_pass di tabel app_settings.'
        ));
      }

      final smtpServer = SmtpServer(
        host,
        port: port,
        username: user,
        password: pass,
        ssl: port == 465,
        allowInsecure: true, // izinkan self-signed cert (mail server internal)
        ignoreBadCertificate: true, // bypass verifikasi SSL untuk IP langsung
      );

      final message = Message()
        ..from = Address(user, senderName)
        ..recipients.addAll(toAddresses.map((e) => Address(e)))
        ..ccRecipients.addAll(ccAddresses.map((e) => Address(e)))
        ..subject = subject
        ..text = bodyText;

      // Lampirkan foto jika ada
      for (final path in attachments) {
        final file = File(path);
        if (await file.exists()) {
          // ignore: argument_type_not_assignable
          message.attachments.add(FileAttachment(file as dynamic));
        }
      }

      await send(message, smtpServer);
      return const SuccessResult(null);
    } catch (e) {
      return ErrorResult(NetworkFailure(e.toString()));
    }
  }
}
