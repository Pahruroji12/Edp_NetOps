import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_snackbar.dart';

/// WdcpControlWidgets — reusable UI components untuk WdcpControlPage.

// ══════════════════════════════════════════════════════════════
// STATUS HEADER
// ══════════════════════════════════════════════════════════════
class WdcpStatusHeader extends StatelessWidget {
  final String ip;
  const WdcpStatusHeader({super.key, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.successColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: context.successColor.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(builder: (_, c) {
        final isWide = c.maxWidth >= 360;
        final iconAndStatus = Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.successColor.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: context.successColor.withOpacity(0.3))),
            child: Icon(Icons.router_outlined, color: context.successColor, size: 26),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("STATUS RBWDCP", style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Row(children: [
              Text("ONLINE", style: TextStyle(color: context.successColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: context.successColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: context.successColor.withOpacity(0.7), blurRadius: 8)])),
            ]),
          ]),
        ]);
        final ipBox = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.borderColor)),
          child: Column(crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            Text("IP RBWDCP", style: TextStyle(color: context.textSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(ip, style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: 1)),
          ]),
        );
        if (isWide) return Row(children: [iconAndStatus, const Spacer(), ipBox]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [iconAndStatus, const SizedBox(height: 12), SizedBox(width: double.infinity, child: ipBox)]);
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECURITY PANEL
// ══════════════════════════════════════════════════════════════
class WdcpSecurityPanel extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  const WdcpSecurityPanel({super.key, required this.isEnabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final statusColor = isEnabled ? context.dangerColor : context.successColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WdcpPanelHeader(title: "DEFAULT AUTHENTICATE", icon: Icons.security_outlined, color: statusColor),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.25))),
            child: Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.6), blurRadius: 6)])),
              const SizedBox(width: 7),
              Text(isEnabled ? "ENABLED" : "DISABLED", style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ]),
          ),
          const Spacer(),
          Transform.scale(scale: 0.85, child: Switch(
            value: isEnabled, onChanged: onToggle,
            activeThumbColor: context.dangerColor, inactiveThumbColor: context.successColor,
            trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? context.dangerColor.withOpacity(0.25) : context.successColor.withOpacity(0.2)),
          )),
        ]),
        const SizedBox(height: 8),
        Text(isEnabled ? "⚠ Semua perangkat dapat terhubung" : "✓ Hanya perangkat whitelist", style: TextStyle(color: context.textSecondary, fontSize: 10)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD MAC PANEL
// ══════════════════════════════════════════════════════════════
class WdcpAddMacPanel extends StatelessWidget {
  final TextEditingController macCtrl;
  final TextEditingController commentCtrl;
  final VoidCallback onAdd;
  const WdcpAddMacPanel({super.key, required this.macCtrl, required this.commentCtrl, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const WdcpPanelHeader(title: "TAMBAH MAC ADDRESS", icon: Icons.add_moderator_outlined, color: Color(0xFF6C63FF)),
        const SizedBox(height: 16),
        WdcpDarkTextField(controller: macCtrl, label: "MAC Address", hint: "AA:BB:CC:DD:EE:FF", icon: Icons.lan_outlined, isMonospace: true),
        const SizedBox(height: 10),
        WdcpDarkTextField(controller: commentCtrl, label: "Comment / Nama Perangkat", hint: "Toko / IC / Keterangan lain", icon: Icons.label_outline),
        const SizedBox(height: 16),
        Material(color: Colors.transparent, child: InkWell(
          onTap: onAdd, borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4A42CC)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text("Tambah Mac Address", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ROUTER INFO PANEL
// ══════════════════════════════════════════════════════════════
class WdcpRouterInfoPanel extends StatelessWidget {
  final Map<String, String> sysInfo;
  final VoidCallback onWinbox;
  const WdcpRouterInfoPanel({super.key, required this.sysInfo, required this.onWinbox});

  @override
  Widget build(BuildContext context) {
    String boardName = sysInfo['board-name'] ?? '-';
    String version = sysInfo['version'] ?? '-';
    String cpuLoad = sysInfo['cpu-load'] ?? '0';
    String freeMem = sysInfo['free-memory'] ?? '0';
    String uptime = sysInfo['uptime'] ?? '-';
    try { freeMem = "${(double.parse(freeMem) / 1024 / 1024).toStringAsFixed(1)} MB"; } catch (_) {}
    final cpuInt = int.tryParse(cpuLoad) ?? 0;
    final cpuColor = cpuInt > 80 ? context.dangerColor : cpuInt > 50 ? const Color(0xFFFFB347) : context.successColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const WdcpPanelHeader(title: "ROUTER INFO", icon: Icons.monitor_heart_outlined, color: Color(0xFF00C9A7)),
        const SizedBox(height: 14),
        Row(children: [
          Text("CPU", style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: cpuInt / 100, backgroundColor: context.surfaceColor, valueColor: AlwaysStoppedAnimation<Color>(cpuColor), minHeight: 6))),
          const SizedBox(width: 8),
          Text("$cpuLoad%", style: TextStyle(color: cpuColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _infoTile(context, "Board", boardName)), Expanded(child: _infoTile(context, "RouterOS", "v$version"))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _infoTile(context, "Free RAM", freeMem)), Expanded(child: _infoTile(context, "Uptime", uptime))]),
        const SizedBox(height: 16),
        Material(color: Colors.transparent, child: InkWell(
          onTap: onWinbox, borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.accentColor.withOpacity(0.3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.window_outlined, color: context.accentColor, size: 16),
              const SizedBox(width: 8),
              Text("Buka Winbox", style: TextStyle(color: context.accentColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Padding(padding: const EdgeInsets.only(right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: context.textSecondary, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════
// LIST ITEM (devices + access list)
// ══════════════════════════════════════════════════════════════
class WdcpListContent extends StatelessWidget {
  final List<Map<String, String>> data;
  final bool isAccessList;
  final IconData emptyIcon;
  final String emptyText;
  final void Function(String id, String mac)? onDelete;

  const WdcpListContent({super.key, required this.data, required this.isAccessList, required this.emptyIcon, required this.emptyText, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: context.surfaceColor, shape: BoxShape.circle, border: Border.all(color: context.borderColor)), child: Icon(emptyIcon, size: 28, color: context.textSecondary)),
        const SizedBox(height: 12),
        Text(emptyText, style: TextStyle(color: context.textSecondary, fontSize: 12)),
      ]));
    }
    final itemAccent = isAccessList ? const Color(0xFFFFB347) : context.successColor;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8), itemCount: data.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.borderColor.withOpacity(0.5), indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = data[index];
        final mac = item['mac-address'] ?? item['mac'] ?? '-';
        final comment = item['comment'] ?? '-';
        final uptime = item['uptime'] ?? '';
        final id = item['.id'];
        return Material(color: Colors.transparent, child: InkWell(
          onTap: () { Clipboard.setData(ClipboardData(text: mac)); CustomSnackBar.show(context, "MAC Address disalin!", context.accentColor); },
          splashColor: context.accentColor.withOpacity(0.05),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: itemAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: itemAccent.withOpacity(0.25))),
              child: Icon(isAccessList ? Icons.vpn_key_outlined : Icons.smartphone_outlined, color: itemAccent, size: 16)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mac, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontFamily: 'monospace', fontSize: 12, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(isAccessList ? (comment != '-' ? comment : "No Comment") : "Uptime: $uptime", style: TextStyle(color: context.textSecondary, fontSize: 10)),
            ])),
            if (!isAccessList && comment != '-' && comment.isNotEmpty)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: context.accentColor.withOpacity(0.2))),
                child: Text(comment, style: TextStyle(fontSize: 9, color: context.accentColor, fontWeight: FontWeight.w700))),
            if (isAccessList && id != null)
              Material(color: Colors.transparent, child: InkWell(
                onTap: () => onDelete?.call(id, mac), borderRadius: BorderRadius.circular(6),
                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: context.dangerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: context.dangerColor.withOpacity(0.2))),
                  child: Icon(Icons.delete_outline, size: 15, color: context.dangerColor)),
              )),
          ])),
        ));
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DELETE MAC DIALOG
// ══════════════════════════════════════════════════════════════
class WdcpDeleteMacDialog extends StatelessWidget {
  final String id;
  final String mac;
  final void Function(String id, String mac) onConfirm;
  const WdcpDeleteMacDialog({super.key, required this.id, required this.mac, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: Material(color: Colors.transparent, child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10))]),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF2A1520), shape: BoxShape.circle, border: Border.all(color: context.dangerColor.withOpacity(0.3))),
          child: Icon(Icons.delete_outline, color: context.dangerColor, size: 26)),
        const SizedBox(height: 14),
        Text("Hapus Akses?", style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text("Hapus MAC Address berikut dari Whitelist?", textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor)),
          child: Text(mac, style: TextStyle(color: context.textPrimary, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(side: BorderSide(color: context.borderColor), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text("Batal", style: TextStyle(color: context.textSecondary)))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); onConfirm(id, mac); },
            style: ElevatedButton.styleFrom(backgroundColor: context.dangerColor, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
        ]),
      ])),
    ))));
  }
}

