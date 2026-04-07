// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../utils/app_colors.dart';
// import '../../utils/custom_snackbar.dart';
// import '../../utils/activity_logger.dart';
// import '../../services/scan_rbwdcp_service.dart';
// import '../auth/login_page.dart';
// import '../dashboard/dashboard_page.dart';
// import '../profile/profile_page.dart';
// import '../settings/settings_page.dart';
// import '../profile/admin_panel_page.dart';
// import '../store_management/store_list_page.dart';
// import '../store_management/ping_page.dart';
// import '../store_management/ftp_page.dart';

// class OfficeDevicesPage extends StatefulWidget {
//   const OfficeDevicesPage({super.key});

//   @override
//   State<OfficeDevicesPage> createState() => _OfficeDevicesPageState();
// }

// class _OfficeDevicesPageState extends State<OfficeDevicesPage> {
//   // ── Singleton service — scan tetap berjalan saat pindah halaman ──────────
//   final ScanRbwdcpService _scan = ScanRbwdcpService();

//   bool _isLoading = true;
//   List<Map<String, dynamic>> _alarmServers = [];
//   Map<String, dynamic>? _stbOffice;

//   @override
//   void initState() {
//     super.initState();
//     _fetchOfficeDevices();
//     _scan.addListener(_onScanUpdate);
//   }

//   @override
//   void dispose() {
//     // Hanya berhenti mendengarkan — scan di background TETAP berjalan
//     _scan.removeListener(_onScanUpdate);
//     super.dispose();
//   }

//   void _onScanUpdate() {
//     if (mounted) setState(() {});
//   }

//   // ══════════════════════════════════════════════════════════
//   // DATA
//   // ══════════════════════════════════════════════════════════

//   Future<void> _fetchOfficeDevices() async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await Supabase.instance.client
//           .from('office_devices')
//           .select()
//           .order('id', ascending: true);

//       final List<Map<String, dynamic>> alarms = [];
//       Map<String, dynamic>? stb;

//       for (var item in response) {
//         if (item['device_type'] == 'alarm_server') {
//           alarms.add(item);
//         } else if (item['device_type'] == 'stb_office') {
//           stb = item;
//         }
//       }
//       setState(() {
//         _alarmServers = alarms;
//         _stbOffice = stb;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (mounted) {
//         CustomSnackBar.show(
//           context,
//           'Gagal memuat data: $e',
//           AppStatusColors.danger,
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   // ══════════════════════════════════════════════════════════
//   // AKSI TOMBOL
//   // ══════════════════════════════════════════════════════════

//   Future<void> _launchPingCmd(String ip) async {
//     if (!Platform.isWindows) {
//       CustomSnackBar.show(
//         context,
//         'Fitur Ping CMD hanya untuk PC Windows.',
//         AppStatusColors.warning,
//       );
//       return;
//     }
//     try {
//       await Process.start('cmd.exe', [
//         '/c',
//         'start',
//         'cmd.exe',
//         '/k',
//         'ping $ip -t',
//       ], runInShell: true);
//     } catch (e) {
//       CustomSnackBar.show(
//         context,
//         'Gagal menjalankan Ping: $e',
//         AppStatusColors.danger,
//       );
//     }
//   }

//   Future<void> _launchVnc(String ip) async {
//     if (!Platform.isWindows) {
//       CustomSnackBar.show(
//         context,
//         'Fitur VNC hanya untuk PC Windows.',
//         AppStatusColors.warning,
//       );
//       return;
//     }
//     try {
//       await Process.start(r'D:\Edp NetOps\vncviewer.exe', [ip]);
//     } catch (e) {
//       CustomSnackBar.show(
//         context,
//         'Gagal membuka VNC: $e',
//         AppStatusColors.danger,
//       );
//     }
//   }

//   void _launchFtp(String ip, String deviceName) {
//     if (!Platform.isWindows) {
//       CustomSnackBar.show(
//         context,
//         'Fitur FTP hanya untuk PC Windows.',
//         AppStatusColors.warning,
//       );
//       return;
//     }
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             FtpPage(targetIp: ip, storeCode: 'OFFICE', storeName: deviceName),
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // AUTH
//   // ══════════════════════════════════════════════════════════

