import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../features/store/domain/store_model.dart';
import '../../../../../features/store/presentation/controllers/store_list_controller.dart';
import '../../../../../features/store/presentation/pages/store_detail_page.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/widgets/custom_snackbar.dart';

/// StoreListCard — kartu daftar toko dengan search di DashboardPage.
///
/// Lokasi: features/dashboard/presentation/widgets/store_list_card.dart
///
class StoreListCard extends StatelessWidget {
  final List<StoreModel> stores;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onSearch;

  const StoreListCard({
    super.key,
    required this.stores,
    required this.searchController,
    required this.scrollController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header: search + badge ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final isWide = constraints.maxWidth >= 420;

                final titleWidget = Text(
                  'Daftar Toko',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                );

                final searchWidget = SizedBox(
                  width: isWide ? 190 : double.infinity,
                  height: 36,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: context.accentColor,
                        selectionColor: context.accentColor.withOpacity(0.3),
                        selectionHandleColor: context.accentColor,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari toko...',
                        hintStyle: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: context.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        filled: true,
                        fillColor: context.surfaceColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.accentColor,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 14,
                                  color: context.textSecondary,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  onSearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                );

                final badgeWidget = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '${stores.length} Toko',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.accentColor,
                    ),
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      titleWidget,
                      const Spacer(),
                      searchWidget,
                      const SizedBox(width: 10),
                      badgeWidget,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [titleWidget, const Spacer(), badgeWidget]),
                      const SizedBox(height: 10),
                      searchWidget,
                    ],
                  );
                }
              },
            ),
          ),

          Container(height: 1, color: context.borderColor),

          // ── Store list ────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (context.screenHeight * 0.35).clamp(200, 500),
            ),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              radius: const Radius.circular(10),
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.zero,
                itemCount: stores.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: context.borderColor.withOpacity(0.5),
                ),
                itemBuilder: (context, index) =>
                    _StoreItem(store: stores[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private store item widget ─────────────────────────────────────────────────

class _StoreItem extends StatelessWidget {
  final StoreModel store;
  const _StoreItem({required this.store});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreDetailPage(store: store)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store_rounded,
                  size: 18,
                  color: context.accentColor,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${store.storeCode} - ${store.storeName}',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
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
                                context.accentColor,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.content_copy_rounded,
                                size: 13,
                                color: context.textSecondary.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ConnectionBadge(label: store.connectionType ?? '-'),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Connection badge (pakai StoreListController.connColor) ────────────────────

class _ConnectionBadge extends StatelessWidget {
  final String label;
  const _ConnectionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = StoreListController.connColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
