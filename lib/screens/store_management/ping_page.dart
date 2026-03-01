import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/ping_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/activity_logger.dart';
import '../../utils/custom_snackbar.dart';
import '../auth/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../profile/profile_page.dart';
import '../profile/admin_panel_page.dart';
import '../settings/settings_page.dart';
import '../store_management/store_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage>
    with SingleTickerProviderStateMixin {
  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
  }

  // ══════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════

  Future<void> _logout(BuildContext ctx) async {
    try {
      await ActivityLogger.updateOnlineStatus(false);
      await ActivityLogger.logAction(
        actionType: "LOGOUT",
        description: "Pengguna keluar dari sistem",
      );
      await Supabase.instance.client.auth.signOut();
      currentUserNik = '';
      currentUserName = '';
      currentUserRole = '';
      if (ctx.mounted) {
        Navigator.pushAndRemoveUntil(
          ctx,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        CustomSnackBar.show(ctx, "Gagal logout: $e", ctx.dangerColor);
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUILD UTAMA
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Hanya Windows
    if (!Platform.isWindows) {
      return Scaffold(
        backgroundColor: context.primaryColor,
        appBar: AppBar(
          backgroundColor: context.primaryColor,
          title: Text(
            "Ping Scanner",
            style: TextStyle(color: context.textPrimary),
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

    final engine = PingService.instance;

    return Scaffold(
      backgroundColor: context.primaryColor,
      drawer: _buildDrawer(),
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),

                          // ── Scheduler ───────────────────────────
                          _buildSectionHeader(
                            "SCHEDULER OTOMATIS",
                            Icons.schedule_outlined,
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
                          _buildSectionHeader(
                            "TARGET IP",
                            Icons.my_location_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildTargetCard(engine),
                          const SizedBox(height: 24),

                          // ── Input Manual IP ──────────────────────
                          _buildSectionHeader(
                            "INPUT MANUAL (OPSIONAL)",
                            Icons.edit_note_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildManualInputCard(engine),
                          const SizedBox(height: 24),

                          // ── Mode Kecepatan ──────────────────────
                          _buildSectionHeader(
                            "MODE KECEPATAN",
                            Icons.speed_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildSpeedCard(engine),
                          const SizedBox(height: 32),

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
            "PING SCANNER",
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

  // ══════════════════════════════════════════════════════════
  // SECTION HEADER (identik settings_page)
  // ══════════════════════════════════════════════════════════

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

  Widget _buildProgressCard(PingService engine) {
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
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TARGET IP CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildTargetCard(PingService engine) {
    final targets = [
      {
        'key': 'GW',
        'label': 'IP Gateway',
        'icon': Icons.router_outlined,
        'value': engine.pingGateway,
      },
      {
        'key': 'S1',
        'label': 'IP Station 1',
        'icon': Icons.computer_outlined,
        'value': engine.pingStation1,
      },
      {
        'key': 'STB',
        'label': 'IP STB',
        'icon': Icons.tv_outlined,
        'value': engine.pingSTB,
      },
      {
        'key': 'RB',
        'label': 'IP RB WDCP',
        'icon': Icons.settings_input_antenna_outlined,
        'value': engine.pingRbWdcp,
      },
      {
        'key': 'C1',
        'label': 'IP CCTV 1',
        'icon': Icons.videocam_outlined,
        'value': engine.pingCctv1,
      },
      {
        'key': 'C2',
        'label': 'IP CCTV 2',
        'icon': Icons.videocam_outlined,
        'value': engine.pingCctv2,
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
  // MODE KECEPATAN CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildSpeedCard(PingService engine) {
    final speeds = [
      {
        'value': 1,
        'label': 'Santai',
        'sub': '1 request per giliran',
        'tag': 'LOW',
        'color': context.successColor,
        'icon': Icons.looks_one_outlined,
      },
      {
        'value': 5,
        'label': 'Sedang',
        'sub': '5 request sekaligus',
        'tag': 'MED',
        'color': context.warningColor,
        'icon': Icons.looks_two_outlined,
      },
      {
        'value': 20,
        'label': 'Agresif',
        'sub': '20 request sekaligus',
        'tag': 'HIGH',
        'color': context.dangerColor,
        'icon': Icons.looks_3_outlined,
      },
    ];

    return _buildCard(
      accentLeft: context.warningColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Mode Kecepatan Ping",
            "Sesuaikan dengan kondisi jaringan kantor",
            Icons.speed_outlined,
            context.warningColor,
          ),
          const SizedBox(height: 20),
          ...speeds.map((s) {
            final val = s['value'] as int;
            final selected = engine.speedMode == val;
            final color = s['color'] as Color;
            final icon = s['icon'] as IconData;

            return GestureDetector(
              onTap: engine.isScanning ? null : () => engine.setSpeed(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.07)
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? color.withOpacity(0.4)
                        : context.borderColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon box
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.12)
                            : context.cardColor,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: selected
                              ? color.withOpacity(0.3)
                              : context.borderColor,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: selected ? color : context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Label + sub
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['label'] as String,
                            style: TextStyle(
                              color: selected
                                  ? context.textPrimary
                                  : context.textSecondary,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s['sub'] as String,
                            style: TextStyle(
                              color: context.textSecondary.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tag badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(selected ? 0.12 : 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withOpacity(selected ? 0.35 : 0.15),
                        ),
                      ),
                      child: Text(
                        s['tag'] as String,
                        style: TextStyle(
                          color: selected
                              ? color
                              : context.textSecondary.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Radio indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: selected ? color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? color : context.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: selected
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
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MANUAL INPUT CARD (NOTEPAD MINI)
  // ══════════════════════════════════════════════════════════

  Widget _buildManualInputCard(PingService engine) {
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
              onChanged: (val) => engine.manualIps = val,
              enabled: !engine.isScanning,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SCHEDULER CARD
  // ══════════════════════════════════════════════════════════

  Widget _buildSchedulerCard(PingService engine) {
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

  Widget _buildStartButton(PingService engine) {
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

  // ══════════════════════════════════════════════════════════
  // DRAWER (identik dengan settings & profile)
  // ══════════════════════════════════════════════════════════

  Widget _buildDrawer() {
    Color roleAccentD;
    IconData roleIconD;
    switch (currentUserRole.toLowerCase()) {
      case 'administrator':
        roleAccentD = const Color(0xFFFF6B6B);
        roleIconD = Icons.admin_panel_settings_outlined;
        break;
      case 'admin':
        roleAccentD = const Color(0xFFFFB347);
        roleIconD = Icons.manage_accounts_outlined;
        break;
      default:
        roleAccentD = context.accentColor;
        roleIconD = Icons.person_outline;
    }

    final nameParts = currentUserName.trim().split(' ');
    final initialsD = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'U';

    return Drawer(
      backgroundColor: context.surfaceColor,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleAccentD.withOpacity(0.13), context.cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roleAccentD,
                                    roleAccentD.withOpacity(0.55),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: roleAccentD.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initialsD,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -5,
                              bottom: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: roleAccentD.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  roleIconD,
                                  size: 12,
                                  color: roleAccentD,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00E676).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E676,
                                      ).withOpacity(0.7),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUserName.isNotEmpty ? currentUserName : 'User',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          currentUserNik,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleAccentD.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: roleAccentD.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIconD, size: 11, color: roleAccentD),
                          const SizedBox(width: 6),
                          Text(
                            currentUserRole.toUpperCase(),
                            style: TextStyle(
                              color: roleAccentD,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Menu Items ───────────────────────────────────
          _buildDrawerTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
          ),
          _buildDrawerTile(
            icon: Icons.store_outlined,
            label: 'Data Toko',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StoreListPage()),
              );
            },
          ),

          // ── Active: Ping Scanner ─────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 2,
              ),
              leading: Icon(
                Icons.network_check,
                color: context.accentColor,
                size: 20,
              ),
              title: Text(
                'Ping Scanner',
                style: TextStyle(
                  color: context.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),

          _buildDrawerTile(
            icon: Icons.person_outline,
            label: 'Profil Saya',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),

          if (currentUserRole.toLowerCase() == 'administrator') ...[
            _buildDrawerTile(
              icon: Icons.settings_outlined,
              label: 'Setting',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            _buildDrawerTile(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Control Center',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                );
              },
            ),
          ],

          const Spacer(),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: context.borderColor,
          ),
          const SizedBox(height: 8),
          _buildDrawerTile(
            icon: Icons.logout_outlined,
            label: 'Keluar Aplikasi',
            iconColor: const Color(0xFFFF6B6B),
            labelColor: const Color(0xFFFF6B6B),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: iconColor ?? context.textSecondary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // ══════════════════════════════════════════════════════════
  // LOGOUT DIALOG
  // ══════════════════════════════════════════════════════════

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1520),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_outlined,
                      color: Color(0xFFFF6B6B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Keluar Aplikasi?",
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Apakah Anda yakin ingin keluar dari aplikasi EDP NetOps?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Batal",
                            style: TextStyle(color: context.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _logout(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Ya, Keluar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
      ),
    );
  }
}
