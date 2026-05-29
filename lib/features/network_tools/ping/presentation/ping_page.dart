import '../../../../core/platform/feature_availability.dart';
import 'package:flutter/material.dart';
import '../../../../layout/main_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/globals.dart';
import 'ping_controller.dart';

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage>
    with SingleTickerProviderStateMixin {
  bool _animationsReady = false;
  final _engine = PingController.instance;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
      if (!_engine.isAutoPingSTBActive) {
        _engine.toggleAutoPing(true);
      }
    });
  }

  @override
  void dispose() {
    _engine.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// Listener untuk menampilkan notifikasi dari controller.
  void _onControllerChanged() {
    if (!mounted) return;

    // Ambil notifikasi SEBELUM setState agar tidak hilang di rebuild berikutnya.
    final notification = _engine.pendingNotification;
    if (notification != null) {
      _engine.clearNotification();
    }

    setState(() {});

    // Tampilkan snackbar setelah frame selesai rebuild —
    // mencegah race condition dengan AnimatedBuilder yang juga listen ke engine.
    if (notification != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CustomSnackBar.showFromKey(
          globalMessengerKey,
          notification.message,
          notification.color,
        );
      });
    }
  }

  // ══════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════
  // BUILD UTAMA
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Hanya Windows
    if (!FeatureAvailability.canUsePing) {
      return Scaffold(
        backgroundColor: context.primaryColor,
        appBar: AppBar(
          backgroundColor: context.primaryColor,
          title: Text(
            "Ping Scanner",
            style: TextStyle(color: context.textPrimary),
          ),
          automaticallyImplyLeading: false,
          leading: context.isDesktop
              ? null
              : IconButton(
                  icon: Icon(Icons.menu_rounded, color: context.textPrimary),
                  onPressed: () =>
                      MainLayout.scaffoldKey.currentState?.openDrawer(),
                ),
          iconTheme: IconThemeData(color: context.textPrimary),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.desktop_access_disabled_outlined,
                size: 48,
                color: context.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                "Eksklusif Desktop (Windows)",
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final engine = _engine;

    return Scaffold(
      backgroundColor: context.primaryColor,

      body: AnimatedOpacity(
        opacity: _animationsReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _animationsReady ? Offset.zero : const Offset(0, 0.03),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: engine,
            builder: (context, _) {
              return CustomScrollView(
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

                          // ── Scheduler ───────────────────────────
                          const SectionHeader(
                            title: "SCHEDULER OTOMATIS",
                            icon: Icons.schedule_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildSchedulerCard(engine),
                          const SizedBox(height: 24),

                          // ── Status Progress ──────────────────────
                          if (engine.isScanning || engine.progressValue == 1.0)
                            _buildProgressCard(engine),

                          if (engine.isScanning || engine.progressValue == 1.0)
                            const SizedBox(height: 20),

                          // ── Target IP ──────────────────────────
                          const SectionHeader(
                            title: "TARGET IP",
                            icon: Icons.my_location_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildTargetCard(engine),
                          const SizedBox(height: 24),

                          // ── Input Manual IP ──────────────────────
                          const SectionHeader(
                            title: "INPUT MANUAL (OPSIONAL)",
                            icon: Icons.edit_note_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildManualInputCard(engine),
                          const SizedBox(height: 24),

                          const SizedBox(height: 8),

                          // ── Tombol Start ─────────────────────────
                          _buildStartButton(engine),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SLIVER APP BAR (identik dengan settings_page)
  // ══════════════════════════════════════════════════════════

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PING SCANNER",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "Ping Scanner — Network Tools",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
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

  // ══════════════════════════════════════════════════════════
  // SECTION HEADER (identik settings_page)
  // ══════════════════════════════════════════════════════════



  // ══════════════════════════════════════════════════════════
  // CARD BASE (identik settings_page)
  // ══════════════════════════════════════════════════════════

  Widget _buildCard({required Widget child, Color? accentLeft}) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: accentLeft != null ? 28 : 24,
            right: 24,
            top: 24,
            bottom: 24,
          ),
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

  Widget _buildCardHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // PROGRESS CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildProgressCard(PingController engine) {
    final isScanning = engine.isScanning;
    final isDone = engine.progressValue == 1.0 && !isScanning;
    final color = isDone ? context.successColor : context.accentColor;

    return _buildCard(
      accentLeft: color,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: isScanning
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.check_circle_outline, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isScanning ? "Sedang Memindai..." : "Pemindaian Selesai",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      engine.statusText,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress persen
              Text(
                "${(engine.progressValue * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: engine.progressValue,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          // ── Stat chips OK / NOK ──
          if (engine.okCount > 0 || engine.nokCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  label: 'OK',
                  value: '${engine.okCount}',
                  color: context.successColor,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  label: 'NOK',
                  value: '${engine.nokCount}',
                  color: context.dangerColor,
                  icon: Icons.cancel_outlined,
                ),
                const Spacer(),
                Text(
                  '${engine.okCount + engine.nokCount} / ${engine.totalTarget}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TARGET IP CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildTargetCard(PingController engine) {
    final targets = [
      {
        'key': 'GW',
        'label': 'IP Gateway',
        'icon': Icons.router_outlined,
        'value': engine.config.gateway,
      },
      {
        'key': 'S1',
        'label': 'IP Station 1',
        'icon': Icons.computer_outlined,
        'value': engine.config.station1,
      },
      {
        'key': 'STB',
        'label': 'IP STB',
        'icon': Icons.tv_outlined,
        'value': engine.config.stb,
      },
      {
        'key': 'RB',
        'label': 'IP RB WDCP',
        'icon': Icons.settings_input_antenna_outlined,
        'value': engine.config.rbWdcp,
      },
      {
        'key': 'C1',
        'label': 'IP CCTV 1',
        'icon': Icons.videocam_outlined,
        'value': engine.config.cctv1,
      },
      {
        'key': 'C2',
        'label': 'IP CCTV 2',
        'icon': Icons.videocam_outlined,
        'value': engine.config.cctv2,
      },
    ];

    return _buildCard(
      accentLeft: context.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Pilih Target IP",
            "Pilih jenis IP yang akan di-ping",
            Icons.my_location_outlined,
            context.accentColor,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final cols = constraints.maxWidth >= 480 ? 3 : 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: targets.map((t) {
                    final checked = t['value'] as bool;
                    final key = t['key'] as String;
                    final label = t['label'] as String;
                    final icon = t['icon'] as IconData;
                    final color = checked
                        ? context.accentColor
                        : context.textSecondary.withOpacity(0.4);

                    return SizedBox(
                      width: (constraints.maxWidth - (cols - 1) * 8) / cols,
                      child: GestureDetector(
                        onTap: engine.isScanning
                            ? null
                            : () => engine.setCheckbox(key, !checked),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: checked
                                ? context.accentColor.withOpacity(0.08)
                                : context.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: checked
                                  ? context.accentColor.withOpacity(0.35)
                                  : context.borderColor,
                              width: checked ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: checked
                                        ? context.textPrimary
                                        : context.textSecondary,
                                    fontSize: 12,
                                    fontWeight: checked
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: checked
                                      ? context.accentColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: checked
                                        ? context.accentColor
                                        : context.borderColor,
                                  ),
                                ),
                                child: checked
                                    ? const Icon(
                                        Icons.check,
                                        size: 11,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MANUAL INPUT CARD (NOTEPAD MINI)
  // ══════════════════════════════════════════════════════════

  Widget _buildManualInputCard(PingController engine) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Input IP Manual",
            "Ketik/Paste IP dari Notepad (Satu IP per baris)",
            Icons.paste_outlined,
            const Color(0xFF00B4D8),
          ),
          const SizedBox(height: 20),
          Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: context.accentColor, // Kursor kedip
                selectionColor: context.accentColor.withOpacity(
                  0.3,
                ), // Blok seleksi
                selectionHandleColor:
                    context.accentColor, // Handle drag (di touch screen)
              ),
            ),
            child: TextField(
              cursorColor: context.accentColor, // Warna kursor bawaan TextField
              maxLines: 5,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText:
                    "Contoh:\n10.73.10.1\n10.73.20.1\n10.73.30.1\ndst ...",
                hintStyle: TextStyle(
                  color: context.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.accentColor,
                    width: 1.5,
                  ), // Berubah warna saat diklik
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.borderColor.withOpacity(0.5),
                  ),
                ),
              ),
              onChanged: (val) => engine.setManualIps(val),
              enabled: !engine.isScanning,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STAT CHIP — identik scan_wdcp_page
  // ══════════════════════════════════════════════════════════
  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.75),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SCHEDULER CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildSchedulerCard(PingController engine) {
    final active = engine.isAutoPingSTBActive;
    final color = const Color(0xFF6C63FF); // indigo/purple

    return _buildCard(
      accentLeft: active ? color : context.borderColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(active ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(active ? 0.25 : 0.1)),
            ),
            child: Icon(
              Icons.nightlight_round_outlined,
              color: active ? color : context.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Auto-Ping STB",
                  style: TextStyle(
                    color: active ? context.textPrimary : context.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Otomatis ping seluruh IP STB setiap jam 00:00 – 03:00 pagi.",
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
                if (active) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Scheduler Aktif",
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: active,
            onChanged: engine.isScanning ? null : engine.toggleAutoPing,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TOMBOL START
  // ══════════════════════════════════════════════════════════

  Widget _buildStartButton(PingController engine) {
    final isScanning = engine.isScanning;
    final color = isScanning ? context.textSecondary : context.accentColor;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isScanning ? null : () => engine.startPing(isAutoRun: false),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isScanning
                  ? null
                  : LinearGradient(
                      colors: [
                        context.accentColor,
                        context.accentColor.withOpacity(0.75),
                      ],
                    ),
              color: isScanning ? context.cardColor : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: isScanning
                  ? null
                  : [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isScanning)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: context.textSecondary,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(Icons.radar_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  isScanning ? "Memindai Jaringan..." : "Mulai Ping",
                  style: TextStyle(
                    color: isScanning ? context.textSecondary : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
