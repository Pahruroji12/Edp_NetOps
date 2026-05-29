import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../../../../core/widgets/network_action_buttons.dart';
import '../../domain/store_model.dart';
import '../controllers/store_detail_controller.dart';
import '../../../../core/utils/connection_type_helper.dart';
import '../../../network_tools/ftp/presentation/ftp_page_loader.dart';
import '../../../network_tools/ftp/data/ftp_service_loader.dart';
import '../../../network_tools/wdcp/presentation/wdcp_control_page_loader.dart';

/// StoreDeviceCard — IP management, stations, CCTV, STB section.
class StoreDeviceCard extends StatelessWidget {
  final StoreDetailController ctrl;
  final StoreModel store;

  const StoreDeviceCard({super.key, required this.ctrl, required this.store});

  bool get _isVsatOnly => ConnectionTypeHelper.isVsatOnly(store.connectionType, store.connectionBackup);
  bool get _isVsatDual => ConnectionTypeHelper.isVsatDual(store.connectionType, store.connectionBackup);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // JARINGAN UTAMA
        _subHeader(context, "JARINGAN UTAMA", Icons.wifi_outlined, context.accentColor),
        _ipRow(context, "IP Gateway", store.ipGateway, isGateway: true, isFirst: true,
          prependButton: (!ctrl.isMobile && _isVsatOnly && store.ipGateway?.isNotEmpty == true)
            ? MiniActionButton(label: "TELNET", color: context.warningColor, onTap: () => ctrl.launchTelnet(store.ipGateway!))
            : null),
        if (store.ipVsat?.isNotEmpty == true && store.ipVsat != '-') ...[
          _divider(context),
          _ipRow(context, "IP VSAT", store.ipVsat, icon: Icons.satellite_alt_outlined,
            customButton: (!ctrl.isMobile && _isVsatDual && store.ipVsat?.isNotEmpty == true)
              ? MiniActionButton(label: "TELNET", color: context.warningColor, onTap: () => ctrl.launchTelnet(store.ipVsat!))
              : null),
        ],
        _divider(context),
        _ipRow(context, "IP RB WDCP", store.ipRbWdcp, icon: Icons.settings_input_antenna_outlined,
          customButton: (ctrl.isAdminOrAbove && (store.ipRbWdcp?.isNotEmpty == true))
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                MiniActionButton(label: "OPEN", icon: Icons.settings_remote_outlined, color: context.secondaryAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WdcpControlPage(ip: store.ipRbWdcp!, storeName: store.storeName, storeCode: store.storeCode)))),
                const SizedBox(width: 4),
                MiniActionButton(label: "WINBOX", color: context.accentColor, onTap: () => ctrl.launchWinboxWdcp(store.ipRbWdcp!)),
              ])
            : null),

        // STATION / KASIR
        _buildStationsSection(context),

        // PERANGKAT LAIN
        _subDivider(context),
        _subHeader(context, "PERANGKAT LAINNYA", Icons.devices_outlined, const Color(0xFFFFB347)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ipRow(context, "IP STB", store.ipStb, icon: Icons.tv_outlined,
            customButton: (!ctrl.isMobile && store.ipStb != null && store.ipStb!.isNotEmpty)
              ? MiniActionButton(label: "FTP", icon: Icons.upload_file, color: context.warningColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FtpPage(targetIp: store.ipStb!, storeCode: store.storeCode, storeName: store.storeName))))
              : null),
          if (!ctrl.isMobile) _buildStbProgress(context),
        ]),
        if (store.ipIkiosk?.isNotEmpty == true && store.ipIkiosk != '-') ...[
          _divider(context),
          _ipRow(context, "IP iKiosk", store.ipIkiosk, icon: Icons.touch_app_outlined),
        ],
        if (store.ipTimbangan?.isNotEmpty == true && store.ipTimbangan != '-') ...[
          _divider(context),
          _ipRow(context, "Timbangan", store.ipTimbangan, icon: Icons.scale_outlined),
        ],

        // CCTV
        _buildCctvSection(context),
      ]),
    );
  }

  Widget _buildStationsSection(BuildContext context) {
    final stations = <(String, String?)>[
      ('Station 1', store.ipStation1), ('Station 2', store.ipStation2),
      ('Station 3', store.ipStation3), ('Station 4', store.ipStation4),
      ('Station 5', store.ipStation5),
    ].where((s) => s.$2 != null && s.$2!.isNotEmpty && s.$2 != '-').toList();
    if (stations.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      _subDivider(context),
      _subHeader(context, "STATION / KASIR", Icons.point_of_sale_outlined, const Color(0xFF00C9A7)),
      for (int i = 0; i < stations.length; i++) ...[
        if (i > 0) _divider(context),
        _ipRow(context, stations[i].$1, stations[i].$2, showVnc: true, icon: Icons.computer_outlined),
      ],
    ]);
  }

  Widget _buildCctvSection(BuildContext context) {
    final cctvs = <(String, String?)>[('CCTV 1', store.ipCctv1), ('CCTV 2', store.ipCctv2)]
        .where((c) => c.$2 != null && c.$2!.isNotEmpty && c.$2 != '-').toList();
    if (cctvs.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      _subDivider(context),
      _subHeader(context, "CCTV / NVR", Icons.videocam_outlined, const Color(0xFFFF6B6B)),
      for (int i = 0; i < cctvs.length; i++) ...[
        if (i > 0) _divider(context),
        _ipRow(context, cctvs[i].$1, cctvs[i].$2, showCctv: true, icon: Icons.videocam_outlined, isLast: i == cctvs.length - 1),
      ],
    ]);
  }

  Widget _buildStbProgress(BuildContext context) {
    return ListenableBuilder(
      listenable: FtpService(),
      builder: (context, child) {
        final ftpService = FtpService();
        final activeJob = ftpService.activeJobs.where((j) => j.isActive && j.targetIp == store.ipStb).firstOrNull;
        if (activeJob != null) {
          return ListenableBuilder(
            listenable: activeJob,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(left: 45.0, right: 16.0, bottom: 12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LinearProgressIndicator(value: activeJob.progress > 0 ? activeJob.progress : null, backgroundColor: context.surfaceColor, color: context.warningColor, minHeight: 2.5),
                const SizedBox(height: 6),
                Text(activeJob.statusText, style: TextStyle(color: context.warningColor, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Shared helpers ──

  Widget _divider(BuildContext context) => Divider(height: 1, color: context.borderColor.withOpacity(0.6), indent: 16, endIndent: 16);
  Widget _subDivider(BuildContext context) => Container(height: 8, decoration: BoxDecoration(color: context.surfaceColor, border: Border.symmetric(horizontal: BorderSide(color: context.borderColor))));

  Widget _subHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        Container(width: 3, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _ipRow(BuildContext context, String label, String? value, {
    bool isGateway = false, bool showVnc = false, bool showCctv = false, bool showPing = true,
    IconData icon = Icons.computer_outlined, Widget? customButton, Widget? prependButton,
    bool isFirst = false, bool isLast = false,
  }) {
    final bool hasValue = value != null && value.isNotEmpty && value != "-";
    final List<Widget> actionButtons = [
      if (!ctrl.isMobile) ...[
        if (hasValue && prependButton != null) prependButton,
        if (hasValue && isGateway && ctrl.isAdminOrAbove && !_isVsatOnly)
          MiniActionButton(label: "WINBOX", color: context.accentColor, onTap: () => ctrl.launchWinbox(value)),
        if (hasValue && showVnc) MiniActionButton(label: "VNC", icon: Icons.desktop_windows_outlined, color: const Color(0xFF00C9A7), onTap: () => ctrl.launchVnc(value)),
        if (hasValue && showCctv) MiniActionButton(label: "VIEW", icon: Icons.videocam_outlined, color: const Color(0xFFFF6B6B), onTap: () => ctrl.launchCctv(value)),
        if (hasValue && customButton != null) customButton,
        if (hasValue && showPing && !isGateway) MiniActionButton(label: "PING", color: context.textSecondary, onTap: () => ctrl.launchPingCmd(value), isOutline: true),
      ],
    ];

    final ipValue = GestureDetector(
      onTap: hasValue ? () { Clipboard.setData(ClipboardData(text: value)); CustomSnackBar.show(context, "$label disalin!", const Color(0xFF00D4FF)); } : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(hasValue ? value : "—", style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13, color: hasValue ? context.textPrimary : context.textSecondary.withOpacity(0.5), letterSpacing: 0.5)),
        if (hasValue) ...[const SizedBox(width: 5), Icon(Icons.copy_outlined, size: 11, color: context.textSecondary.withOpacity(0.5))],
      ]),
    );

    return LayoutBuilder(builder: (_, constraints) {
      final isCompact = constraints.maxWidth < 380 && actionButtons.isNotEmpty;
      if (isCompact) {
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: hasValue ? context.accentColor.withOpacity(0.7) : context.textSecondary, size: 17),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Row(children: [const SizedBox(width: 25), Expanded(child: ipValue), Wrap(spacing: 5, children: actionButtons)]),
        ]));
      }
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children: [
        Icon(icon, color: hasValue ? context.accentColor.withOpacity(0.7) : context.textSecondary, size: 17),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
          const SizedBox(height: 2), ipValue,
        ])),
        if (actionButtons.isNotEmpty) ...[const SizedBox(width: 8), Wrap(spacing: 5, children: actionButtons)],
      ]));
    });
  }
}
