import 'package:edp_netops/core/platform/native_io.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/ftp_client.dart';
import '../ftp_controller.dart';

/// FtpFilePanel — panel file browser (lokal atau remote).
class FtpFilePanel extends StatelessWidget {
  final bool isLocal;
  final bool isConnected;
  final bool isConnecting;
  final bool isLoadingRemote;
  final String? remoteError;
  final String remoteErrorDetail;
  final String localPath;
  final String remotePath;
  final String targetIp;
  final List<FileSystemEntity> localFiles;
  final List<FtpEntry> remoteFiles;
  final File? selectedLocalFile;
  final FtpEntry? selectedRemoteFile;
  final List<String> availableDrives;
  final String currentDrive;
  final bool canNavigateLocalUp;

  // Callbacks
  final void Function(String path) onLoadLocalDir;
  final void Function(File file) onSelectLocalFile;
  final VoidCallback onNavigateLocalUp;
  final VoidCallback onConnectAndLoad;
  final VoidCallback onNavigateRemoteUp;
  final void Function(FtpEntry entry) onNavigateRemoteInto;
  final void Function(FtpEntry entry) onSelectRemoteFile;

  const FtpFilePanel({
    super.key,
    required this.isLocal,
    required this.isConnected,
    required this.isConnecting,
    required this.isLoadingRemote,
    this.remoteError,
    this.remoteErrorDetail = '',
    required this.localPath,
    required this.remotePath,
    required this.targetIp,
    required this.localFiles,
    required this.remoteFiles,
    this.selectedLocalFile,
    this.selectedRemoteFile,
    required this.availableDrives,
    required this.currentDrive,
    required this.canNavigateLocalUp,
    required this.onLoadLocalDir,
    required this.onSelectLocalFile,
    required this.onNavigateLocalUp,
    required this.onConnectAndLoad,
    required this.onNavigateRemoteUp,
    required this.onNavigateRemoteInto,
    required this.onSelectRemoteFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        _buildColumnLabels(context),
        SizedBox(height: 260, child: isLocal ? _buildLocalList(context) : _buildRemoteContent(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final labelColor = isLocal ? context.accentColor : (isConnected ? context.warningColor : context.dangerColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.borderColor.withOpacity(0.5)))),
      child: Row(children: [
        Icon(isLocal ? Icons.computer_rounded : Icons.tv_rounded, size: 13, color: labelColor),
        const SizedBox(width: 6),
        Text(isLocal ? "PC" : "STB Remote", style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        if (isLocal && availableDrives.isNotEmpty)
          DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: currentDrive, dropdownColor: context.cardColor,
            icon: Icon(Icons.arrow_drop_down, color: context.accentColor, size: 14),
            style: TextStyle(color: context.accentColor, fontSize: 11, fontWeight: FontWeight.w700),
            isDense: true,
            items: availableDrives.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (d) { if (d != null) onLoadLocalDir(d); },
          )),
        Expanded(child: Text(isLocal ? localPath : remotePath, style: TextStyle(color: context.textSecondary, fontSize: 10, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
        if (!isLocal) ...[
          const SizedBox(width: 6),
          Material(color: Colors.transparent, child: InkWell(
            onTap: isConnecting ? null : onConnectAndLoad,
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: context.accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: context.accentColor.withOpacity(0.25))),
              child: isConnecting
                  ? SizedBox(width: 10, height: 10, child: CircularProgressIndicator(color: context.accentColor, strokeWidth: 1.5))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh_rounded, color: context.accentColor, size: 11),
                      const SizedBox(width: 3),
                      Text("Reconnect", style: TextStyle(color: context.accentColor, fontSize: 9, fontWeight: FontWeight.w700)),
                    ]),
            ),
          )),
        ],
      ]),
    );
  }

  Widget _buildColumnLabels(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: context.surfaceColor.withOpacity(0.5),
      child: Row(children: [
        Expanded(flex: 3, child: Text("Nama File", style: TextStyle(color: context.textSecondary, fontSize: 10))),
        SizedBox(width: 70, child: Text("Ukuran", textAlign: TextAlign.right, style: TextStyle(color: context.textSecondary, fontSize: 10))),
        const SizedBox(width: 8),
        SizedBox(width: 82, child: Text("Tanggal", textAlign: TextAlign.right, style: TextStyle(color: context.textSecondary, fontSize: 10))),
      ]),
    );
  }

  Widget _buildLocalList(BuildContext context) {
    return ListView(padding: EdgeInsets.zero, children: [
      if (canNavigateLocalUp) FtpFileRow(name: "..", size: "", isFolder: true, onTap: onNavigateLocalUp),
      ...localFiles.map((entity) {
        final isDir = entity is Directory;
        final name = entity.path.split(Platform.pathSeparator).last;
        String size = "", date = "";
        if (!isDir) {
          try {
            final f = entity as File;
            size = "${(f.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB";
            final mod = f.lastModifiedSync();
            date = "${mod.day.toString().padLeft(2, '0')} ${FtpController.monthName(mod.month)} ${mod.year}";
          } catch (_) {}
        } else {
          try { final mod = entity.statSync().modified; date = "${mod.day.toString().padLeft(2, '0')} ${FtpController.monthName(mod.month)} ${mod.year}"; } catch (_) {}
        }
        return FtpFileRow(
          name: name, size: size, date: date, isFolder: isDir,
          isSelected: selectedLocalFile?.path == entity.path,
          onTap: () => isDir ? onLoadLocalDir(entity.path) : onSelectLocalFile(entity as File),
        );
      }),
    ]);
  }

  Widget _buildRemoteContent(BuildContext context) {
    if (isConnecting || isLoadingRemote) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: context.accentColor, strokeWidth: 2),
        const SizedBox(height: 10),
        Text(isConnecting ? "Menghubungkan..." : "Memuat...", style: TextStyle(color: context.textSecondary, fontSize: 11)),
      ]));
    }

    // ── No credentials configured ──
    if (remoteError == 'no_credentials') {
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.warningColor.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: context.warningColor.withOpacity(0.25))),
          child: Icon(Icons.settings_outlined, size: 28, color: context.warningColor)),
        const SizedBox(height: 12),
        Text("Credential FTP Belum Diatur", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(remoteErrorDetail, textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 11)),
      ])));
    }

    // ── Auth error (wrong credentials) ──
    if (remoteError == 'auth_error') {
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.dangerColor.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: context.dangerColor.withOpacity(0.25))),
          child: Icon(Icons.key_off_rounded, size: 28, color: context.dangerColor)),
        const SizedBox(height: 12),
        Text("Login FTP Ditolak", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(remoteErrorDetail, textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(targetIp, style: TextStyle(color: context.dangerColor, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ])));
    }

    // ── STB offline / network error ──
    if (!isConnected && remoteError != "dir_error") {
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.dangerColor.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: context.dangerColor.withOpacity(0.25))),
          child: Icon(Icons.cloud_off_outlined, size: 28, color: context.dangerColor)),
        const SizedBox(height: 12),
        Text("STB Tidak Terhubung", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(remoteErrorDetail, textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(targetIp, style: TextStyle(color: context.dangerColor, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ])));
    }

    // ── Directory error (flashdisk) ──
    if (remoteError == "dir_error") {
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.warningColor.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: context.warningColor.withOpacity(0.25))),
          child: Icon(Icons.usb_off_rounded, size: 28, color: context.warningColor)),
        const SizedBox(height: 12),
        Text("Storage Tidak Dapat Diakses", style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text("Flashdisk tidak terpasang atau mengalami kerusakan", textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(remotePath, style: TextStyle(color: context.warningColor, fontSize: 10, fontFamily: 'monospace')),
      ])));
    }
    return ListView(padding: EdgeInsets.zero, children: [
      if (remotePath != "/" && remotePath.isNotEmpty) FtpFileRow(name: "..", size: "", isFolder: true, onTap: onNavigateRemoteUp),
      ...remoteFiles.map((entry) {
        final size = entry.isDirectory ? "" : "${(entry.size / (1024 * 1024)).toStringAsFixed(2)} MB";
        return FtpFileRow(
          name: entry.name, size: size, date: entry.date, isFolder: entry.isDirectory,
          isSelected: selectedRemoteFile?.name == entry.name,
          onTap: () => entry.isDirectory ? onNavigateRemoteInto(entry) : onSelectRemoteFile(entry),
        );
      }),
    ]);
  }
}

