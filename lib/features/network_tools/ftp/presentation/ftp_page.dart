import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/globals.dart';
import '../data/ftp_service.dart';
import '../../../../core/utils/notification_mixin.dart';
import 'ftp_controller.dart';
import 'widgets/ftp_status_header.dart';
import 'widgets/ftp_action_column.dart';
import 'widgets/ftp_file_panel.dart';
import 'widgets/ftp_transfer_queue.dart';
import 'widgets/ftp_dialogs.dart';

/// FtpPage — thin UI orchestrator untuk FTP file transfer.
///
/// Arsitektur: Page (layout) → FtpController (logic) → FtpService (transport)
///
/// UI sections sudah dipecah ke presentation/widgets/:
///   - FtpStatusHeader
///   - FtpFilePanel (local + remote)
///   - FtpActionColumn
///   - FtpTransferQueuePanel
///   - FtpDeleteDialog / FtpCancelTransferDialog
///
class FtpPage extends StatefulWidget {
  final String targetIp;
  final String storeCode;
  final String storeName;

  const FtpPage({
    super.key,
    required this.targetIp,
    required this.storeCode,
    required this.storeName,
  });

  @override
  State<FtpPage> createState() => _FtpPageState();
}

class _FtpPageState extends State<FtpPage> {
  late final FtpController _ctrl;
  FtpService get _ftpService => _ctrl.ftpService;

  @override
  void initState() {
    super.initState();
    _ctrl = FtpController(
      targetIp: widget.targetIp,
      storeCode: widget.storeCode,
      storeName: widget.storeName,
    );
    _ctrl.addListener(_onControllerChanged);
    _ftpService.addListener(_onServiceChanged);
    _ctrl.init();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ftpService.removeListener(_onServiceChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.pendingNotification != null) {
      CustomSnackBar.showFromKey(globalMessengerKey, _ctrl.pendingNotification!.message, _ctrl.pendingNotification!.color);
      _ctrl.clearNotification();
    }
  }

  void _onServiceChanged() {
    if (!mounted) return;
    if (_ftpService.pendingNotifMessage != null && _ftpService.pendingNotifLevel != null) {
      final color = NotifMessage(_ftpService.pendingNotifMessage!, _ftpService.pendingNotifLevel!).color;
      CustomSnackBar.showFromKey(globalMessengerKey, _ftpService.pendingNotifMessage!, color);
      _ftpService.clearNotification();
    }
  }

  // ── Delete helpers (require dialog → context) ──────────────────

  Future<void> _deleteLocalFile() async {
    final fileName = _ctrl.selectedLocalFileName;
    if (fileName == null) { _ctrl.deleteLocalFile(); return; }
    final confirmed = await _showDeleteDialog(fileName, isLocal: true);
    if (!confirmed || !mounted) return;
    await _ctrl.deleteLocalFile();
  }

  Future<void> _deleteRemoteFile() async {
    final fileName = _ctrl.validateDeleteRemote();
    if (fileName == null) return;
    final confirmed = await _showDeleteDialog(fileName, isLocal: false);
    if (!confirmed || !mounted) return;
    await _ctrl.executeDeleteRemote();
  }

  Future<bool> _showDeleteDialog(String fileName, {required bool isLocal}) async {
    return await showDialog<bool>(
      context: context, barrierColor: Colors.black54,
      builder: (_) => FtpDeleteDialog(fileName: fileName, isLocal: isLocal),
    ) ?? false;
  }

