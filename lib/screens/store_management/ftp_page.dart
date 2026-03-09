import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../../services/ftp_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/custom_snackbar.dart';

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
  final FtpService _ftpService = FtpService();

  // ── State koneksi ─────────────────────────────────────────────────────────
  bool _isConnected = false;
  bool _isConnecting = false;

  // ── Panel lokal ───────────────────────────────────────────────────────────
  String _localPath = "C:\\";
  List<FileSystemEntity> _localFiles = [];
  File? _selectedLocalFile;
  List<String> _availableDrives = [];

  // ── Panel remote STB ──────────────────────────────────────────────────────
  String _remotePath = "/sdcard/";
  List<FTPEntry> _remoteFiles = [];
  FTPEntry? _selectedRemoteFile;
  bool _isLoadingRemote = false;
  String? _remoteError;

  // ── Operasi aktif ─────────────────────────────────────────────────────────
  bool _isDeletingLocal = false;
  bool _isDeletingRemote = false;

  @override
  void initState() {
    super.initState();
    _scanAvailableDrives();
    _connectAndLoad();
  }

  // ── LOKAL ─────────────────────────────────────────────────────────────────

  void _scanAvailableDrives() {
    final drives = <String>[];
    for (int i = 67; i <= 90; i++) {
      final drive = "${String.fromCharCode(i)}:\\";
      try {
        if (Directory(drive).existsSync()) drives.add(drive);
      } catch (_) {}
    }
    setState(() {
      _availableDrives = drives;
      if (drives.contains("D:\\"))
        _localPath = "D:\\";
      else if (drives.isNotEmpty)
        _localPath = drives.first;
    });
    if (drives.isNotEmpty) _loadLocalDirectory(_localPath);
  }

  void _loadLocalDirectory(String path) {
    try {
      final entities = Directory(path).listSync();
      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      setState(() {
        _localPath = path;
        _localFiles = entities;
        _selectedLocalFile = null;
      });
    } catch (_) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Akses folder ditolak.",
          AppStatusColors.danger,
        );
      }
    }
  }

  Future<void> _deleteLocalFile() async {
    if (_selectedLocalFile == null) {
      CustomSnackBar.show(
        context,
        "Pilih file di panel kiri terlebih dahulu.",
        AppStatusColors.warning,
      );
      return;
    }
    final confirmed = await _showDeleteDialog(
      _selectedLocalFile!.path.split(Platform.pathSeparator).last,
      isLocal: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeletingLocal = true);
    try {
      await _selectedLocalFile!.delete();
      if (mounted) {
        CustomSnackBar.show(
          context,
          "File lokal berhasil dihapus.",
          AppStatusColors.warning,
        );
        _loadLocalDirectory(_localPath);
      }
    } catch (_) {
      if (mounted)
        CustomSnackBar.show(
          context,
          "Gagal menghapus file lokal.",
          AppStatusColors.danger,
        );
    } finally {
      if (mounted) setState(() => _isDeletingLocal = false);
    }
  }

  // ── REMOTE ────────────────────────────────────────────────────────────────

  Future<void> _connectAndLoad() async {
    if (!mounted) return;
    setState(() {
      _isConnecting = true;
      _isConnected = false;
      _remoteError = null;
    });

    final ftp = FTPConnect(
      widget.targetIp,
      user: 'posterm',
      pass: 'dAZAD9yq',
      port: 21,
    );
    bool connected = false;
    try {
      connected = await ftp.connect();
      if (!connected) throw Exception("login_rejected");

      try {
        await ftp.changeDirectory(_remotePath);
      } catch (_) {
        // Folder tidak bisa diakses — kemungkinan flashdisk rusak/tidak terpasang
        throw Exception("dir_error:$_remotePath");
      }

      final entries = await ftp.listDirectoryContent();
      entries.sort((a, b) {
        if (a.type == FTPEntryType.dir && b.type == FTPEntryType.file)
          return -1;
        if (a.type == FTPEntryType.file && b.type == FTPEntryType.dir) return 1;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _remoteError = null;
        _remoteFiles = entries;
        _selectedRemoteFile = null;
      });
    } catch (e) {
      final msg = e.toString();
      String errorCode;
      if (msg.contains("dir_error")) {
        errorCode = "dir_error";
      } else if (msg.contains("login_rejected")) {
        errorCode = "login_rejected";
      } else {
        errorCode = "offline";
      }
      if (mounted)
        setState(() {
          _isConnected = false;
          _remoteError = errorCode;
        });
    } finally {
      if (connected)
        try {
          await ftp.disconnect();
        } catch (_) {}
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _loadRemoteDirectory(String path) async {
    if (!mounted) return;
    setState(() => _isLoadingRemote = true);

    final ftp = FTPConnect(
      widget.targetIp,
      user: 'posterm',
      pass: 'dAZAD9yq',
      port: 21,
    );
    bool connected = false;
    try {
      connected = await ftp.connect();
      if (!connected) throw Exception("login_rejected");

      try {
        await ftp.changeDirectory(path);
      } catch (_) {
        throw Exception("dir_error:$path");
      }

      final entries = await ftp.listDirectoryContent();
      entries.sort((a, b) {
        if (a.type == FTPEntryType.dir && b.type == FTPEntryType.file)
          return -1;
        if (a.type == FTPEntryType.file && b.type == FTPEntryType.dir) return 1;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _remotePath = path;
        _remoteFiles = entries;
        _remoteError = null;
        _selectedRemoteFile = null;
      });
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        if (msg.contains("dir_error")) {
          setState(() => _remoteError = "dir_error");
          CustomSnackBar.show(
            context,
            "Folder tidak dapat diakses. Flashdisk mungkin rusak atau tidak terpasang.",
            AppStatusColors.warning,
          );
        } else {
          CustomSnackBar.show(
            context,
            "Gagal memuat direktori. Pastikan STB ${widget.targetIp} aktif.",
            AppStatusColors.danger,
          );
        }
      }
    } finally {
      if (connected)
        try {
          await ftp.disconnect();
        } catch (_) {}
      if (mounted) setState(() => _isLoadingRemote = false);
    }
  }

  void _startUpload() {
    if (_selectedLocalFile == null) {
      CustomSnackBar.show(
        context,
        "Pilih file di panel kiri terlebih dahulu.",
        AppStatusColors.warning,
      );
      return;
    }
    if (_ftpService.isUploading || _ftpService.isDownloading) {
      CustomSnackBar.show(
        context,
        "Masih ada proses transfer yang berjalan.",
        AppStatusColors.warning,
      );
      return;
    }
    _ftpService
        .sendPromoFile(widget.targetIp, _remotePath, _selectedLocalFile!)
        .then((_) {
          if (mounted) _loadRemoteDirectory(_remotePath);
        });
  }

  void _startDownload() {
    if (_selectedRemoteFile == null) {
      CustomSnackBar.show(
        context,
        "Pilih file di panel kanan terlebih dahulu.",
        AppStatusColors.warning,
      );
      return;
    }
    if (_selectedRemoteFile!.type == FTPEntryType.dir) {
      CustomSnackBar.show(
        context,
        "Tidak dapat mengunduh folder.",
        AppStatusColors.warning,
      );
      return;
    }
    if (_ftpService.isUploading || _ftpService.isDownloading) {
      CustomSnackBar.show(
        context,
        "Masih ada proses transfer yang berjalan.",
        AppStatusColors.warning,
      );
      return;
    }
    _ftpService
        .downloadFile(
          widget.targetIp,
          _remotePath,
          _selectedRemoteFile!.name,
          _localPath,
        )
        .then((_) {
          if (mounted) _loadLocalDirectory(_localPath);
        });
  }

  Future<void> _deleteRemoteFile() async {
    if (_selectedRemoteFile == null) {
      CustomSnackBar.show(
        context,
        "Pilih file di panel kanan terlebih dahulu.",
        AppStatusColors.warning,
      );
      return;
    }
    if (_selectedRemoteFile!.type == FTPEntryType.dir) {
      CustomSnackBar.show(
        context,
        "Tidak dapat menghapus folder.",
        AppStatusColors.warning,
      );
      return;
    }
    final confirmed = await _showDeleteDialog(
      _selectedRemoteFile!.name,
      isLocal: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeletingRemote = true);
    final success = await _ftpService.deleteRemoteFile(
      widget.targetIp,
      _remotePath,
      _selectedRemoteFile!.name,
    );
    if (!mounted) return;
    setState(() => _isDeletingRemote = false);

    if (success) {
      CustomSnackBar.show(
        context,
        "${_selectedRemoteFile!.name} berhasil dihapus dari STB.",
        AppStatusColors.warning,
      );
      _loadRemoteDirectory(_remotePath);
    } else {
      CustomSnackBar.show(
        context,
        "Gagal menghapus file dari STB.",
        AppStatusColors.danger,
      );
    }
  }

  Future<bool> _showDeleteDialog(
    String fileName, {
    required bool isLocal,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.dangerColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: context.dangerColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Hapus File",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLocal
                          ? "Hapus file berikut dari laptop?"
                          : "Hapus file berikut dari STB?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              foregroundColor: context.textSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Batal"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.dangerColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Hapus",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
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
              child: Column(
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    "TRANSFER FILE",
                    Icons.swap_horiz_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTransferPanel(),
                  const SizedBox(height: 20),
                  _buildSectionHeader("TRANSFER QUEUE", Icons.queue_rounded),
                  const SizedBox(height: 12),
                  _buildQueuePanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // APPBAR
  // ══════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isConnected ? context.successColor : context.dangerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_isConnected
                              ? context.successColor
                              : context.dangerColor)
                          .withOpacity(0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "FTP STB — ${widget.storeCode}",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                widget.storeName,
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: const [],

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STATUS HEADER
  // ══════════════════════════════════════════════════════════════

  Widget _buildStatusHeader() {
    final statusColor = _isConnected
        ? context.successColor
        : context.dangerColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = constraints.maxWidth >= 360;

          final iconAndStatus = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Icon(
                  _isConnected ? Icons.tv_rounded : Icons.tv_off_rounded,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STATUS STB",
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _isConnected ? "ONLINE" : "OFFLINE",
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.7),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          final ipBox = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: isWide
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  "IP STB",
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.targetIp,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(children: [iconAndStatus, const Spacer(), ipBox]);
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconAndStatus,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ipBox),
              ],
            );
          }
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ERROR & LOADING VIEW
  // ══════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════
  // SECTION HEADER & CARD WRAPPER
  // ══════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child, Color? accentLeft}) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
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
          child: child,
        ),
        if (accentLeft != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentLeft, accentLeft.withOpacity(0.25)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TRANSFER PANEL
  // ══════════════════════════════════════════════════════════════

  Widget _buildTransferPanel() {
    return _buildCard(
      accentLeft: context.accentColor,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 24, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    color: context.accentColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "File Transfer",
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Laptop  ↔  STB ${widget.targetIp}",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),
          // File panels
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildFilePanel(isLocal: true)),
                _buildActionColumn(),
                Expanded(child: _buildFilePanel(isLocal: false)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionColumn() {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: context.borderColor.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            icon: Icons.upload_rounded,
            label: "Upload",
            color: context.successColor,
            onTap: _startUpload,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.download_rounded,
            label: "Download",
            color: context.accentColor,
            onTap: _startDownload,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.delete_outline_rounded,
            label: "Hapus L",
            color: context.warningColor,
            onTap: _isDeletingLocal ? null : _deleteLocalFile,
            isLoading: _isDeletingLocal,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.delete_forever_rounded,
            label: "Hapus R",
            color: context.dangerColor,
            onTap: _isDeletingRemote ? null : _deleteRemoteFile,
            isLoading: _isDeletingRemote,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
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
              color: disabled
                  ? context.borderColor.withOpacity(0.08)
                  : color.withOpacity(0.08),
              border: Border.all(
                color: disabled
                    ? context.borderColor.withOpacity(0.3)
                    : color.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        icon,
                        color: disabled
                            ? context.textSecondary.withOpacity(0.3)
                            : color,
                        size: 18,
                      ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: disabled
                        ? context.textSecondary.withOpacity(0.3)
                        : color,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePanel({required bool isLocal}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.borderColor.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLocal ? Icons.computer_rounded : Icons.tv_rounded,
                size: 13,
                color: isLocal
                    ? context.accentColor
                    : (_isConnected
                          ? context.warningColor
                          : context.dangerColor),
              ),
              const SizedBox(width: 6),
              Text(
                isLocal ? "Laptop" : "STB Remote",
                style: TextStyle(
                  color: isLocal
                      ? context.accentColor
                      : (_isConnected
                            ? context.warningColor
                            : context.dangerColor),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              if (isLocal && _availableDrives.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _availableDrives.contains(_localPath.substring(0, 3))
                        ? _localPath.substring(0, 3)
                        : _availableDrives.first,
                    dropdownColor: context.cardColor,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: context.accentColor,
                      size: 14,
                    ),
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    isDense: true,
                    items: _availableDrives
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (d) {
                      if (d != null) _loadLocalDirectory(d);
                    },
                  ),
                ),
              Expanded(
                child: Text(
                  isLocal ? _localPath : _remotePath,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              // Tombol Reconnect — hanya di panel kanan
              if (!isLocal) ...[
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isConnecting ? null : _connectAndLoad,
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: context.accentColor.withOpacity(0.25),
                        ),
                      ),
                      child: _isConnecting
                          ? SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                color: context.accentColor,
                                strokeWidth: 1.5,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: context.accentColor,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "Reconnect",
                                  style: TextStyle(
                                    color: context.accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          color: context.surfaceColor.withOpacity(0.5),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "Nama File",
                  style: TextStyle(color: context.textSecondary, fontSize: 10),
                ),
              ),
              Text(
                "Ukuran",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: isLocal ? _buildLocalList() : _buildRemotePanelContent(),
        ),
      ],
    );
  }

  Widget _buildRemotePanelContent() {
    // Loading
    if (_isConnecting || _isLoadingRemote) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: context.accentColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 10),
            Text(
              _isConnecting ? "Menghubungkan..." : "Memuat...",
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
    }

    // Error: STB tidak konek
    if (!_isConnected && _remoteError != "dir_error") {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.dangerColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.dangerColor.withOpacity(0.25),
                  ),
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  size: 28,
                  color: context.dangerColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "STB Tidak Terhubung",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Pastikan STB aktif dan terhubung ke jaringan",
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                widget.targetIp,
                style: TextStyle(
                  color: context.dangerColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error: Direktori tidak bisa diakses (flashdisk rusak/tidak ada)
    if (_remoteError == "dir_error") {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.warningColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.warningColor.withOpacity(0.25),
                  ),
                ),
                child: Icon(
                  Icons.usb_off_rounded,
                  size: 28,
                  color: context.warningColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Storage Tidak Dapat Diakses",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Flashdisk tidak terpasang atau mengalami kerusakan",
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                _remotePath,
                style: TextStyle(
                  color: context.warningColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal: tampilkan list
    return _buildRemoteList();
  }

  Widget _buildLocalList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (Directory(_localPath).parent.path != _localPath)
          _buildFileRow(
            "..",
            "",
            isFolder: true,
            onTap: () => _loadLocalDirectory(Directory(_localPath).parent.path),
          ),
        ..._localFiles.map((entity) {
          final isDir = entity is Directory;
          final name = entity.path.split(Platform.pathSeparator).last;
          String size = "";
          if (!isDir) {
            try {
              size =
                  "${((entity as File).lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB";
            } catch (_) {}
          }
          return _buildFileRow(
            name,
            size,
            isFolder: isDir,
            isSelected: _selectedLocalFile?.path == entity.path,
            onTap: () {
              if (isDir)
                _loadLocalDirectory(entity.path);
              else
                setState(() => _selectedLocalFile = entity as File);
            },
          );
        }),
      ],
    );
  }

  Widget _buildRemoteList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (_remotePath != "/" && _remotePath.isNotEmpty)
          _buildFileRow(
            "..",
            "",
            isFolder: true,
            onTap: () {
              final parts = _remotePath
                  .split('/')
                  .where((p) => p.isNotEmpty)
                  .toList();
              if (parts.isNotEmpty) {
                parts.removeLast();
                _loadRemoteDirectory("/${parts.join('/')}");
              }
            },
          ),
        ..._remoteFiles.map((entry) {
          final isDir = entry.type == FTPEntryType.dir;
          final size = isDir
              ? ""
              : "${((entry.size ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB";
          return _buildFileRow(
            entry.name,
            size,
            isFolder: isDir,
            isSelected: _selectedRemoteFile?.name == entry.name,
            onTap: () {
              if (isDir) {
                final newPath = _remotePath.endsWith('/')
                    ? "$_remotePath${entry.name}"
                    : "$_remotePath/${entry.name}";
                _loadRemoteDirectory(newPath);
              } else {
                setState(() => _selectedRemoteFile = entry);
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildFileRow(
    String name,
    String size, {
    required bool isFolder,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? context.accentColor.withOpacity(0.08)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: context.borderColor.withOpacity(0.3)),
              left: BorderSide(
                color: isSelected ? context.accentColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(
                      name == ".."
                          ? Icons.arrow_upward_rounded
                          : isFolder
                          ? Icons.folder_rounded
                          : Icons.insert_drive_file_rounded,
                      size: 14,
                      color: name == ".."
                          ? context.textSecondary
                          : isFolder
                          ? context.warningColor
                          : context.accentColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                              ? context.accentColor
                              : context.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (size.isNotEmpty)
                Text(
                  size,
                  style: TextStyle(color: context.textSecondary, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // QUEUE PANEL
  // ══════════════════════════════════════════════════════════════

  Widget _buildQueuePanel() {
    return _buildCard(
      accentLeft: context.successColor,
      child: ListenableBuilder(
        listenable: _ftpService,
        builder: (context, _) {
          final isActive = _ftpService.isUploading || _ftpService.isDownloading;
          final isDownload = _ftpService.isDownloading;
          final progress = _ftpService.uploadProgress;
          final status = _ftpService.statusMessage;
          final activeColor = isDownload
              ? context.accentColor
              : context.successColor;

          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isActive ? activeColor : context.textSecondary)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color:
                              (isActive ? activeColor : context.textSecondary)
                                  .withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        isDownload
                            ? Icons.download_rounded
                            : isActive
                            ? Icons.upload_rounded
                            : Icons.inbox_rounded,
                        color: isActive ? activeColor : context.textSecondary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDownload
                                ? "Sedang Download"
                                : isActive
                                ? "Sedang Upload"
                                : "Antrian Transfer",
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.isEmpty
                                ? "Tidak ada proses berjalan"
                                : status,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Text(
                        "${(progress * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: context.borderColor,
                      color: activeColor,
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
