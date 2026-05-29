import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/store/domain/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/error/failures.dart';
import '../../data/ticket_email_data.dart';
import '../../data/ticket_email_service_loader.dart';
import '../../data/ticket_repository.dart';
import 'ticket_form_widgets.dart';
import 'ticket_attachment_loader.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TicketDialog — Enterprise Open Tiket Popup (Refactored)
//
// Dipanggil dari StoreDetailPage via: TicketDialog.show(context, store, key)
//
// Struktur:
//   - TicketEmailData       → data/template email per provider
//   - ticket_form_widgets   → EmailChip, FieldLabel, RecipientRow, TextField
//   - TicketAttachmentSection → foto lampiran
//   - TicketDialog          → orchestrator (file ini)
// ═════════════════════════════════════════════════════════════════════════════

class TicketDialog {
  TicketDialog._();

  /// Tampilkan dialog open tiket.
  /// [key]      : 'astinet' | 'icon' | 'fiberstar'
  /// [isBackup] : true jika koneksi yang bermasalah adalah backup
  static void show(
    BuildContext context,
    StoreModel store,
    String key, {
    bool isBackup = false,
  }) {
    final emailData = TicketEmailData.fromProvider(store, key, isBackup: isBackup);

    final toCtrl = TextEditingController(text: emailData.to);
    final ccCtrl = TextEditingController(text: emailData.cc);
    final picCtrl = TextEditingController();
    final kendalaCtrl = TextEditingController();

    bool isSending = false;
    bool isEditingRecipients = false;
    List<XFile> attachedImages = [];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // ── Send handler ────────────────────────────────────────
            Future<void> handleSend() async {
              if (picCtrl.text.trim().isEmpty) {
                CustomSnackBar.show(ctx, 'Nomor PIC wajib diisi', Colors.orange);
                return;
              }
              if (kendalaCtrl.text.trim().isEmpty) {
                CustomSnackBar.show(ctx, 'Kendala wajib diisi', Colors.orange);
                return;
              }
              setDialogState(() => isSending = true);
              
              final result = await TicketEmailService.instance.sendEmail(
                toAddresses: TicketEmailData.parseEmails(toCtrl.text),
                ccAddresses: TicketEmailData.parseEmails(ccCtrl.text),
                subject: emailData.subject,
                bodyText: emailData.buildFinalBody(
                  pic: picCtrl.text.trim(),
                  kendala: kendalaCtrl.text.trim(),
                ),
                attachments: attachedImages.map((f) => f.path).toList(),
              );

              result.fold(
                (Failure failure) {
                  setDialogState(() => isSending = false);
                  CustomSnackBar.show(ctx, 'Gagal kirim: ${failure.message}', Colors.red);
                },
                (_) async {
                  final insertResult = await TicketRepository().insert(
                    storeCode: store.storeCode,
                    storeName: store.storeName,
                    provider: emailData.label,
                  );
                  
                  insertResult.fold(
                    (Failure insertFailure) {
                      setDialogState(() => isSending = false);
                      CustomSnackBar.show(ctx, 'Email terkirim tapi gagal menyimpan ke history: ${insertFailure.message}', Colors.orange);
                    },
                    (_) {
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        CustomSnackBar.show(
                          context,
                          'Tiket ${emailData.label} berhasil dikirim & disimpan!',
                          const Color(0xFF00C853),
                        );
                      }
                    }
                  );
                },
              );
            }