  Future<void> _confirmCancelJob(TransferJob job) async {
    final confirmed = await showDialog<bool>(
      context: context, barrierColor: Colors.black54,
      builder: (_) => FtpCancelTransferDialog(fileName: job.fileName),
    ) ?? false;
    if (confirmed) _ftpService.cancelJob(job.id);
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(children: [
                FtpStatusHeader(isConnected: _ctrl.isConnected, ip: widget.targetIp),
                const SizedBox(height: 16),
                const SectionHeader(title: "TRANSFER FILE", icon: Icons.swap_horiz_rounded),
                const SizedBox(height: 12),
                _buildTransferPanel(),
                const SizedBox(height: 20),
                const SectionHeader(title: "TRANSFER QUEUE", icon: Icons.queue_rounded),
                const SizedBox(height: 12),
                _buildQueueCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final dotColor = _ctrl.isConnected ? context.successColor : context.dangerColor;
    return SliverAppBar(
      pinned: true, backgroundColor: context.cardColor, elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      title: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: dotColor.withOpacity(0.7), blurRadius: 8)])),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("FTP STB — ${widget.storeCode}", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          Text(widget.storeName, style: TextStyle(color: context.textSecondary, fontSize: 10)),
        ]),
      ]),
      actions: const [],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, context.accentColor.withOpacity(0.3), Colors.transparent])))),
    );
  }

  // ── Transfer Panel (card wrapper + file panels + action column) ──

  Widget _buildTransferPanel() {
    return _buildCard(
      accentLeft: context.accentColor,
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 24, 14),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: context.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(9), border: Border.all(color: context.accentColor.withOpacity(0.2))),
              child: Icon(Icons.compare_arrows_rounded, color: context.accentColor, size: 16)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("File Transfer", style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text("PC  ↔  STB ${widget.targetIp}", style: TextStyle(color: context.textSecondary, fontSize: 12)),
            ])),
          ]),
        ),
        Divider(height: 1, color: context.borderColor),
        // File panels + action column
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _buildFilePanel(isLocal: true)),
            FtpActionColumn(
              onUpload: _ctrl.startUpload,
              onDownload: _ctrl.startDownload,
              onDeleteLocal: _ctrl.isDeletingLocal ? null : _deleteLocalFile,
              onDeleteRemote: _ctrl.isDeletingRemote ? null : _deleteRemoteFile,
              isDeletingLocal: _ctrl.isDeletingLocal,
              isDeletingRemote: _ctrl.isDeletingRemote,
            ),
            Expanded(child: _buildFilePanel(isLocal: false)),
          ]),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _buildFilePanel({required bool isLocal}) {
    return FtpFilePanel(
      isLocal: isLocal,
      isConnected: _ctrl.isConnected,
      isConnecting: _ctrl.isConnecting,
      isLoadingRemote: _ctrl.isLoadingRemote,
      remoteError: _ctrl.remoteError,
      remoteErrorDetail: _ctrl.remoteErrorDetail,
      localPath: _ctrl.localPath,
      remotePath: _ctrl.remotePath,
      targetIp: widget.targetIp,
      localFiles: _ctrl.localFiles,
      remoteFiles: _ctrl.remoteFiles,
      selectedLocalFile: _ctrl.selectedLocalFile,
      selectedRemoteFile: _ctrl.selectedRemoteFile,
      availableDrives: _ctrl.availableDrives,
      currentDrive: _ctrl.currentDrive,
      canNavigateLocalUp: _ctrl.canNavigateLocalUp,
      onLoadLocalDir: _ctrl.loadLocalDirectory,
      onSelectLocalFile: _ctrl.selectLocalFile,
      onNavigateLocalUp: _ctrl.navigateLocalUp,
      onConnectAndLoad: _ctrl.connectAndLoad,
      onNavigateRemoteUp: _ctrl.navigateRemoteUp,
      onNavigateRemoteInto: _ctrl.navigateRemoteInto,
      onSelectRemoteFile: _ctrl.selectRemoteFile,
    );
  }

  Widget _buildQueueCard() {
    return _buildCard(
      accentLeft: context.successColor,
      child: FtpTransferQueuePanel(ftpService: _ftpService, onCancelJob: _confirmCancelJob),
    );
  }

  // ── Card wrapper ──

  Widget _buildCard({required Widget child, Color? accentLeft}) {
    return Stack(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardColor, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: child,
      ),
      if (accentLeft != null)
        Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accentLeft, accentLeft.withOpacity(0.25)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
          ),
        )),
    ]);
  }
}
