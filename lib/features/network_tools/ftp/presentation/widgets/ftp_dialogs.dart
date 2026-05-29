import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// FtpDialogs — dialog konfirmasi delete file dan cancel transfer.
class FtpDeleteDialog extends StatelessWidget {
  final String fileName;
  final bool isLocal;

  const FtpDeleteDialog({super.key, required this.fileName, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.borderColor)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.dangerColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, color: context.dangerColor, size: 28)),
            const SizedBox(height: 16),
            Text("Hapus File", style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(isLocal ? "Hapus file berikut dari PC?" : "Hapus file berikut dari STB?", textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor)),
              child: Text(fileName, style: TextStyle(color: context.accentColor, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(side: BorderSide(color: context.borderColor), foregroundColor: context.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("Batal"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: context.dangerColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.w700)))),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// FtpCancelTransferDialog — dialog konfirmasi batal transfer.
class FtpCancelTransferDialog extends StatelessWidget {
  final String fileName;
  const FtpCancelTransferDialog({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.borderColor)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.warningColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.cancel_outlined, color: context.warningColor, size: 28)),
            const SizedBox(height: 16),
            Text("Batalkan Transfer?", style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text("Transfer yang sudah terkirim tidak bisa dikembalikan.", textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor)),
              child: Text(fileName, style: TextStyle(color: context.accentColor, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(side: BorderSide(color: context.borderColor), foregroundColor: context.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("Lanjutkan"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: context.warningColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("Batalkan", style: TextStyle(fontWeight: FontWeight.w700)))),
            ]),
          ]),
        ),
      ),
    );
  }
}