            // ── UI ──────────────────────────────────────────────────
            return Theme(
              data: Theme.of(ctx).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: ctx.accentColor.withOpacity(0.25),
                  cursorColor: ctx.accentColor,
                  selectionHandleColor: ctx.accentColor,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ctx.dialogMaxWidth(base: 520)),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: ctx.dialogMargin, vertical: ctx.scaledPadding(24)),
                      decoration: BoxDecoration(
                        color: ctx.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ctx.borderColor, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── HEADER ──────────────────────────────
                            _buildHeader(ctx, store, emailData.label, isSending, dialogContext),

                            // ── BODY ────────────────────────────────
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSubjectBox(ctx, emailData.subject),
                                    const SizedBox(height: 14),

                                    _buildRecipientSection(
                                      ctx, toCtrl, ccCtrl,
                                      isEditingRecipients,
                                      () => setDialogState(
                                        () => isEditingRecipients = !isEditingRecipients,
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // PIC
                                    const TicketFieldLabel(
                                      text: 'Nomor PIC',
                                      icon: Icons.badge_outlined,
                                      isRequired: true,
                                    ),
                                    TicketTextField(
                                      controller: picCtrl,
                                      hintText: 'Nama / Nomor HP...',
                                      prefixIcon: Icons.person_outline_rounded,
                                    ),
                                    const SizedBox(height: 14),

                                    // Kendala
                                    const TicketFieldLabel(
                                      text: 'Kendala / Deskripsi Masalah',
                                      icon: Icons.report_problem_outlined,
                                      isRequired: true,
                                    ),
                                    TicketTextField(
                                      controller: kendalaCtrl,
                                      hintText: 'Deskripsikan kendala yang dialami toko...',
                                      maxLines: 4,
                                    ),
                                    const SizedBox(height: 14),

                                    // Foto
                                    TicketAttachmentSection(
                                      images: attachedImages,
                                      onImagesAdded: (picked) =>
                                          setDialogState(() => attachedImages.addAll(picked)),
                                      onImageRemoved: (i) =>
                                          setDialogState(() => attachedImages.removeAt(i)),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── FOOTER ──────────────────────────────
                            _buildFooter(ctx, dialogContext, isSending, attachedImages, handleSend),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS — private statics
  // ════════════════════════════════════════════════════════════════════

  static Widget _buildHeader(
    BuildContext ctx,
    StoreModel store,
    String providerLabel,
    bool isSending,
    BuildContext dialogContext,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: ctx.accentColor.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: ctx.accentColor.withOpacity(0.12))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ctx.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.confirmation_number_outlined, color: ctx.accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.storeCode} — ${store.storeName}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.textPrimary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(providerLabel, style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.3)),
            ),
            child: const Text(
              'Open Tiket',
              style: TextStyle(fontSize: 10, color: Color(0xFFEF5350), fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
            icon: Icon(Icons.close_rounded, color: ctx.textSecondary, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  static Widget _buildSubjectBox(BuildContext ctx, String subject) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: ctx.primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ctx.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.subject_rounded, size: 12, color: ctx.textSecondary),
              const SizedBox(width: 5),
              Text(
                'SUBJECT',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: ctx.textSecondary, letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subject,
            style: TextStyle(
              fontSize: 12, color: ctx.textSecondary,
              fontStyle: FontStyle.italic, height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRecipientSection(
    BuildContext ctx,
    TextEditingController toCtrl,
    TextEditingController ccCtrl,
    bool isEditing,
    VoidCallback onToggleEdit,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ctx.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header penerima
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: ctx.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: ctx.borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.alternate_email_rounded, size: 13, color: ctx.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'PENERIMA EMAIL',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: ctx.textSecondary, letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ctx.accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: ctx.accentColor.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEditing ? Icons.lock_outline_rounded : Icons.edit_outlined,
                          size: 11, color: ctx.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEditing ? 'Kunci' : 'Edit',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: ctx.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // To & CC
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                RecipientRow(
                  label: 'To',
                  controller: toCtrl,
                  isPrimaryChip: true,
                  isEditing: isEditing,
                ),
                const SizedBox(height: 8),
                RecipientRow(
                  label: 'Cc',
                  controller: ccCtrl,
                  isPrimaryChip: false,
                  isEditing: isEditing,
                  minLines: 3,
                  maxLines: 4,
                  maxVisible: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFooter(
    BuildContext ctx,
    BuildContext dialogContext,
    bool isSending,
    List<XFile> attachedImages,
    Future<void> Function() handleSend,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: ctx.cardColor,
        border: Border(top: BorderSide(color: ctx.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (attachedImages.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: ctx.accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: ctx.accentColor.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 13, color: ctx.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    '${attachedImages.length} foto akan dilampirkan',
                    style: TextStyle(fontSize: 11, color: ctx.accentColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ctx.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: ctx.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isSending ? null : handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctx.accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    disabledBackgroundColor: ctx.accentColor.withOpacity(0.4),
                  ),
                  child: isSending
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text('Mengirim...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 15),
                            SizedBox(width: 8),
                            Text('Kirim Tiket', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