//   Future<void> _logout(BuildContext ctx) async {
//     try {
//       await ActivityLogger.updateOnlineStatus(false);
//       await ActivityLogger.logAction(
//         actionType: 'LOGOUT',
//         description: 'Pengguna keluar dari sistem',
//       );
//       await Supabase.instance.client.auth.signOut();
//       currentUserNik = '';
//       currentUserName = '';
//       currentUserRole = '';
//       if (ctx.mounted) {
//         Navigator.pushAndRemoveUntil(
//           ctx,
//           MaterialPageRoute(builder: (_) => const LoginPage()),
//           (_) => false,
//         );
//       }
//     } catch (e) {
//       if (ctx.mounted)
//         CustomSnackBar.show(ctx, 'Gagal logout: $e', AppStatusColors.danger);
//     }
//   }

//   void _showLogoutDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: context.cardColor,
//         title: Text('Keluar?', style: TextStyle(color: context.textPrimary)),
//         content: Text(
//           'Yakin ingin keluar dari aplikasi?',
//           style: TextStyle(color: context.textSecondary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Batal',
//               style: TextStyle(color: context.textSecondary),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _logout(context);
//             },
//             child: Text('Keluar', style: TextStyle(color: context.dangerColor)),
//           ),
//         ],
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // BUILD
//   // ══════════════════════════════════════════════════════════

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: context.surfaceColor,
//       drawer: _buildDrawer(),
//       body: CustomScrollView(
//         slivers: [
//           _buildSliverAppBar(),
//           if (_isLoading)
//             const SliverFillRemaining(
//               child: Center(child: CircularProgressIndicator()),
//             )
//           else
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ── Scan RBWDCP ───────────────────────────────────
//                     _buildSectionHeader('SCAN RBWDCP', Icons.radar_rounded),
//                     const SizedBox(height: 12),
//                     _buildScanCard(),
//                     const SizedBox(height: 28),

//                     // ── Device Office ─────────────────────────────────
//                     if (_stbOffice != null || _alarmServers.isNotEmpty) ...[
//                       _buildSectionHeader(
//                         'DEVICE OFFICE',
//                         Icons.devices_rounded,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildDeviceSection(
//                         subHeaderTitle: 'PERANGKAT',
//                         subHeaderIcon: Icons.devices_outlined,
//                         subHeaderColor: context.accentColor,
//                         items: [
//                           if (_stbOffice != null)
//                             _DeviceItem(
//                               label:
//                                   _stbOffice!['device_name']?.toString() ??
//                                   'IP STB',
//                               ip: _stbOffice!['ip_address'],
//                               icon: Icons.tv_outlined,
//                               customButton: _buildMiniButton(
//                                 label: 'FTP',
//                                 icon: Icons.upload_file,
//                                 color: context.warningColor,
//                                 onTap: () => _launchFtp(
//                                   _stbOffice!['ip_address'],
//                                   _stbOffice!['device_name'],
//                                 ),
//                               ),
//                             ),
//                           ..._alarmServers.asMap().entries.map((e) {
//                             final server = e.value;
//                             return _DeviceItem(
//                               label:
//                                   server['device_name']?.toString() ??
//                                   'Server ${e.key + 1}',
//                               ip: server['ip_address'],
//                               icon: Icons.computer_outlined,
//                               showVnc: true,
//                             );
//                           }),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // APPBAR
//   // ══════════════════════════════════════════════════════════

