import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/store_model.dart';
import '../../presentation/controllers/store_list_controller.dart';
import '../../presentation/widgets/connection_badge.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../../../../core/theme/app_colors.dart';

/// StoreCard — card toko di StoreListPage.
///
/// Lokasi: features/store/presentation/widgets/store_card.dart
///
/// Sebelumnya: method _buildStoreCard() di dalam StoreListPage.
/// Sekarang: widget mandiri yang bisa dipakai di mana saja.
///
class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onTap;

  const StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String mainType = (store.connectionType ?? '-').trim().toUpperCase();
    String backupType = (store.connectionBackup ?? '').trim().toUpperCase();

    // Jika backup kosong tapi ada IP VSAT, tampilkan badge VSAT
    if ((backupType.isEmpty || backupType == '-') &&
        (store.ipVsat?.isNotEmpty == true)) {
      backupType = 'VSAT';
    }
    final bool hasBackup = backupType.isNotEmpty && backupType != '-';
    final Color cardAccent = StoreListController.connColor(
      store.connectionType ?? '',
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: cardAccent.withOpacity(0.06),
        highlightColor: cardAccent.withOpacity(0.03),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Radial glow kanan atas ────────────────────────
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [cardAccent.withOpacity(0.1), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // ── Accent bar kiri ───────────────────────────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardAccent, cardAccent.withOpacity(0.2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    // ── Avatar inisial ────────────────────────────
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardAccent.withOpacity(0.25)),
                      ),
                      child: Center(
                        child: Text(
                          store.storeCode.isNotEmpty
                              ? store.storeCode[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: cardAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Info toko ─────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Kode + Nama + tombol copy
                          Row(
                            children: [
                              _CodeBadge(
                                code: store.storeCode,
                                accent: cardAccent,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  store.storeName,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _CopyIconButton(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          '${store.storeCode} - ${store.storeName}',
                                    ),
                                  );
                                  CustomSnackBar.show(
                                    context,
                                    'Info toko disalin!',
                                    cardAccent,
                                  );
                                },
                                size: 13,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // IP Gateway + tombol copy
                          Row(
                            children: [
                              Icon(
                                Icons.router_outlined,
                                size: 10,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                store.ipGateway?.isNotEmpty == true
                                    ? store.ipGateway!
                                    : '—',
                                style: TextStyle(
                                  color: store.ipGateway?.isNotEmpty == true
                                      ? context.textSecondary
                                      : context.textSecondary.withOpacity(0.4),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (store.ipGateway?.isNotEmpty == true) ...[
                                const SizedBox(width: 6),
                                _CopyIconButton(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: store.ipGateway!),
                                    );
                                    CustomSnackBar.show(
                                      context,
                                      'IP Gateway disalin!',
                                      cardAccent,
                                    );
                                  },
                                  size: 11,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 7),

                          // Connection badges
                          Wrap(
                            spacing: 5,
                            runSpacing: 3,
                            children: [
                              if (mainType.isNotEmpty && mainType != '-')
                                ConnectionBadge(label: mainType),
                              if (hasBackup) ConnectionBadge(label: backupType),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Chevron ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────

class _CodeBadge extends StatelessWidget {
  final String code;
  final Color accent;
  const _CodeBadge({required this.code, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _CopyIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  const _CopyIconButton({required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            Icons.content_copy_rounded,
            size: size,
            color: context.textSecondary.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
