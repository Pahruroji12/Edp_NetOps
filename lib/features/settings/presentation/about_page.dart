
import 'package:flutter/material.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/utils/responsive_helper.dart';
import 'package:edp_netops/core/widgets/section_header.dart';
import 'package:edp_netops/core/constants/app_constants.dart';
import 'package:edp_netops/core/services/auto_update_service.dart';
import 'package:edp_netops/core/widgets/custom_snackbar.dart';
import 'package:edp_netops/core/widgets/confirm_dialog.dart';
import 'package:edp_netops/core/platform/feature_availability.dart';
import 'package:edp_netops/core/platform/platform_helper.dart';
import 'widgets/about_info_section.dart';
import 'widgets/update_dialog.dart';
import 'package:edp_netops/core/widgets/page_entry_transition.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _isCheckingUpdate = false;
  bool _isDownloadingInline = false;
  double _inlineDownloadProgress = 0.0;
  String _inlineUpdateStatus = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: PageEntryTransition(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.pagePaddingH,
                  0,
                  context.pagePaddingH,
                  40,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: "TENTANG APLIKASI",
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 12),
                    AboutInfoSection(
                      isCheckingUpdate: _isCheckingUpdate,
                      isDownloadingInline: _isDownloadingInline,
                      inlineDownloadProgress: _inlineDownloadProgress,
                      inlineUpdateStatus: _inlineUpdateStatus,
                      onCheckForUpdates: _handleCheckForUpdates,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: context.isDesktop
          ? null
          : const Center(child: AppHamburgerButton()),
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "TENTANG APLIKASI",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),

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

  Future<void> _handleCheckForUpdates() async {
    if (!FeatureAvailability.canUseAutoUpdate) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.system_update_rounded, color: context.accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Pembaruan Mobile',
                style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Untuk memperbarui aplikasi EDP NetOps di Android/iOS, silakan unduh file APK/IPA terbaru dari server distribusi internal perusahaan atau hubungi Administrator EDP.',
            style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Mengerti',
                style: TextStyle(color: context.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_isCheckingUpdate) return;
    
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final update = await AutoUpdateService.checkForUpdates();
      if (!mounted) return;

      if (update == null) {
        CustomSnackBar.success('Aplikasi up-to-date! Versi v${AppConstants.appVersion} adalah yang terbaru.');
      } else {
        // Tampilkan dialog update dengan callback untuk inline progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => UpdateDialog(
            updateInfo: update,
            onStartDownload: () {
              // Tutup dialog dan aktifkan inline progress bar
              Navigator.of(ctx).pop();
              setState(() {
                _isDownloadingInline = true;
                _inlineDownloadProgress = 0.0;
                _inlineUpdateStatus = 'Memulai unduhan...';
              });
              // Mulai unduhan sesungguhnya
              AutoUpdateService.downloadUpdate(
                url: update.downloadUrl,
                fileName: update.fileName,
                onProgress: (progress) {
                  if (mounted) {
                    setState(() {
                      _inlineDownloadProgress = progress;
                      _inlineUpdateStatus = 'Mengunduh v${update.latestVersion}... Jangan tutup aplikasi.';
                    });
                  }
                },
              ).then((savePath) async {
                if (mounted) {
                  setState(() {
                    _isDownloadingInline = false;
                    _inlineUpdateStatus = '';
                  });

                  final message = PlatformHelper.isAndroid
                      ? 'Pembaruan siap dipasang! Silakan ikuti petunjuk sistem untuk memasang versi terbaru.'
                      : 'Pembaruan siap dipasang!\nAplikasi akan ditutup selama beberapa detik untuk menerapkan pembaruan dan akan terbuka kembali secara otomatis.';
                  final shouldInstall = await showConfirmDialog(
                    context,
                    title: 'Pemasangan Pembaruan',
                    message: message,
                    confirmLabel: 'Pasang Sekarang',
                    cancelLabel: 'Nanti',
                    icon: Icons.system_update_rounded,
                  );

                  if (shouldInstall == true) {
                    await AutoUpdateService.installAndExit(savePath);
                  } else {
                    CustomSnackBar.info('Pemasangan ditunda. Anda dapat memperbarui aplikasi kapan saja melalui menu Cek Update.');
                  }
                }
              }).catchError((e) {
                if (mounted) {
                  setState(() {
                    _isDownloadingInline = false;
                    _inlineUpdateStatus = '';
                  });
                  CustomSnackBar.error('Gagal mengunduh pembaruan: $e');
                }
              });
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error('Gagal memeriksa pembaruan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }
}