//   Widget _buildSliverAppBar() {
//     return SliverAppBar(
//       pinned: true,
//       backgroundColor: context.cardColor,
//       elevation: 0,
//       iconTheme: IconThemeData(color: context.textPrimary),
//       leading: Builder(
//         builder: (ctx) => IconButton(
//           icon: const Icon(Icons.menu_rounded, size: 22),
//           onPressed: () => Scaffold.of(ctx).openDrawer(),
//         ),
//       ),
//       title: Row(
//         children: [
//           Container(
//             width: 7,
//             height: 7,
//             decoration: BoxDecoration(
//               color: context.accentColor,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: context.accentColor.withOpacity(0.7),
//                   blurRadius: 8,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'OFFICE DEVICES',
//                 style: TextStyle(
//                   color: context.textPrimary,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w800,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//               Text(
//                 'Network Tools & Perangkat Kantor',
//                 style: TextStyle(color: context.textSecondary, fontSize: 10),
//               ),
//             ],
//           ),
//         ],
//       ),
//       // Badge jika scan sedang berjalan
//       actions: [
//         if (_scan.isScanning)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               decoration: BoxDecoration(
//                 color: context.accentColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: context.accentColor.withOpacity(0.3)),
//               ),
//               child: Row(
//                 children: [
//                   SizedBox(
//                     width: 10,
//                     height: 10,
//                     child: CircularProgressIndicator(
//                       color: context.accentColor,
//                       strokeWidth: 1.5,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     '${(_scan.scanProgress * 100).toStringAsFixed(0)}%',
//                     style: TextStyle(
//                       color: context.accentColor,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w800,
//                       fontFamily: 'monospace',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//       ],
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(
//           height: 1,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.transparent,
//                 context.accentColor.withOpacity(0.3),
//                 Colors.transparent,
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // SECTION HEADER
//   // ══════════════════════════════════════════════════════════

//   Widget _buildSectionHeader(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: context.accentColor),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: TextStyle(
//             color: context.textSecondary,
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             letterSpacing: 2,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Container(
//             height: 1,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [context.borderColor, Colors.transparent],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // SCAN CARD — pakai ScanRbwdcpService (background)
//   // ══════════════════════════════════════════════════════════

//   Widget _buildScanCard() {
//     final s = _scan;
//     final isDone = s.scanProgress == 1.0 && !s.isScanning;
//     final color = isDone ? context.successColor : context.accentColor;

//     return Stack(
//       children: [
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: context.cardColor,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: context.borderColor),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 16,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(28, 18, 18, 18),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Baris atas: info + tombol kecil di kanan ───────
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Icon status
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.12),
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: color.withOpacity(0.2)),
//                       ),
//                       child: s.isScanning
//                           ? SizedBox(
//                               width: 17,
//                               height: 17,
//                               child: CircularProgressIndicator(
//                                 color: color,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : Icon(
//                               isDone
//                                   ? Icons.check_circle_outline
//                                   : Icons.radar_rounded,
//                               color: color,
//                               size: 17,
//                             ),
//                     ),
//                     const SizedBox(width: 14),
//                     // Teks judul + status
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             s.isScanning
//                                 ? 'Sedang Scanning...'
//                                 : isDone
//                                 ? 'Scan Selesai'
//                                 : 'Scan Massal RB WDCP',
//                             style: TextStyle(
//                               color: context.textPrimary,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                           const SizedBox(height: 3),
//                           Text(
//                             s.isScanning
//                                 ? s.scanStatus
//                                 : isDone
//                                 ? s.scanStatus
//                                 : 'Audit keamanan Default Auth via Mikrotik API',
//                             style: TextStyle(
//                               color: context.textSecondary,
//                               fontSize: 11,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     // Tombol kecil di kanan
//                     _buildMiniButton(
//                       label: s.isScanning
//                           ? 'Batalkan'
//                           : isDone
//                           ? 'Scan Lagi'
//                           : 'Mulai Scan',
//                       icon: s.isScanning
//                           ? Icons.stop_rounded
//                           : Icons.wifi_find_rounded,
//                       color: s.isScanning
//                           ? context.dangerColor
//                           : context.accentColor,
//                       onTap: s.isScanning
//                           ? () => _scan.cancelScan()
//                           : () => _scan.startScan(),
//                     ),
//                   ],
//                 ),

