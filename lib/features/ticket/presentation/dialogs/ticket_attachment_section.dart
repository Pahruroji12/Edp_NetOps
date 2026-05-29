import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';

/// Section foto lampiran pada dialog tiket.
///
/// Lokasi: features/ticket/presentation/dialogs/ticket_attachment_section.dart
///
/// Mendukung 3 cara input:
///   1. Tombol "Tambah Foto" → image_picker
///   2. Drag & drop file dari Explorer → desktop_drop
///   3. Paste (Ctrl+V) dari clipboard → pasteboard
///
class TicketAttachmentSection extends StatefulWidget {
  final List<XFile> images;
  final ValueChanged<List<XFile>> onImagesAdded;
  final ValueChanged<int> onImageRemoved;

  const TicketAttachmentSection({
    super.key,
    required this.images,
    required this.onImagesAdded,
    required this.onImageRemoved,
  });

  @override
  State<TicketAttachmentSection> createState() =>
      _TicketAttachmentSectionState();
}

class _TicketAttachmentSectionState extends State<TicketAttachmentSection> {
  bool _isDragging = false;

  // ── Allowed image extensions ──────────────────────────────────
  static const _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
  };

  bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return _imageExtensions.any((e) => ext.endsWith(e));
  }

  // ── Paste from clipboard (Ctrl+V) ─────────────────────────────
  Future<void> _handlePaste() async {
    try {
      // Coba ambil file paths dari clipboard (misal copy file dari Explorer)
      final files = await Pasteboard.files();
      if (files.isNotEmpty) {
        final imageFiles = files
            .where((f) => _isImageFile(f))
            .map((f) => XFile(f))
            .toList();
        if (imageFiles.isNotEmpty) {
          widget.onImagesAdded(imageFiles);
          return;
        }
      }

      // Coba ambil image bytes dari clipboard (misal screenshot / copy image)
      final Uint8List? imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        // Simpan ke temp file
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/paste_$timestamp.png');
        await tempFile.writeAsBytes(imageBytes);
        widget.onImagesAdded([XFile(tempFile.path)]);
        return;
      }
    } catch (_) {
      // Clipboard kosong atau format tidak didukung — abaikan
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: false,
      onKeyEvent: (event) {
        // Ctrl+V handler
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyV &&
            HardwareKeyboard.instance.isControlPressed) {
          _handlePaste();
        }
      },
      child: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) {
          setState(() => _isDragging = false);
          final imageFiles = details.files
              .where((f) => _isImageFile(f.path))
              .map((f) => XFile(f.path))
              .toList();
          if (imageFiles.isNotEmpty) {
            widget.onImagesAdded(imageFiles);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: _isDragging
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.accentColor,
                    width: 2,
                  ),
                  color: context.accentColor.withOpacity(0.06),
                )
              : null,
          padding: _isDragging ? const EdgeInsets.all(8) : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              if (_isDragging)
                _buildDropZone(context)
              else if (widget.images.isEmpty)
                _buildEmptyPlaceholder(context)
              else ...[
                _buildImageList(context),
                const SizedBox(height: 6),
                Text(
                  '${widget.images.length} foto dipilih',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.accentColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              _buildHintRow(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.photo_camera_outlined,
            size: 12, color: context.textSecondary),
        const SizedBox(width: 5),
        Text(
          'FOTO LAMPIRAN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: context.textSecondary,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Opsional',
          style: TextStyle(
            fontSize: 10,
            color: context.textSecondary.withOpacity(0.55),
          ),
        ),
        const Spacer(),
        // Paste button
        _buildMiniButton(
          context,
          icon: Icons.content_paste_rounded,
          label: 'Paste',
          onTap: _handlePaste,
        ),
        const SizedBox(width: 6),
        // Browse button
        _buildMiniButton(
          context,
          icon: Icons.add_photo_alternate_outlined,
          label: 'Tambah Foto',
          onTap: () async {
            final picked =
                await ImagePicker().pickMultiImage(imageQuality: 70);
            if (picked.isNotEmpty) widget.onImagesAdded(picked);
          },
        ),
      ],
    );
  }

  Widget _buildMiniButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: context.accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: context.accentColor.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: context.accentColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drop Zone (aktif saat dragging) ────────────────────────────
  Widget _buildDropZone(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.accentColor.withOpacity(0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: context.accentColor.withOpacity(0.04),
      ),
      child: Column(
        children: [
          Icon(Icons.file_download_outlined,
              size: 32, color: context.accentColor),
          const SizedBox(height: 8),
          Text(
            'Lepaskan file di sini',
            style: TextStyle(
              fontSize: 13,
              color: context.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty Placeholder ──────────────────────────────────────────
  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.image_outlined,
              size: 24, color: context.textSecondary.withOpacity(0.35)),
          const SizedBox(height: 4),
          Text(
            'Belum ada foto yang dipilih',
            style: TextStyle(
                fontSize: 12,
                color: context.textSecondary.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }

  // ── Image Preview List ─────────────────────────────────────────
  Widget _buildImageList(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        itemBuilder: (_, i) => Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: context.accentColor.withOpacity(0.3)),
                image: DecorationImage(
                  image: FileImage(File(widget.images[i].path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 12,
              child: GestureDetector(
                onTap: () => widget.onImageRemoved(i),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hint Row ───────────────────────────────────────────────────
  Widget _buildHintRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 11, color: context.textSecondary.withOpacity(0.4)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Drag & drop file gambar, atau tekan Ctrl+V untuk paste dari clipboard',
            style: TextStyle(
              fontSize: 10,
              color: context.textSecondary.withOpacity(0.45),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
