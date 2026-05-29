/// Stub TicketAttachmentSection untuk Web.
///
/// Versi ini hanya menyediakan tombol "Tambah Foto" via image_picker
/// (yang sudah support Web). Fitur drag-drop dan paste dihilangkan
/// karena desktop_drop dan pasteboard tidak tersedia di Web.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class TicketAttachmentSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────
        Row(
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
            // Browse button — image_picker support Web
            GestureDetector(
              onTap: () async {
                final picked =
                    await ImagePicker().pickMultiImage(imageQuality: 70);
                if (picked.isNotEmpty) onImagesAdded(picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: context.accentColor.withOpacity(0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 13, color: context.accentColor),
                    const SizedBox(width: 5),
                    Text(
                      'Tambah Foto',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Image list or empty placeholder ─────────────────────
        if (images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.image_outlined,
                    size: 24,
                    color: context.textSecondary.withOpacity(0.35)),
                const SizedBox(height: 4),
                Text(
                  'Belum ada foto yang dipilih',
                  style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary.withOpacity(0.45)),
                ),
              ],
            ),
          )
        else ...[
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
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
                      color: context.surfaceColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FutureBuilder<dynamic>(
                        future: images[i].readAsBytes(),
                        builder: (ctx, snap) {
                          if (snap.hasData) {
                            return Image.memory(snap.data,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90);
                          }
                          return const Center(
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)));
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => onImageRemoved(i),
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
          ),
          const SizedBox(height: 6),
          Text(
            '${images.length} foto dipilih',
            style: TextStyle(
              fontSize: 11,
              color: context.accentColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