//                 // ── Progress bar (muncul saat scanning) ────────────
//                 if (s.isScanning || s.scanProgress > 0) ...[
//                   const SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(6),
//                           child: LinearProgressIndicator(
//                             value: s.scanProgress > 0 ? s.scanProgress : null,
//                             backgroundColor: context.borderColor,
//                             color: color,
//                             minHeight: 5,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Text(
//                         '${(s.scanProgress * 100).toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           color: color,
//                           fontWeight: FontWeight.w800,
//                           fontSize: 11,
//                           fontFamily: 'monospace',
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (s.scanCurrentIp.isNotEmpty) ...[
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.router_outlined,
//                           size: 10,
//                           color: context.textSecondary,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           s.scanCurrentIp,
//                           style: TextStyle(
//                             color: context.textSecondary,
//                             fontSize: 10,
//                             fontFamily: 'monospace',
//                           ),
//                         ),
//                         const Spacer(),
//                         Text(
//                           '${s.scanCompleted}/${s.scanTotal}',
//                           style: TextStyle(
//                             color: context.textSecondary,
//                             fontSize: 10,
//                             fontFamily: 'monospace',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],

//                 // ── Stats (muncul setelah ada hasil) ───────────────
//                 if (s.scanCompleted > 0) ...[
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: context.surfaceColor,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: context.borderColor),
//                     ),
//                     child: Row(
//                       children: [
//                         _statChip(
//                           '${s.scanSuccess}',
//                           'Berhasil',
//                           context.successColor,
//                           Icons.check_circle_outline,
//                         ),
//                         _statChip(
//                           '${s.scanOffline}',
//                           'Offline',
//                           context.textSecondary,
//                           Icons.wifi_off_outlined,
//                         ),
//                         _statChip(
//                           '${s.scanAuthActive}',
//                           'Auth ON',
//                           s.scanAuthActive > 0
//                               ? context.dangerColor
//                               : context.successColor,
//                           s.scanAuthActive > 0
//                               ? Icons.warning_amber_outlined
//                               : Icons.verified_outlined,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],