/// FtpFileRow — single file/folder row.
class FtpFileRow extends StatelessWidget {
  final String name;
  final String size;
  final String date;
  final bool isFolder;
  final bool isSelected;
  final VoidCallback? onTap;

  const FtpFileRow({super.key, required this.name, required this.size, this.date = '', required this.isFolder, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? context.accentColor.withOpacity(0.08) : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: context.borderColor.withOpacity(0.3)),
              left: BorderSide(color: isSelected ? context.accentColor : Colors.transparent, width: 2),
            ),
          ),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              Icon(name == ".." ? Icons.arrow_upward_rounded : isFolder ? Icons.folder_rounded : Icons.insert_drive_file_rounded, size: 14,
                color: name == ".." ? context.textSecondary : isFolder ? context.warningColor : context.accentColor.withOpacity(0.7)),
              const SizedBox(width: 7),
              Expanded(child: Text(name, style: TextStyle(color: isSelected ? context.accentColor : context.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
            ])),
            SizedBox(width: 70, child: Text(size, textAlign: TextAlign.right, style: TextStyle(color: context.textSecondary, fontSize: 10))),
            const SizedBox(width: 8),
            SizedBox(width: 82, child: Text(date, textAlign: TextAlign.right, style: TextStyle(color: context.textSecondary, fontSize: 9, fontFamily: 'monospace'))),
          ]),
        ),
      ),
    );
  }
}
