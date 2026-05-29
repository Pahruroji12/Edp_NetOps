import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// FtpActionColumn — tombol Upload, Download, Hapus L, Hapus R.
class FtpActionColumn extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final VoidCallback? onDeleteLocal;
  final VoidCallback? onDeleteRemote;
  final bool isDeletingLocal;
  final bool isDeletingRemote;

  const FtpActionColumn({
    super.key,
    required this.onUpload,
    required this.onDownload,
    this.onDeleteLocal,
    this.onDeleteRemote,
    this.isDeletingLocal = false,
    this.isDeletingRemote = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(vertical: BorderSide(color: context.borderColor.withOpacity(0.5))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FtpActionButton(icon: Icons.upload_rounded, label: "Upload", color: context.successColor, onTap: onUpload),
          const SizedBox(height: 10),
          _FtpActionButton(icon: Icons.download_rounded, label: "Download", color: context.accentColor, onTap: onDownload),
          const SizedBox(height: 10),
          _FtpActionButton(icon: Icons.delete_outline_rounded, label: "Hapus L", color: context.warningColor, onTap: isDeletingLocal ? null : onDeleteLocal, isLoading: isDeletingLocal),
          const SizedBox(height: 10),
          _FtpActionButton(icon: Icons.delete_forever_rounded, label: "Hapus R", color: context.dangerColor, onTap: isDeletingRemote ? null : onDeleteRemote, isLoading: isDeletingRemote),
        ],
      ),
    );
  }
}

class _FtpActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _FtpActionButton({required this.icon, required this.label, required this.color, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: disabled ? context.borderColor.withOpacity(0.08) : color.withOpacity(0.08),
              border: Border.all(color: disabled ? context.borderColor.withOpacity(0.3) : color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              isLoading
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                  : Icon(icon, color: disabled ? context.textSecondary.withOpacity(0.3) : color, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: disabled ? context.textSecondary.withOpacity(0.3) : color, fontSize: 8, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}
