import '../../../../core/platform/feature_availability.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/page_entry_transition.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/globals.dart';
import 'ping_controller.dart';
import 'widgets/ping_scheduler_card.dart';
import 'widgets/ping_target_selector.dart';
import 'widgets/ping_manual_input_card.dart';
import 'widgets/ping_result_log.dart';
import 'widgets/ping_action_button.dart';

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage>
    with SingleTickerProviderStateMixin {
  final _engine = PingController.instance;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
              : const Center(child: AppHamburgerButton()),
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
      body: PageEntryTransition(
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
                        PingSchedulerCard(engine: engine),
                        const SizedBox(height: 24),

                        // ── Logs Console & Progress ──────────────
                        if (engine.isScanning || engine.progressValue == 1.0) ...[
                          PingResultLog(engine: engine),
                          const SizedBox(height: 24),
                        ],

                        // ── Target IP ──────────────────────────
                        const SectionHeader(
                          title: "TARGET IP",
                          icon: Icons.my_location_outlined,
                        ),
                        const SizedBox(height: 12),
                        PingTargetSelector(engine: engine),
                        const SizedBox(height: 24),

                        // ── Input Manual IP ──────────────────────
                        const SectionHeader(
                          title: "INPUT MANUAL (OPSIONAL)",
                          icon: Icons.edit_note_outlined,
                        ),
                        const SizedBox(height: 12),
                        PingManualInputCard(engine: engine),
                        const SizedBox(height: 24),

                        // ── Tombol Start ─────────────────────────
                        PingActionButton(engine: engine),
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
}