// ══════════════════════════════════════════════════════════════
// LOADING / ERROR STATES
// ══════════════════════════════════════════════════════════════
class WdcpLoadingState extends StatelessWidget {
  final String ip;
  const WdcpLoadingState({super.key, required this.ip});
  @override
  Widget build(BuildContext context) {
    return Container(color: context.primaryColor, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 44, height: 44, child: CircularProgressIndicator(color: context.accentColor, strokeWidth: 2.5)),
      const SizedBox(height: 16),
      Text("MENGHUBUNGKAN KE RBWDCP...", style: TextStyle(color: context.textSecondary, fontSize: 11, letterSpacing: 2)),
      const SizedBox(height: 6),
      Text(ip, style: TextStyle(color: context.accentColor, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
    ])));
  }
}

class WdcpErrorView extends StatelessWidget {
  final String ip;
  final VoidCallback onRetry;
  const WdcpErrorView({super.key, required this.ip, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle, border: Border.all(color: context.dangerColor.withOpacity(0.3))),
        child: Icon(Icons.cloud_off_outlined, size: 40, color: context.dangerColor)),
      const SizedBox(height: 18),
      Text("Gagal Terhubung", style: TextStyle(color: context.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text("Tidak dapat konek ke Router WDCP\n$ip", textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 12)),
      const SizedBox(height: 24),
      Material(color: Colors.transparent, child: InkWell(onTap: onRetry, borderRadius: BorderRadius.circular(10), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.accentColor.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.refresh_rounded, color: context.accentColor, size: 16),
          const SizedBox(width: 8),
          Text("Coba Lagi", style: TextStyle(color: context.accentColor, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ))),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ══════════════════════════════════════════════════════════════
class WdcpPanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const WdcpPanelHeader({super.key, required this.title, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 7),
      Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
    ]);
  }
}

class WdcpDarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isMonospace;
  const WdcpDarkTextField({super.key, required this.controller, required this.label, this.hint, this.icon, this.isMonospace = false});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      Theme(
        data: Theme.of(context).copyWith(textSelectionTheme: TextSelectionThemeData(cursorColor: context.accentColor, selectionColor: context.accentColor.withOpacity(0.3), selectionHandleColor: context.accentColor)),
        child: TextField(
          controller: controller, cursorColor: context.accentColor,
          style: TextStyle(color: context.textPrimary, fontSize: 12, fontFamily: isMonospace ? 'monospace' : null, letterSpacing: isMonospace ? 0.5 : 0),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.4), fontSize: 12),
            prefixIcon: icon != null ? Icon(icon, size: 15, color: context.textSecondary) : null,
            filled: true, fillColor: context.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: context.accentColor, width: 1.5)),
          ),
        ),
      ),
    ]);
  }
}
