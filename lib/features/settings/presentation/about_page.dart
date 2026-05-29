import 'package:flutter/material.dart';
import '../../../layout/main_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/section_header.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // 1. Tambahkan trigger animasi
  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    // Jalankan animasi sesaat setelah halaman dibuka
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _animationsReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      // 2. Hapus _isLoading karena About Page tidak narik data dari internet
      body: AnimatedOpacity(
        opacity: _animationsReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _animationsReady ? Offset.zero : const Offset(0, 0.04),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
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
                      _buildSystemInfoCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          : IconButton(
              icon: Icon(Icons.menu_rounded, color: context.textPrimary),
              onPressed: () =>
                  MainLayout.scaffoldKey.currentState?.openDrawer(),
            ),
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
            "TENTANG APLIKASI", // 3. Judul sudah diganti
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



  // ==========================================
  // INFORMASI SISTEM & CLEAR CACHE
  // ==========================================
  Widget _buildSystemInfoCard() {
    final infoItems = [
      (Icons.apps_rounded, 'Nama Aplikasi', 'EDP NetOps', context.accentColor),
      (
        Icons.tag_rounded,
        'Versi',
        'v2.6 (Enterprise Build)',
        context.accentColor,
      ),
      (Icons.build_circle_outlined, 'Build', '2026.02', context.textSecondary),
      (
        Icons.storage_outlined,
        'Database',
        'Supabase PostgreSQL',
        const Color(0xFF3ECF8E),
      ),
      (
        Icons.devices_outlined,
        'Platform',
        'Flutter (Cross-Platform)',
        const Color(0xFF54C5F8),
      ),
      (
        Icons.palette_outlined,
        'UI Framework',
        'Material Design 3',
        const Color(0xFFFFB347),
      ),
      (Icons.person_outline, 'Developer', 'PAHRUROJI', const Color(0xFFBB86FC)),
      (
        Icons.copyright_outlined,
        'Hak Cipta',
        '© 2026  All Rights Reserved.',
        context.textSecondary,
      ),
    ];

    return Container(
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
      child: Column(
        children: [
          // ── TOP BANNER ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor.withOpacity(0.15),
                  context.secondaryAccent.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lan_outlined,
                    size: 26,
                    color: context.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'EDP',
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: ' NetOps',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Network Operations Center',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    'v2.7',
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── STATUS PILLS ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                _buildStatusPill(
                  Icons.cloud_done_outlined,
                  'Connected',
                  const Color(0xFF00E676),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  Icons.security_outlined,
                  'Encrypted',
                  context.accentColor,
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  Icons.verified_outlined,
                  'Stable',
                  const Color(0xFFFFB347),
                ),
              ],
            ),
          ),

          // ── INFO ROWS ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              children: List.generate(infoItems.length, (i) {
                final item = infoItems[i];
                final icon = item.$1;
                final label = item.$2;
                final value = item.$3;
                final color = item.$4;
                final isLast = i == infoItems.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(icon, size: 15, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              softWrap: true,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: context.borderColor.withOpacity(0.5),
                        indent: 44,
                      ),
                  ],
                );
              }),
            ),
          ),

          // ── FOOTER ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'System Online  ·  © 2026 Developed by Pahruroji',
                  style: TextStyle(
                    color: context.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: status pill
  Widget _buildStatusPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