//                 // ── Path file CSV ──────────────────────────────────
//                 if (s.scanFilePath != null && !s.isScanning) ...[
//                   const SizedBox(height: 10),
//                   GestureDetector(
//                     onTap: () {
//                       Clipboard.setData(ClipboardData(text: s.scanFilePath!));
//                       CustomSnackBar.show(
//                         context,
//                         'Path disalin!',
//                         context.accentColor,
//                       );
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: context.successColor.withOpacity(0.06),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: context.successColor.withOpacity(0.2),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.save_alt_outlined,
//                             size: 12,
//                             color: context.successColor,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               s.scanFilePath!,
//                               style: TextStyle(
//                                 color: context.successColor,
//                                 fontSize: 10,
//                                 fontFamily: 'monospace',
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Icon(
//                             Icons.copy_outlined,
//                             size: 11,
//                             color: context.successColor,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],

//                 // ── Tabel hasil ────────────────────────────────────
//                 if (s.scanResults.isNotEmpty) ...[
//                   const SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.list_alt_outlined,
//                         size: 12,
//                         color: context.textSecondary,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         'HASIL (${s.scanResults.length} router)',
//                         style: TextStyle(
//                           color: context.textSecondary,
//                           fontSize: 10,
//                           fontWeight: FontWeight.w700,
//                           letterSpacing: 1.5,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Container(
//                           height: 1,
//                           color: context.borderColor.withOpacity(0.5),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   // Header tabel
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: context.surfaceColor,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Row(
//                       children: [
//                         _th('No', 26),
//                         _th('Toko', 68),
//                         _th('IP', 100),
//                         _th('Wlan', 50),
//                         _th('Auth', 46, right: true),
//                         Expanded(
//                           child: Text(
//                             'Ket.',
//                             style: TextStyle(
//                               color: context.textSecondary,
//                               fontSize: 10,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   ConstrainedBox(
//                     constraints: const BoxConstraints(maxHeight: 280),
//                     child: ListView.builder(
//                       padding: EdgeInsets.zero,
//                       shrinkWrap: true,
//                       itemCount: s.scanResults.length,
//                       itemBuilder: (_, i) => _buildResultRow(s.scanResults[i]),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//         // Accent bar kiri
//         Positioned(
//           left: 0,
//           top: 0,
//           bottom: 0,
//           child: Container(
//             width: 4,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [color, color.withOpacity(0.2)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 bottomLeft: Radius.circular(20),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _statChip(String value, String label, Color color, IconData icon) {
//     return Expanded(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(7),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               shape: BoxShape.circle,
//               border: Border.all(color: color.withOpacity(0.2)),
//             ),
//             child: Icon(icon, size: 13, color: color),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: color,
//               fontSize: 17,
//               fontWeight: FontWeight.w900,
//               fontFamily: 'monospace',
//             ),
//           ),
//           Text(
//             label,
//             style: TextStyle(
//               color: context.textSecondary,
//               fontSize: 9,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _th(String text, double width, {bool right = false}) {
//     return SizedBox(
//       width: width,
//       child: Text(
//         text,
//         textAlign: right ? TextAlign.right : TextAlign.left,
//         style: TextStyle(
//           color: context.textSecondary,
//           fontSize: 10,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }

//   Widget _buildResultRow(ScanResultModel r) {
//     if (r.wlanResults.isEmpty) {
//       final isVsat = r.connectionType.toUpperCase().contains('VSAT');
//       final rowColor = isVsat ? context.warningColor : context.textSecondary;
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(color: context.borderColor.withOpacity(0.3)),
//           ),
//         ),
//         child: Row(
//           children: [
//             SizedBox(
//               width: 26,
//               child: Text(
//                 '${r.no}',
//                 style: TextStyle(
//                   color: context.textSecondary,
//                   fontSize: 10,
//                   fontFamily: 'monospace',
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 68,
//               child: Text(
//                 r.storeCode,
//                 style: TextStyle(
//                   color: context.textPrimary,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 100,
//               child: Text(
//                 r.ip,
//                 style: TextStyle(
//                   color: context.textSecondary,
//                   fontSize: 9,
//                   fontFamily: 'monospace',
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 50,
//               child: Text(
//                 '-',
//                 style: TextStyle(color: context.textSecondary, fontSize: 10),
//               ),
//             ),
//             SizedBox(
//               width: 46,
//               child: Text(
//                 '-',
//                 style: TextStyle(color: context.textSecondary, fontSize: 10),
//               ),
//             ),
//             Expanded(
//               child: Row(
//                 children: [
//                   Icon(
//                     isVsat
//                         ? Icons.satellite_alt_outlined
//                         : Icons.wifi_off_outlined,
//                     size: 10,
//                     color: rowColor,
//                   ),
//                   const SizedBox(width: 3),
//                   Expanded(
//                     child: Text(
//                       r.errorMsg.isNotEmpty ? r.errorMsg : 'Tidak terjangkau',
//                       style: TextStyle(color: rowColor, fontSize: 9),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//     return Column(
//       children: r.wlanResults.asMap().entries.map((e) {
//         final i = e.key;
//         final w = e.value;
//         final authOn = w.defaultAuth;
//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//           decoration: BoxDecoration(
//             color: authOn ? context.dangerColor.withOpacity(0.05) : null,
//             border: Border(
//               bottom: BorderSide(color: context.borderColor.withOpacity(0.3)),
//               left: authOn
//                   ? BorderSide(color: context.dangerColor, width: 2)
//                   : BorderSide.none,
//             ),
//           ),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 26,
//                 child: Text(
//                   i == 0 ? '${r.no}' : '',
//                   style: TextStyle(
//                     color: context.textSecondary,
//                     fontSize: 10,
//                     fontFamily: 'monospace',
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 68,
//                 child: i == 0
//                     ? Text(
//                         r.storeCode,
//                         style: TextStyle(
//                           color: context.textPrimary,
//                           fontSize: 10,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       )
//                     : const SizedBox(),
//               ),
//               SizedBox(
//                 width: 100,
//                 child: i == 0
//                     ? Text(
//                         r.ip,
//                         style: TextStyle(
//                           color: context.textSecondary,
//                           fontSize: 9,
//                           fontFamily: 'monospace',
//                         ),
//                       )
//                     : const SizedBox(),
//               ),
//               SizedBox(
//                 width: 50,
//                 child: Text(
//                   w.name.toUpperCase(),
//                   style: TextStyle(
//                     color: context.accentColor,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                     fontFamily: 'monospace',
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 46,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Container(
//                       width: 6,
//                       height: 6,
//                       decoration: BoxDecoration(
//                         color: authOn
//                             ? context.dangerColor
//                             : context.successColor,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color:
//                                 (authOn
//                                         ? context.dangerColor
//                                         : context.successColor)
//                                     .withOpacity(0.6),
//                             blurRadius: 4,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 3),
//                     Text(
//                       authOn ? 'true' : 'false',
//                       style: TextStyle(
//                         color: authOn
//                             ? context.dangerColor
//                             : context.successColor,
//                         fontSize: 9,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   authOn ? '⚠ AKTIF' : 'Aman',
//                   style: TextStyle(
//                     color: authOn ? context.dangerColor : context.successColor,
//                     fontSize: 9,
//                     fontWeight: authOn ? FontWeight.w700 : FontWeight.w400,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // DRAWER — identik dashboard_page
//   // ══════════════════════════════════════════════════════════

//   Widget _buildDrawer() {
//     Color roleAccentD;
//     IconData roleIconD;
//     switch (currentUserRole.toLowerCase()) {
//       case 'administrator':
//         roleAccentD = const Color(0xFFFF6B6B);
//         roleIconD = Icons.admin_panel_settings_outlined;
//         break;
//       case 'admin':
//         roleAccentD = const Color(0xFFFFB347);
//         roleIconD = Icons.manage_accounts_outlined;
//         break;
//       default:
//         roleAccentD = context.accentColor;
//         roleIconD = Icons.person_outline;
//     }
//     final nameParts = currentUserName.trim().split(' ');
//     final initialsD = nameParts.length >= 2
//         ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
//         : currentUserName.isNotEmpty
//         ? currentUserName[0].toUpperCase()
//         : 'U';

//     return Drawer(
//       backgroundColor: context.surfaceColor,
//       child: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [roleAccentD.withOpacity(0.13), context.cardColor],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               border: Border(bottom: BorderSide(color: context.borderColor)),
//             ),
//             child: SafeArea(
//               bottom: false,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Stack(
//                           clipBehavior: Clip.none,
//                           children: [
//                             Container(
//                               width: 60,
//                               height: 60,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [
//                                     roleAccentD,
//                                     roleAccentD.withOpacity(0.55),
//                                   ],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                                 borderRadius: BorderRadius.circular(18),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: roleAccentD.withOpacity(0.35),
//                                     blurRadius: 14,
//                                     offset: const Offset(0, 5),
//                                   ),
//                                 ],
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   initialsD,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 22,
//                                     fontWeight: FontWeight.w900,
//                                     letterSpacing: 1,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               right: -5,
//                               bottom: -5,
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: BoxDecoration(
//                                   color: context.surfaceColor,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: roleAccentD.withOpacity(0.5),
//                                     width: 1.5,
//                                   ),
//                                 ),
//                                 child: Icon(
//                                   roleIconD,
//                                   size: 12,
//                                   color: roleAccentD,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const Spacer(),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 9,
//                             vertical: 5,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF00E676).withOpacity(0.08),
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(
//                               color: const Color(0xFF00E676).withOpacity(0.3),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 6,
//                                 height: 6,
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFF00E676),
//                                   shape: BoxShape.circle,
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: const Color(
//                                         0xFF00E676,
//                                       ).withOpacity(0.7),
//                                       blurRadius: 5,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 5),
//                               const Text(
//                                 'Online',
//                                 style: TextStyle(
//                                   color: Color(0xFF00E676),
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       currentUserName.isNotEmpty ? currentUserName : 'User',
//                       style: TextStyle(
//                         color: context.textPrimary,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w800,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.badge_outlined,
//                           size: 12,
//                           color: context.textSecondary.withOpacity(0.6),
//                         ),
//                         const SizedBox(width: 5),
//                         Text(
//                           currentUserNik,
//                           style: TextStyle(
//                             color: context.textSecondary,
//                             fontSize: 12,
//                             fontFamily: 'monospace',
//                             letterSpacing: 0.8,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: roleAccentD.withOpacity(0.12),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: roleAccentD.withOpacity(0.35),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(roleIconD, size: 11, color: roleAccentD),
//                           const SizedBox(width: 6),
//                           Text(
//                             currentUserRole.toUpperCase(),
//                             style: TextStyle(
//                               color: roleAccentD,
//                               fontSize: 10,
//                               fontWeight: FontWeight.w800,
//                               letterSpacing: 1.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildDrawerTile(
//             icon: Icons.dashboard_outlined,
//             label: 'Dashboard',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const DashboardPage()),
//               );
//             },
//           ),
//           _buildDrawerTile(
//             icon: Icons.store_outlined,
//             label: 'Data Toko',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const StoreListPage()),
//               );
//             },
//           ),
//           if (Platform.isWindows)
//             _buildDrawerTile(
//               icon: Icons.network_check,
//               label: 'Ping Scanner',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const PingPage()),
//                 );
//               },
//             ),
//           // Active tile
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
//             decoration: BoxDecoration(
//               color: context.accentColor.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: context.accentColor.withOpacity(0.2)),
//             ),
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 2,
//               ),
//               leading: Icon(
//                 Icons.monitor_outlined,
//                 color: context.accentColor,
//                 size: 20,
//               ),
//               title: Text(
//                 'Device Office',
//                 style: TextStyle(
//                   color: context.accentColor,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 13,
//                 ),
//               ),
//               onTap: () => Navigator.pop(context),
//             ),
//           ),
//           _buildDrawerTile(
//             icon: Icons.person_outline,
//             label: 'Profil Saya',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ProfilePage()),
//               );
//             },
//           ),
//           if (currentUserRole.toLowerCase() == 'administrator') ...[
//             _buildDrawerTile(
//               icon: Icons.settings_outlined,
//               label: 'Setting',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const SettingsPage()),
//                 );
//               },
//             ),
//             _buildDrawerTile(
//               icon: Icons.admin_panel_settings_outlined,
//               label: 'Control Center',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const AdminPanelPage()),
//                 );
//               },
//             ),
//           ],
//           const Spacer(),
//           Container(
//             height: 1,
//             margin: const EdgeInsets.symmetric(horizontal: 12),
//             color: context.borderColor,
//           ),
//           const SizedBox(height: 8),
//           _buildDrawerTile(
//             icon: Icons.logout_outlined,
//             label: 'Keluar Aplikasi',
//             iconColor: const Color(0xFFFF6B6B),
//             labelColor: const Color(0xFFFF6B6B),
//             onTap: () {
//               Navigator.pop(context);
//               _showLogoutDialog();
//             },
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerTile({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     Color? iconColor,
//     Color? labelColor,
//   }) {
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
//       leading: Icon(icon, color: iconColor ?? context.textSecondary, size: 20),
//       title: Text(
//         label,
//         style: TextStyle(
//           color: labelColor ?? context.textPrimary,
//           fontSize: 13,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // DEVICE SECTION WIDGETS
//   // ══════════════════════════════════════════════════════════

//   Widget _buildDeviceSection({
//     required String subHeaderTitle,
//     required IconData subHeaderIcon,
//     required Color subHeaderColor,
//     required List<_DeviceItem> items,
//   }) {
//     return Stack(
//       children: [
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: context.cardColor,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: context.borderColor),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 16,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSubHeader(subHeaderTitle, subHeaderIcon, subHeaderColor),
//               for (int i = 0; i < items.length; i++) ...[
//                 if (i > 0) _buildDivider(),
//                 _buildIpRow(
//                   context,
//                   items[i].label,
//                   items[i].ip,
//                   icon: items[i].icon,
//                   showVnc: items[i].showVnc,
//                   showPing: items[i].showPing,
//                   customButton: items[i].customButton,
//                 ),
//               ],
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//         Positioned(
//           left: 0,
//           top: 0,
//           bottom: 0,
//           child: Container(
//             width: 4,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [subHeaderColor, subHeaderColor.withOpacity(0.2)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 bottomLeft: Radius.circular(20),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSubHeader(String title, IconData icon, Color color) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
//       child: Row(
//         children: [
//           Container(
//             width: 3,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Icon(icon, size: 13, color: color),
//           const SizedBox(width: 6),
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontSize: 10,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider() {
//     return Divider(
//       height: 1,
//       color: context.borderColor.withOpacity(0.6),
//       indent: 16,
//       endIndent: 16,
//     );
//   }

//   Widget _buildIpRow(
//     BuildContext context,
//     String label,
//     String? value, {
//     bool showVnc = false,
//     bool showPing = true,
//     IconData icon = Icons.computer_outlined,
//     Widget? customButton,
//     bool isFirst = false,
//     bool isLast = false,
//   }) {
//     final bool hasValue = value != null && value.isNotEmpty && value != '-';
//     final List<Widget> actionButtons = [
//       if (hasValue && showVnc)
//         _buildMiniButton(
//           label: 'VNC',
//           icon: Icons.desktop_windows_outlined,
//           color: const Color(0xFF00C9A7),
//           onTap: () => _launchVnc(value),
//         ),
//       if (hasValue && customButton != null) customButton,
//       if (hasValue && showPing)
//         _buildMiniButton(
//           label: 'PING',
//           color: context.textSecondary,
//           onTap: () => _launchPingCmd(value),
//           isOutline: true,
//         ),
//     ];

//     final ipValue = GestureDetector(
//       onTap: hasValue
//           ? () {
//               Clipboard.setData(ClipboardData(text: value));
//               CustomSnackBar.show(
//                 context,
//                 '$label disalin!',
//                 const Color(0xFF00D4FF),
//               );
//             }
//           : null,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             hasValue ? value : '—',
//             style: TextStyle(
//               fontFamily: 'monospace',
//               fontWeight: FontWeight.w700,
//               fontSize: 13,
//               color: hasValue
//                   ? context.textPrimary
//                   : context.textSecondary.withOpacity(0.5),
//               letterSpacing: 0.5,
//             ),
//           ),
//           if (hasValue) ...[
//             const SizedBox(width: 5),
//             Icon(
//               Icons.copy_outlined,
//               size: 11,
//               color: context.textSecondary.withOpacity(0.5),
//             ),
//           ],
//         ],
//       ),
//     );

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: hasValue
//                 ? context.accentColor.withOpacity(0.7)
//                 : context.textSecondary,
//             size: 17,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(color: context.textSecondary, fontSize: 11),
//                 ),
//                 const SizedBox(height: 2),
//                 ipValue,
//               ],
//             ),
//           ),
//           if (actionButtons.isNotEmpty) ...[
//             const SizedBox(width: 8),
//             Wrap(spacing: 5, children: actionButtons),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildMiniButton({
//     required String label,
//     required VoidCallback onTap,
//     required Color color,
//     IconData? icon,
//     bool isOutline = false,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(6),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
//           decoration: BoxDecoration(
//             color: isOutline ? Colors.transparent : color.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(6),
//             border: Border.all(
//               color: color.withOpacity(isOutline ? 0.3 : 0.25),
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (icon != null) ...[
//                 Icon(icon, size: 10, color: color),
//                 const SizedBox(width: 3),
//               ],
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: color,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Helper class ──────────────────────────────────────────────────────────────

// class _DeviceItem {
//   final String label;
//   final String? ip;
//   final IconData icon;
//   final bool showVnc;
//   final bool showPing;
//   final Widget? customButton;

//   const _DeviceItem({
//     required this.label,
//     required this.ip,
//     this.icon = Icons.computer_outlined,
//     this.showVnc = false,
//     this.showPing = true,
//     this.customButton,
//   });
// }
