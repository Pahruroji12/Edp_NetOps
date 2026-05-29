import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/network_action_buttons.dart';
import '../data/scan_rbwdcp_service.dart';

/// ScanWdcpWidgets — reusable UI components untuk ScanWdcpPage.
///
/// Lokasi: features/network_tools/wdcp/presentation/scan_wdcp_widgets.dart

// ══════════════════════════════════════════════════════════════
// SCANNER PANEL
// ══════════════════════════════════════════════════════════════

class WdcpScannerPanel extends StatelessWidget {
  final ScanRbwdcpService scan;
  final VoidCallback onFixNoTargets;
  final VoidCallback onCsvTap;

  const WdcpScannerPanel({
    super.key,
    required this.scan,
    required this.onFixNoTargets,
    required this.onCsvTap,
  });

  @override
  Widget build(BuildContext context) {
    final scanColor =
        scan.isScanning ? AppStatusColors.danger : context.accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security_rounded,
                    color: context.accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SCAN WDCP Y",
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(scan.scanStatus,
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (scan.scanFilePath != null) ...[
                    _buildCsvButton(context),
                    const SizedBox(width: 6),
                  ],
                  _buildScanButton(context, scanColor),
                ],
              ),
            ],
          ),

          // ── Progress bar ──
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: scan.isScanning ? scan.scanProgress : 0.0,
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                  scan.isScanning ? context.accentColor : Colors.transparent),
              minHeight: 4,
            ),
          ),

          // ── Stats ──
          if (scan.scanTotal > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _statChip('Berhasil', '${scan.scanSuccess}',
                    context.successColor, Icons.check_circle_outline_rounded),
                const SizedBox(width: 8),
                _statChip('Offline', '${scan.scanOffline}',
                    AppStatusColors.danger, Icons.cancel_outlined),
                const SizedBox(width: 8),
                _statChip('Default Auth', '${scan.scanAuthActive}',
                    context.warningColor, Icons.warning_amber_rounded),
                const Spacer(),
                Text('${scan.scanCompleted}/${scan.scanTotal}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                        fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  context.borderColor,
                  Colors.transparent,
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _buildFixRow(context),
            if (scan.isFixing || scan.fixCompleted > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: scan.isFixing ? scan.fixProgress : 1.0,
                  backgroundColor: context.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(scan.fixFailed > 0
                      ? AppStatusColors.danger
                      : context.warningColor),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _statChip('Fixed', '${scan.fixSuccess}',
                      context.successColor, Icons.check_rounded),
                  const SizedBox(width: 6),
                  if (scan.fixFailed > 0)
                    _statChip('Gagal', '${scan.fixFailed}',
                        AppStatusColors.danger, Icons.close_rounded),
                  const Spacer(),
                  Text('${scan.fixCompleted}/${scan.fixTotal}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary,
                          fontFamily: 'monospace')),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCsvButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCsvTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.successColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: context.successColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.file_download_outlined,
                  size: 13, color: context.successColor),
              const SizedBox(width: 4),
              Text("CSV",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.successColor,
                      letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context, Color scanColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: scan.isScanning ? scan.cancelScan : scan.startScan,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scanColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scanColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  scan.isScanning ? Icons.stop_rounded : Icons.radar_rounded,
                  size: 13,
                  color: scanColor),
              const SizedBox(width: 5),
              Text(scan.isScanning ? "BATAL" : "SCAN",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scanColor,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock_reset_rounded,
            size: 14, color: context.warningColor.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            scan.isFixing
                ? scan.fixStatus
                : scan.fixStatus.isNotEmpty && !scan.isScanning
                    ? scan.fixStatus
                    : 'Nonaktifkan default-auth dari hasil scan',
            style: TextStyle(
                fontSize: 10,
                color: scan.isFixing
                    ? context.warningColor
                    : context.textSecondary,
                fontWeight:
                    scan.isFixing ? FontWeight.w600 : FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: scan.isScanning
                ? null
                : scan.isFixing
                    ? scan.cancelFix
                    : () {
                        if (scan.scanAuthActive == 0) {
                          onFixNoTargets();
                          return;
                        }
                        scan.startFixDefaultAuth();
                      },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: scan.isScanning
                    ? context.borderColor.withOpacity(0.5)
                    : scan.isFixing
                        ? AppStatusColors.danger.withOpacity(0.12)
                        : context.warningColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scan.isScanning
                      ? context.borderColor
                      : scan.isFixing
                          ? AppStatusColors.danger.withOpacity(0.35)
                          : context.warningColor.withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    scan.isFixing
                        ? Icons.stop_rounded
                        : Icons.auto_fix_high_rounded,
                    size: 12,
                    color: scan.isScanning
                        ? context.textSecondary.withOpacity(0.4)
                        : scan.isFixing
                            ? AppStatusColors.danger
                            : context.warningColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    scan.isFixing ? 'BATAL' : 'FIX DEFAULT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: scan.isScanning
                          ? context.textSecondary.withOpacity(0.4)
                          : scan.isFixing
                              ? AppStatusColors.danger
                              : context.warningColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'monospace')),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.75),
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STORE LIST HEADER
// ══════════════════════════════════════════════════════════════

class WdcpStoreListHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onSearch;

  const WdcpStoreListHeader({
    super.key,
    required this.searchCtrl,
    required this.filteredCount,
    required this.totalCount,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = constraints.maxWidth >= 450;

          final titleWidget = Text("DAFTAR RBWDCP",
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700));

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
                controller: searchCtrl,
                onChanged: (_) => onSearch(),
                style:
                    TextStyle(color: context.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Cari toko...",
                  hintStyle: TextStyle(
                      color: context.textSecondary, fontSize: 12),
                  prefixIcon: Icon(Icons.search,
                      size: 16, color: context.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 10),
                  filled: true,
                  fillColor: context.surfaceColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: context.accentColor, width: 1.5),
                  ),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              size: 14, color: context.textSecondary),
                          onPressed: () {
                            searchCtrl.clear();
                            onSearch();
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                ),
              ),
            ),
          );

          final badgeWidget = SizedBox(
            width: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: context.accentColor.withOpacity(0.25)),
              ),
              child: Text(
                "$filteredCount/$totalCount",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.accentColor,
                    fontFamily: 'monospace'),
              ),
            ),
          );

          if (isWide) {
            return Row(children: [
              titleWidget,
              const Spacer(),
              searchWidget,
              const SizedBox(width: 8),
              badgeWidget,
            ]);
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    children: [titleWidget, const Spacer(), badgeWidget]),
                const SizedBox(height: 10),
                searchWidget,
              ],
            );
          }
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STORE ROW
// ══════════════════════════════════════════════════════════════

class WdcpStoreRow extends StatelessWidget {
  final Map<String, dynamic> store;
  final void Function(String ip, String name, String code) onOpenWdcp;
  final void Function(String ip) onWinbox;
  final void Function(String ip) onPing;
  final void Function(String text) onCopyInfo;
  final void Function(String ip) onCopyIp;

  const WdcpStoreRow({
    super.key,
    required this.store,
    required this.onOpenWdcp,
    required this.onWinbox,
    required this.onPing,
    required this.onCopyInfo,
    required this.onCopyIp,
  });

  @override
  Widget build(BuildContext context) {
    final storeCode = store['store_code'] ?? '-';
    final storeName = store['store_name'] ?? '-';
    final ipWdcp = (store['ip_rb_wdcp'] ?? '-').toString().trim();
    final connType = store['connection_type'] ?? '-';
    final hasIp = ipWdcp.isNotEmpty && ipWdcp != '-';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;

        final infoSection = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: context.accentColor.withOpacity(0.15)),
              ),
              child: Icon(Icons.router_outlined,
                  size: 15, color: context.accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text('$storeCode - $storeName',
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () =>
                            onCopyInfo("$storeCode - $storeName"),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.content_copy_rounded,
                              size: 13,
                              color: context.textSecondary
                                  .withOpacity(0.6)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _connColor(connType).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _connColor(connType).withOpacity(0.3)),
                    ),
                    child: Text(connType,
                        style: TextStyle(
                            color: _connColor(connType),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: hasIp ? () => onCopyIp(ipWdcp) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ipWdcp,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: hasIp
                                    ? context.textPrimary
                                    : context.textSecondary
                                        .withOpacity(0.4),
                                letterSpacing: 0.5)),
                        if (hasIp) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.copy_outlined,
                              size: 10,
                              color: context.textSecondary
                                  .withOpacity(0.4)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final buttons = hasIp
            ? Wrap(spacing: 5, runSpacing: 5, children: [
                MiniActionButton(
                    label: 'OPEN',
                    icon: Icons.settings_remote_outlined,
                    color: context.secondaryAccent,
                    onTap: () =>
                        onOpenWdcp(ipWdcp, storeName, storeCode)),
                MiniActionButton(
                    label: 'WINBOX',
                    color: context.accentColor,
                    onTap: () => onWinbox(ipWdcp)),
                MiniActionButton(
                    label: 'PING',
                    color: context.textSecondary,
                    onTap: () => onPing(ipWdcp),
                    isOutline: true),
              ])
            : const SizedBox.shrink();

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: infoSection),
                    const SizedBox(width: 12),
                    buttons,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoSection,
                    const SizedBox(height: 10),
                    Row(children: [
                      const SizedBox(width: 36),
                      buttons,
                    ]),
                  ],
                ),
        );
      },
    );
  }

  Color _connColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('astinet')) return const Color(0xFF29B6F6);
    if (l.contains('icon')) return const Color(0xFF26C6DA);
    if (l.contains('fiberstar')) return const Color(0xFF66BB6A);
    if (l.contains('orbit')) return const Color(0xFFEF5350);
    if (l.contains('xl') || l.contains('tun')) return const Color(0xFFAB47BC);
    if (l.contains('indosat') || l.contains('isat')) return const Color(0xFFFFCA28);
    if (l.contains('vsat')) return const Color(0xFFFFB74D);
    if (l.contains('gsm')) return const Color(0xFFFF7043);
    return const Color(0xFF7A9CC4);
  }
}

// ══════════════════════════════════════════════════════════════
// LOADING & EMPTY WIDGETS
// ══════════════════════════════════════════════════════════════

class WdcpLoadingWidget extends StatelessWidget {
  final Color color;
  const WdcpLoadingWidget({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  color: color, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 16),
          Text("MEMUAT DATA TOKO...",
              style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class WdcpEmptyWidget extends StatelessWidget {
  final bool hasSearchText;
  const WdcpEmptyWidget({super.key, this.hasSearchText = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 32, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            hasSearchText ? 'Tidak ada yang cocok' : 'Tidak ada data',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
